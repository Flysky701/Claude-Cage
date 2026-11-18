package workbench

import (
	"context"
	"crypto/subtle"
	"encoding/base64"
	"errors"
	"io"
	"net"
	"net/http"
	"net/netip"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/miekg/dns"
	"github.com/sylvinus/agent-vm/internal/cage"
	"github.com/sylvinus/agent-vm/internal/managedproxy"
)

type windowsLocalNetwork struct {
	mu       sync.Mutex
	session  *localAppRoute
	users    int
	selected bool
}

type localNetworkState struct {
	InUse    bool   `json:"in_use"`
	Open     bool   `json:"open"`
	Selected bool   `json:"selected"`
	Message  string `json:"message"`
}

// Each grant belongs to a measured, explicitly selected node. Cancelling it
// interrupts pending dials and every socket opened under that grant.
type localNetworkGrant struct {
	cfg    cage.Config
	raw    *cage.Egress
	ctx    context.Context
	cancel context.CancelFunc
}

type localAppRoute struct {
	ctx     context.Context
	cancel  context.CancelFunc
	pipe    string
	key     string
	server  *http.Server
	mu      sync.Mutex
	epoch   uint64
	grant   *localNetworkGrant
	message string
	expiry  *time.Timer
}

func (p *windowsLocalPrototype) networkStatus(w http.ResponseWriter, r *http.Request) {
	jsonReply(w, p.network.state())
}

func (n *windowsLocalNetwork) state() localNetworkState {
	n.mu.Lock()
	defer n.mu.Unlock()
	if n.session == nil {
		if !n.selected {
			return localNetworkState{Message: "请在网络与代理设置中选择并应用 Cage 节点。"}
		}
		return localNetworkState{Selected: true, Message: "已选择 Cage 节点。打开隔离应用后检查出口。"}
	}
	n.session.mu.Lock()
	defer n.session.mu.Unlock()
	return localNetworkState{InUse: true, Open: n.session.grant != nil, Selected: n.selected, Message: n.session.message}
}

// Refresh on startup and proxy mutations; polling status never probes the
// network or reloads subscription material.
func (n *windowsLocalNetwork) readSelection(profile string) {
	store, err := managedproxy.Load(profile)
	_, selected := store.Find(store.Selected)
	n.mu.Lock()
	n.selected = err == nil && selected
	n.mu.Unlock()
}

func (n *windowsLocalNetwork) revoke(reason string) {
	n.mu.Lock()
	defer n.mu.Unlock()
	if n.session != nil {
		n.session.mu.Lock()
		n.session.revokeLocked(reason)
		n.session.mu.Unlock()
	}
}

func (r *localAppRoute) revokeLocked(reason string) {
	r.epoch++
	if r.expiry != nil {
		r.expiry.Stop()
	}
	if r.grant != nil {
		r.grant.cancel()
		r.grant = nil
	}
	r.message = reason
}

func (s *Server) prepareWindowsLocalNetwork(ctx context.Context, cmd *exec.Cmd) func() {
	// The worker daemon builds its environment from scratch. Only the host's
	// helper is told which owner-only pipe belongs to this controller.
	var env []string
	for _, entry := range cmd.Environ() {
		name, _, _ := strings.Cut(entry, "=")
		if !strings.HasPrefix(strings.ToUpper(name), "CAGE_LOCAL_APP_NETWORK_") {
			env = append(env, entry)
		}
	}
	cmd.Env = env
	n := &s.windowsLocal.network
	n.mu.Lock()
	route := n.session
	if route == nil {
		name := "Cage.LocalEgress." + randomToken()
		listener, err := listenLocalNetworkPipe(name)
		if err != nil {
			n.mu.Unlock()
			return func() {}
		}
		life, cancel := context.WithCancel(s.lifetimeContext())
		route = &localAppRoute{ctx: life, cancel: cancel, pipe: name, key: randomToken(), message: "正在核验代理出口…"}
		token := randomToken()
		// Named-pipe authorization and the helper's Job PID check authenticate
		// the incoming stream. Discard all client-supplied proxy credentials.
		proxy, err := cage.GateProxy(route, token)
		if err != nil {
			listener.Close()
			cancel()
			n.mu.Unlock()
			return func() {}
		}
		auth := "Basic " + base64.StdEncoding.EncodeToString([]byte("proxy:"+token))
		route.server = &http.Server{ReadHeaderTimeout: 10 * time.Second, MaxHeaderBytes: 64 << 10,
			BaseContext: func(net.Listener) context.Context { return life },
			Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				r.Header.Set("Proxy-Authorization", auth)
				proxy.ServeHTTP(w, r)
			})}
		n.session = route
		go func() { _ = route.server.Serve(&localNetworkListener{listener, route.key}) }()
		go route.monitor(s)
	}
	n.users++
	cmd.Env = append(cmd.Env, "CAGE_LOCAL_APP_NETWORK_PIPE="+route.pipe, "CAGE_LOCAL_APP_NETWORK_PID="+strconv.Itoa(os.Getpid()), "CAGE_LOCAL_APP_NETWORK_KEY="+route.key)
	n.mu.Unlock()
	release := sync.OnceFunc(func() {
		n.mu.Lock()
		defer n.mu.Unlock()
		n.users--
		if n.users == 0 {
			n.session = nil
			route.cancel()
			route.mu.Lock()
			route.revokeLocked("隔离应用已关闭。")
			route.mu.Unlock()
			route.server.Close()
		}
	})
	stop := context.AfterFunc(ctx, release)
	return func() { stop(); release() }
}

// Authenticate the host helper before net/http reads any worker-supplied
// bytes. Enumeration of the pipe name alone confers no proxy access.
type localNetworkListener struct {
	net.Listener
	key string
}

func (l *localNetworkListener) Accept() (net.Conn, error) {
	conn, err := l.Listener.Accept()
	if err != nil {
		return nil, err
	}
	return &localNetworkPipe{Conn: conn, key: l.key}, nil
}

type localNetworkPipe struct {
	net.Conn
	key  string
	once sync.Once
	err  error
}

func (c *localNetworkPipe) Read(b []byte) (int, error) {
	c.once.Do(func() {
		var presented [64]byte
		if _, err := io.ReadFull(c.Conn, presented[:]); err != nil || subtle.ConstantTimeCompare(presented[:], []byte(c.key)) != 1 {
			c.err = errors.New("network helper unavailable")
			c.Conn.Close()
		}
	})
	if c.err != nil {
		return 0, c.err
	}
	return c.Conn.Read(b)
}

func (r *localAppRoute) monitor(s *Server) {
	for r.ctx.Err() == nil {
		r.mu.Lock()
		generation := r.epoch
		r.mu.Unlock()
		ctx, cancel := context.WithTimeout(r.ctx, 25*time.Second)
		cfg, err := s.checkLocalAppRoute(ctx)
		cancel()
		delay := 30 * time.Second
		r.mu.Lock()
		if r.ctx.Err() == nil && r.epoch == generation {
			if err != nil {
				r.revokeLocked(err.Error())
				delay = 5 * time.Second
			} else {
				if r.grant == nil || r.grant.cfg.Fingerprint() != cfg.Fingerprint() {
					r.revokeLocked("")
					raw, e := cage.NewEgress(cfg)
					if e == nil {
						ctx, cancel := context.WithCancel(r.ctx)
						r.grant = &localNetworkGrant{cfg, raw, ctx, cancel}
					}
				}
				if r.grant != nil {
					r.message = "已核验手选代理节点、出口规则和账户隔离。"
					if r.expiry != nil {
						r.expiry.Stop()
					}
					// Expire independently of the monitor's progress.
					r.epoch++
					epoch := r.epoch
					r.expiry = time.AfterFunc(65*time.Second, func() {
						r.mu.Lock()
						defer r.mu.Unlock()
						if r.epoch == epoch {
							r.revokeLocked("出口检查已过期。")
						}
					})
				}
			}
		} else {
			delay = time.Second
		}
		r.mu.Unlock()
		select {
		case <-r.ctx.Done():
			return
		case <-time.After(delay):
		}
	}
}

func (s *Server) checkLocalAppRoute(ctx context.Context) (cage.Config, error) {
	cfg, err := loadConfig(s.configPath)
	if err != nil {
		return cfg, errors.New("无法读取此工作台的代理配置。")
	}
	selected, err := managedproxy.Applied(s.profile, cfg.ProxyURL, cfg.ProxyRevision)
	if err != nil {
		return cfg, errors.New("请在此原型的网络与代理设置中选择并应用 Cage 节点。")
	}
	if !selected.IPNodesOnly {
		return cfg, errors.New("请在此原型重新应用使用公网 IPv4 的节点。")
	}
	s.mu.Lock()
	paused := s.networkPaused
	s.mu.Unlock()
	if paused || !managedproxy.Running(ctx, s.profile, selected) {
		return cfg, errors.New("所选代理已停止或尚未就绪。")
	}
	account := s.windowsLocal.inspect(ctx, false)
	bound := s.windowsLocal.active.Load()
	if bound == nil || !account.Available || account.WorkerSID != bound.WorkerSID || account.InstanceID != bound.InstanceID {
		return cfg, errors.New("本地账户及网络隔离规则核验失败。")
	}
	ip, err := cage.ProbeExitIP(ctx, cfg)
	if err != nil {
		return cfg, errors.New("无法通过所选代理核验出口地址。")
	}
	location, err := s.locationForIP(ctx, cfg, ip)
	if err != nil {
		return cfg, errors.New("无法通过所选代理核验出口地区。")
	}
	observed := location.exitLocation()
	policy := cfg.ExitPolicy.BindMissing(observed)
	if state, reason := policy.Evaluate(ip, &observed); state != cage.CheckPassed {
		return cfg, errors.New(reason)
	}
	if !s.op.TryLock() {
		return cfg, errors.New("正在应用工作台设置，稍后重新检查。")
	}
	defer s.op.Unlock()
	current, err := loadConfig(s.configPath)
	if err != nil || current.Fingerprint() != cfg.Fingerprint() || ctx.Err() != nil {
		return cfg, errors.New("代理配置已变化，正在重新核验。")
	}
	if policy != cfg.ExitPolicy {
		cfg.ExitPolicy = policy
		if err := s.saveExitPolicyConfig(cfg); err != nil {
			return cfg, errors.New("无法保存此节点的首次出口绑定。")
		}
	}
	return cfg, nil
}

func (r *localAppRoute) grantFor(request context.Context) (*localNetworkGrant, context.Context, func(), error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	g := r.grant
	if g == nil || g.ctx.Err() != nil {
		return nil, nil, nil, cage.ErrGateClosed
	}
	ctx, cancel := context.WithCancel(request)
	stop := context.AfterFunc(g.ctx, cancel)
	return g, ctx, func() { stop(); cancel() }, nil
}

func (r *localAppRoute) ExchangeDNS(ctx context.Context, q *dns.Msg) (*dns.Msg, error) {
	g, ctx, done, err := r.grantFor(ctx)
	if err != nil {
		return nil, err
	}
	defer done()
	reply, err := g.raw.ExchangeDNS(ctx, q)
	if g.ctx.Err() != nil {
		return nil, cage.ErrGateClosed
	}
	return reply, err
}

func (r *localAppRoute) DialContext(ctx context.Context, network, address string) (net.Conn, error) {
	g, ctx, done, err := r.grantFor(ctx)
	if err != nil {
		return nil, err
	}
	defer done()
	destination, err := netip.ParseAddrPort(address)
	if err != nil || !g.raw.Allows(network, destination) {
		return nil, cage.ErrGateClosed
	}
	conn, err := g.raw.DialContext(ctx, network, address)
	if err != nil {
		return nil, err
	}
	stop := context.AfterFunc(g.ctx, func() { conn.Close() })
	if g.ctx.Err() != nil {
		stop()
		conn.Close()
		return nil, cage.ErrGateClosed
	}
	return &localGrantConn{Conn: conn, stop: stop}, nil
}

type localGrantConn struct {
	net.Conn
	stop func() bool
}

func (c *localGrantConn) Close() error { c.stop(); return c.Conn.Close() }
func (c *localGrantConn) CloseWrite() error {
	if h, ok := c.Conn.(interface{ CloseWrite() error }); ok {
		return h.CloseWrite()
	}
	return c.Close()
}

package managedproxy

import (
	"encoding/base64"
	"errors"
	"net"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"unicode"
	"unicode/utf8"

	"go.yaml.in/yaml/v3"
)

var shareLinkPrefix = regexp.MustCompile(`^[a-zA-Z][a-zA-Z0-9+.-]*://`)

// Convert only node data, then use the same validation and skipped-node reporting
// as YAML imports. Conversion errors must never include the original URI.
func importProxies(data []byte) ([]map[string]any, []error, error) {
	var input struct {
		Proxies []map[string]any `yaml:"proxies"`
		Payload []map[string]any `yaml:"payload"`
	}
	if yaml.Unmarshal(data, &input) == nil {
		proxies := input.Proxies
		if len(proxies) == 0 {
			proxies = input.Payload
		}
		return proxies, make([]error, len(proxies)), nil
	}
	text := strings.TrimSpace(strings.TrimPrefix(strings.TrimSpace(string(data)), "\ufeff"))
	if !shareLinkPrefix.MatchString(text) {
		encoded := strings.Map(func(r rune) rune {
			if unicode.IsSpace(r) {
				return -1
			}
			return r
		}, text)
		for _, encoding := range []*base64.Encoding{base64.StdEncoding, base64.RawStdEncoding, base64.URLEncoding, base64.RawURLEncoding} {
			decoded, err := encoding.DecodeString(encoded)
			if err == nil && utf8.Valid(decoded) {
				text = strings.TrimSpace(strings.TrimPrefix(string(decoded), "\ufeff"))
				break
			}
		}
	}
	if !shareLinkPrefix.MatchString(text) {
		return nil, nil, errors.New("无法读取订阅，请导入 Clash/Mihomo YAML 或 Trojan 分享链接列表（支持 Base64 编码）")
	}
	var proxies []map[string]any
	var issues []error
	for line := range strings.SplitSeq(text, "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		if len(proxies) == 3000 {
			return nil, nil, errors.New("分享链接列表不能超过 3000 个节点")
		}
		proxy, err := trojanShareLink(line)
		proxies = append(proxies, proxy)
		issues = append(issues, err)
	}
	return proxies, issues, nil
}

func trojanShareLink(link string) (map[string]any, error) {
	p := map[string]any{}
	u, err := url.Parse(link)
	if err != nil {
		return p, errors.New("分享链接格式无效")
	}
	p["name"] = u.Fragment
	if !strings.EqualFold(u.Scheme, "trojan") {
		return p, errors.New("分享链接协议暂不支持，请导出 Clash/Mihomo YAML")
	}
	p["type"] = "trojan"
	if u.User == nil || u.Hostname() == "" || (u.Path != "" && u.Path != "/") || u.Opaque != "" {
		return p, errors.New("Trojan 分享链接缺少密码、服务器或格式无效")
	}
	password, err := url.PathUnescape(u.User.String())
	if err != nil || password == "" {
		return p, errors.New("Trojan 分享链接密码无效")
	}
	port := 443
	if u.Port() != "" {
		port, err = strconv.Atoi(u.Port())
		if err != nil || port < 1 || port > 65535 {
			return p, errors.New("Trojan 分享链接端口无效")
		}
	} else if strings.HasSuffix(u.Host, ":") {
		return p, errors.New("Trojan 分享链接端口无效")
	}
	p["server"], p["port"], p["password"] = u.Hostname(), port, password
	if u.Fragment == "" {
		p["name"] = "Trojan " + net.JoinHostPort(u.Hostname(), strconv.Itoa(port))
	}
	q, err := url.ParseQuery(u.RawQuery)
	if err != nil {
		return p, errors.New("Trojan 分享链接参数编码无效")
	}
	for key, values := range q {
		if len(values) != 1 {
			return p, errors.New("Trojan 分享链接参数重复")
		}
		switch key {
		case "peer", "sni", "allowInsecure", "security", "type", "host", "path", "serviceName", "alpn", "fp":
		default:
			return p, errors.New("Trojan 分享链接包含暂不支持的参数，请导出 Clash/Mihomo YAML")
		}
	}
	if q.Has("security") && q.Get("security") != "tls" {
		return p, errors.New("Trojan 分享链接仅支持 TLS 安全模式")
	}
	sni, peer := q.Get("sni"), q.Get("peer")
	if sni != "" && peer != "" && sni != peer {
		return p, errors.New("Trojan 分享链接的 sni 与 peer 冲突")
	}
	if sni == "" {
		sni = peer
	}
	if sni != "" {
		p["sni"] = sni
	}
	if q.Has("allowInsecure") {
		switch q.Get("allowInsecure") {
		case "1", "true":
			p["skip-cert-verify"] = true
		case "0", "false":
			p["skip-cert-verify"] = false
		default:
			return p, errors.New("Trojan 分享链接的 allowInsecure 必须为 0、1、false 或 true")
		}
	}
	if q.Has("alpn") {
		alpn := strings.Split(q.Get("alpn"), ",")
		for i := range alpn {
			alpn[i] = strings.TrimSpace(alpn[i])
			if alpn[i] == "" {
				return p, errors.New("Trojan 分享链接的 ALPN 列表无效")
			}
		}
		p["alpn"] = alpn
	}
	if q.Has("fp") {
		p["client-fingerprint"] = q.Get("fp")
	}
	switch q.Get("type") {
	case "", "tcp":
		if q.Has("host") || q.Has("path") || q.Has("serviceName") {
			return p, errors.New("Trojan TCP 分享链接包含其他传输模式的参数")
		}
	case "ws":
		if q.Has("serviceName") {
			return p, errors.New("Trojan WebSocket 分享链接不能包含 gRPC 参数")
		}
		p["network"] = "ws"
		opts := map[string]any{}
		if q.Has("path") {
			opts["path"] = q.Get("path")
		}
		if q.Has("host") {
			opts["headers"] = map[string]any{"Host": q.Get("host")}
		}
		p["ws-opts"] = opts
	case "grpc":
		if q.Has("host") || q.Has("path") {
			return p, errors.New("Trojan gRPC 分享链接包含暂不支持的传输参数")
		}
		p["network"] = "grpc"
		if q.Has("serviceName") {
			p["grpc-opts"] = map[string]any{"grpc-service-name": q.Get("serviceName")}
		}
	default:
		return p, errors.New("Trojan 分享链接的传输模式暂不支持，请导出 Clash/Mihomo YAML")
	}
	return p, nil
}

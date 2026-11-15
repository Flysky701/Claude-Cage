package io.github.leexeo.cage.localcore;

import android.app.*;
import android.content.Intent;
import android.net.*;
import android.os.*;
import android.util.AtomicFile;
import hev.htproxy.TProxyService;
import java.io.*;
import java.net.InetAddress;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;

/** External whole-user VPN. Android lockdown, when enabled by the user, guards service failure. */
public final class CoreService extends VpnService {
    private static final Object NATIVE_LIFETIME = new Object();
    static volatile CoreService current;
    static volatile boolean running, startFailed;
    private final AtomicBoolean stopped = new AtomicBoolean();
    private final CountDownLatch stopSignal = new CountDownLatch(1);
    private final CancellationSignal dnsCancel = new CancellationSignal();
    private final CompletableFuture<List<InetAddress>> upstreamAddresses = new CompletableFuture<>();
    private volatile ParcelFileDescriptor tunnel;
    private volatile boolean nativeReady;
    private volatile EmbeddedProxy optionalCore;
    private boolean started;

    @Override public void onCreate() {
        super.onCreate();
        current = this; running = true; startFailed = false;
    }

    @Override public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && "STOP".equals(intent.getAction())) {
            requestStop(); stopSelf(); return START_NOT_STICKY;
        }
        if (stopped.get()) return START_NOT_STICKY;
        try {
            if (VpnService.prepare(this) != null) throw new SecurityException("VPN consent missing");
            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(new NotificationChannel("gateway", "空间网关", NotificationManager.IMPORTANCE_LOW));
            PendingIntent open = PendingIntent.getActivity(this, 0, new Intent(this, CoreActivity.class), PendingIntent.FLAG_IMMUTABLE);
            startForeground(1, new Notification.Builder(this, "gateway")
                    .setSmallIcon(android.R.drawable.stat_notify_sync).setContentTitle("Cage 全手机网关")
                    .setContentText("全手机流量经 SOCKS5；断网锁状态请查看网关")
                    .setContentIntent(open).setOngoing(true).build());
        } catch (RuntimeException denied) {
            startFailed = true; requestStop(); stopSelf(); return START_NOT_STICKY;
        }
        if (!started) {
            started = true;
            new Thread(this::runTunnel, "Cage-HEV-lifetime").start();
        }
        return START_STICKY;
    }

    boolean tunnelReady() {
        EmbeddedProxy core = optionalCore;
        return !stopped.get() && nativeReady && tunnel != null && (core == null || core.isAlive())
                && TProxyService.TProxyIsRunning();
    }

    boolean safeReady() { return tunnelReady() && isAlwaysOn() && isLockdownEnabled(); }

    private void runTunnel() {
        // JNI has global state. Old native cleanup completes before any new service can start it.
        synchronized (NATIVE_LIFETIME) {
            boolean nativeStarted = false;
            try {
                if (stopped.get()) return;
                Upstream upstream;
                String numeric;
                if (Settings.vlessFile(this).isFile()) {
                    EmbeddedProxy core = new EmbeddedProxy();
                    optionalCore = core;
                    if (stopped.get()) core.cancel();
                    // Same application UID as HEV, excluded from its own system VPN.
                    // Missing or invalid VLESS cannot fall back to upstream.json.
                    upstream = core.start(new File(getApplicationInfo().nativeLibraryDir, "libmihomo.so"),
                            getFilesDir(), Settings.loadVless(this));
                    numeric = upstream.host;
                } else {
                    upstream = Settings.load(this);
                    numeric = resolveUpstream(upstream.host);
                }
                if (stopped.get()) return;
                File runtime = new File(getFilesDir(), "tunnel-runtime.yaml");
                AtomicFile output = new AtomicFile(runtime);
                FileOutputStream stream = output.startWrite();
                try {
                    stream.write(TunnelConfig.render(upstream, numeric).getBytes(StandardCharsets.UTF_8));
                    output.finishWrite(stream);
                } catch (Exception failed) { output.failWrite(stream); throw failed; }
                Builder builder = new Builder().setSession("Cage 全手机 SOCKS5 网关")
                        .setMtu(1500).setBlocking(false)
                        .addAddress(TunnelConfig.IPV4, 32).addAddress(TunnelConfig.IPV6, 128)
                        .addRoute("0.0.0.0", 0).addRoute("::", 0).addDnsServer(TunnelConfig.DNS)
                        .setConfigureIntent(PendingIntent.getActivity(this, 0, new Intent(this, CoreActivity.class), PendingIntent.FLAG_IMMUTABLE));
                // Only the gateway is excluded, so native HEV can reach its SOCKS server.
                // No allowed-app list, allowBypass(), target exclusions or direct fallback.
                builder.addDisallowedApplication(getPackageName());
                if (stopped.get()) return;
                tunnel = builder.establish();
                if (tunnel == null || stopped.get()) throw new IOException("TUN unavailable");
                nativeStarted = TProxyService.TProxyStartService(runtime.getAbsolutePath(), tunnel.getFd());
                if (!nativeStarted) throw new IOException("HEV refused start");
                // Start sets a thread flag before YAML parsing: allow initialization to fail first.
                if (stopSignal.await(750, TimeUnit.MILLISECONDS)) return;
                if (!TProxyService.TProxyIsRunning()) throw new IOException("HEV initialization failed");
                nativeReady = true;
                while (!stopSignal.await(300, TimeUnit.MILLISECONDS)) {
                    if (!TProxyService.TProxyIsRunning()) throw new IOException("HEV stopped");
                    if (optionalCore != null && !optionalCore.isAlive()) throw new IOException("optional core stopped");
                }
            } catch (Exception | LinkageError unavailable) {
                if (!stopped.get()) startFailed = true;
            } finally {
                requestStop();
                // Stop joins HEV and closes all SOCKS sessions before its borrowed fd closes.
                if (nativeStarted) try { TProxyService.TProxyStopService(); } catch (LinkageError ignored) {}
                ParcelFileDescriptor closing = tunnel; tunnel = null;
                if (closing != null) try { closing.close(); } catch (IOException ignored) {}
                EmbeddedProxy core = optionalCore;
                if (core != null) core.close();
                stopSelf();
            }
        }
    }

    private String resolveUpstream(String host) throws Exception {
        if (host.indexOf(':') >= 0 || host.matches("[0-9]+(?:\\.[0-9]+){3}"))
            return InetAddress.getByName(host).getHostAddress();
        ConnectivityManager connectivity = getSystemService(ConnectivityManager.class);
        Network physical = null;
        for (Network candidate : connectivity.getAllNetworks()) {
            NetworkCapabilities capabilities = connectivity.getNetworkCapabilities(candidate);
            if (capabilities != null && capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                    && !capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                physical = candidate;
                if (capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)) break;
            }
        }
        if (physical == null) throw new IOException("no underlying network");
        if (stopped.get()) throw new IOException("stopped");
        // Only the SOCKS endpoint is resolved, on a physical network even under lockdown.
        DnsResolver.getInstance().query(physical, host, 0, Runnable::run, dnsCancel,
                new DnsResolver.Callback<List<InetAddress>>() {
                    @Override public void onAnswer(List<InetAddress> addresses, int rcode) {
                        if (rcode != 0 || addresses.isEmpty())
                            upstreamAddresses.completeExceptionally(new IOException("upstream DNS failed"));
                        else upstreamAddresses.complete(addresses);
                    }
                    @Override public void onError(DnsResolver.DnsException ignored) {
                        upstreamAddresses.completeExceptionally(new IOException("upstream DNS failed"));
                    }
                });
        return upstreamAddresses.get(10, TimeUnit.SECONDS).get(0).getHostAddress();
    }

    private void requestStop() {
        if (!stopped.compareAndSet(false, true)) return;
        nativeReady = false;
        if (current == this) { running = false; current = null; }
        dnsCancel.cancel();
        upstreamAddresses.completeExceptionally(new IOException("stopped"));
        EmbeddedProxy core = optionalCore;
        if (core != null) core.cancel();
        stopSignal.countDown();
    }

    @Override public void onRevoke() { requestStop(); stopSelf(); }
    @Override public void onTimeout(int startId, int type) { requestStop(); stopSelf(); }
    @Override public void onDestroy() {
        requestStop(); stopForeground(STOP_FOREGROUND_REMOVE); super.onDestroy();
    }
}

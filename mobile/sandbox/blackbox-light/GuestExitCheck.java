package top.niunaijun.blackbox.network;

import android.content.*;
import android.net.LocalServerSocket;
import android.net.LocalSocket;
import android.net.LocalSocketAddress;
import android.os.*;
import android.system.ErrnoException;
import android.system.Os;
import android.system.OsConstants;
import android.util.Log;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.*;
import java.util.zip.ZipFile;
import io.github.leexeo.cage.space.SpaceSites;

/** Loaded by the existing BlackBox guest-start callback, before the ordinary APK starts. */
public final class GuestExitCheck implements ServiceConnection {
    static final String SITE = "ipv4.icanhazip.com";
    static final String PIN = "104.16.185.241";
    static final String TAG = "CageLightNet";
    // A numeric proxy address avoids resolving the site's name in the no-INTERNET process.
    // The Java socket factory handles this address locally. Nothing listens on this TCP port.
    static final InetSocketAddress JAVA_PROXY = new InetSocketAddress("127.0.0.1", 38491);
    private static final String HELPER = "io.github.leexeo.cage.localcore";
    private final CountDownLatch bound = new CountDownLatch(1);
    private volatile Messenger service;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final Semaphore clients = new Semaphore(4);
    private static boolean attempted;
    private boolean stableProbe;
    private boolean spaceApp;

    public static synchronized void bind(Context host, Context guest) {
        String pkg = guest.getPackageName();
        boolean space = pkg.equals("com.anthropic.claude") || pkg.equals("com.google.android.gsf")
                || pkg.equals("com.google.android.gms") || pkg.equals("com.android.vending");
        if (attempted || (!space && !pkg.equals("io.github.leexeo.cage.plainnet") &&
                !pkg.equals("io.github.leexeo.cage.stablenet"))) return;
        attempted = true;
        try {
            // Refuse to launch the test app in a wrongly permissioned shell.
            for (int family : new int[]{OsConstants.AF_INET, OsConstants.AF_INET6}) {
                for (int type : new int[]{OsConstants.SOCK_STREAM, OsConstants.SOCK_DGRAM}) {
                    try {
                        FileDescriptor direct = Os.socket(family, type, 0);
                        Os.close(direct);
                        Log.e(TAG, "unexpected Internet socket permission; stopping test guest");
                        android.os.Process.killProcess(android.os.Process.myPid());
                        return;
                    } catch (ErrnoException expected) {
                        if (expected.errno != OsConstants.EACCES && expected.errno != OsConstants.EPERM
                                && expected.errno != OsConstants.EAFNOSUPPORT) throw expected;
                    }
                }
            }
            Log.i(TAG, "kernel denied direct IPv4/IPv6 TCP/UDP sockets");
            GuestExitCheck network = new GuestExitCheck();
            network.spaceApp = space;
            network.install(host, pkg);
        } catch (Exception failure) {
            Log.e(TAG, "guest routing unavailable", failure);
        }
    }

    private void install(Context host, String pkg) throws Exception {
        stableProbe = pkg.equals("io.github.leexeo.cage.stablenet");
        String socketName = spaceApp ? "space-" + android.os.Process.myPid() : pkg.substring(pkg.lastIndexOf('.') + 1);
        File path = new File(host.getCacheDir(), socketName + "-egress.sock");
        if (path.exists() && !path.delete()) throw new IOException("could not replace private listener");
        LocalSocket owner = new LocalSocket();
        owner.bind(new LocalSocketAddress(path.toString(), LocalSocketAddress.Namespace.FILESYSTEM));
        LocalServerSocket listener = new LocalServerSocket(owner.getFileDescriptor());
        Os.chmod(path.toString(), 0600);
        int ownerUid = kernelUid();
        Intent intent = new Intent().setClassName(HELPER, HELPER + ".ExitCheckService");
        if (!host.bindService(intent, this, Context.BIND_AUTO_CREATE)) throw new IOException("helper not installed");
        new Thread(() -> {
            try {
                for (;;) {
                    LocalSocket peer = listener.accept();
                    Log.i(TAG, "private connection from pid=" + peer.getPeerCredentials().getPid());
                    if (peer.getPeerCredentials().getUid() != ownerUid || !clients.tryAcquire()) {
                        peer.close();
                        continue;
                    }
                    new Thread(() -> {
                        try (LocalSocket client = peer) { forward(client); }
                        catch (Exception end) { Log.i(TAG, "connection closed " + end); }
                        finally { clients.release(); }
                    }, "Cage-local-client").start();
                }
            } catch (IOException end) { Log.i(TAG, "listener closed " + end); }
            finally {
                try { owner.close(); } catch (IOException ignored) {}
                path.delete();
            }
        }, "Cage-private-proxy").start();
        Socket.setSocketImplFactory(() -> new LocalGuestSocket(path.toString(), spaceApp));
        final Proxy localProxy = new Proxy(Proxy.Type.HTTP, JAVA_PROXY);
        configureJavaProxy(localProxy);
        // Set the first hop before the guest starts. The original APK chooses its
        // own executable, arguments and TLS implementation.
        String childProxy = "socks5h://localhost" + path;
        String apk = host.getApplicationInfo().sourceDir;
        String entry = "lib/arm64-v8a/libcage_curl4.so";
        try (ZipFile signedShell = new ZipFile(apk)) {
            if (!spaceApp && android.os.Process.is64Bit() && signedShell.getEntry(entry) != null) {
                String library = apk + "!/" + entry;
                String existing = Os.getenv("LD_PRELOAD");
                Os.setenv("CAGE_CURL4_LOCAL", path.toString(), true);
                Os.setenv("LD_PRELOAD", existing == null || existing.isEmpty() ? library : library + ":" + existing, true);
                childProxy = "socks5h://127.0.0.1:" + JAVA_PROXY.getPort();
                Log.i(TAG, "signed shell provides a local IPv4 proxy endpoint for the system curl");
            }
        }
        for (String key : new String[]{"http_proxy", "https_proxy", "ALL_PROXY", "all_proxy"})
            Os.setenv(key, childProxy, true);
        for (String key : new String[]{"no_proxy", "NO_PROXY"}) Os.unsetenv(key);
        Log.i(TAG, "installed Java and child proxy defaults for " + pkg);
    }

    private void configureJavaProxy(Proxy localProxy) throws MalformedURLException {
        // Keep the platform HTTPS implementation, its TLS verification and request options.
        // A relative URL resolved against this context inherits the original protocol handler.
        URL platformHttps = new URL("https://" + SITE + "/");
        URLStreamHandler https = new URLStreamHandler() {
            @Override protected URLConnection openConnection(URL url) throws IOException {
                return openConnection(url, localProxy);
            }
            @Override protected URLConnection openConnection(URL url, Proxy requested) throws IOException {
                if (!localProxy.equals(requested) || !(spaceApp ? SpaceSites.allows(url.getHost()) : SITE.equalsIgnoreCase(url.getHost())) ||
                        (url.getPort() != -1 && url.getPort() != 443))
                    throw new ConnectException("outside test HTTPS route");
                // An explicit proxy keeps Android's client from retrying through host DNS.
                return new URL(platformHttps, url.toExternalForm()).openConnection(localProxy);
            }
            @Override protected int getDefaultPort() { return 443; }
        };
        URL.setURLStreamHandlerFactory(protocol -> "https".equals(protocol) ? https : null);
        final List<Proxy> proxy = Collections.singletonList(localProxy);
        ProxySelector.setDefault(new ProxySelector() {
            @Override public List<Proxy> select(URI uri) { return proxy; }
            @Override public void connectFailed(URI uri, SocketAddress address, IOException e) {}
        });
    }

    @Override public void onServiceConnected(ComponentName name, IBinder binder) {
        service = new Messenger(binder);
        Log.i(TAG, "bound to separate relay");
        bound.countDown();
        if (stableProbe) DefaultCurlControl.check(service, main.getLooper());
    }
    @Override public void onServiceDisconnected(ComponentName name) { service = null; }

    // BlackBox virtualizes Process.myUid(); Unix peer credentials use the real UID.
    private static int kernelUid() throws IOException {
        try (BufferedReader reader = new BufferedReader(new FileReader("/proc/self/status"))) {
            for (String line; (line = reader.readLine()) != null;)
                if (line.startsWith("Uid:")) return Integer.parseInt(line.trim().split("\\s+")[1]);
        }
        throw new IOException("missing kernel UID");
    }

    private static String readLine(InputStream input, int limit) throws IOException {
        ByteArrayOutputStream buf = new ByteArrayOutputStream();
        for (int i = 0; i < limit; i++) {
            int b = input.read();
            if (b < 0) throw new EOFException();
            if (b == '\n') return buf.toString("US-ASCII").trim();
            buf.write(b);
        }
        throw new IOException("oversized proxy header");
    }

    private static String socksDestination(DataInputStream in, OutputStream out) throws IOException {
        byte[] methods = new byte[in.readUnsignedByte()];
        in.readFully(methods);
        boolean anonymous = false;
        for (byte method : methods) if (method == 0) anonymous = true;
        out.write(new byte[]{5, (byte)(anonymous ? 0 : 255)});
        if (!anonymous || in.readUnsignedByte() != 5 || in.readUnsignedByte() != 1 ||
                in.readUnsignedByte() != 0) throw new IOException("SOCKS CONNECT required");
        int kind = in.readUnsignedByte();
        String dest;
        if (kind == 3) {
            byte[] name = new byte[in.readUnsignedByte()];
            in.readFully(name);
            dest = new String(name, StandardCharsets.US_ASCII);
        } else if (kind == 1) {
            byte[] ip = new byte[4];
            in.readFully(ip);
            dest = InetAddress.getByAddress(ip).getHostAddress();
        } else throw new IOException("unsupported address family");
        if (in.readUnsignedShort() != 443) throw new IOException("unsupported port");
        return dest;
    }

    private static String httpDestination(DataInputStream in) throws IOException {
        // The caller consumed 'C'. Leave all bytes after the header for the client's TLS.
        String first = "C" + readLine(in, 512);
        String[] fields = first.split(" ");
        if (fields.length != 3 || !fields[0].equals("CONNECT") || !fields[1].endsWith(":443"))
            throw new IOException("HTTPS CONNECT required");
        int remaining = 8192;
        for (;;) {
            String header = readLine(in, remaining);
            if (header.isEmpty()) break;
            remaining -= header.length() + 2;
        }
        return fields[1].substring(0, fields[1].length() - 4);
    }

    private void forward(LocalSocket client) throws Exception {
        client.setSoTimeout(15000);
        DataInputStream in = new DataInputStream(client.getInputStream());
        OutputStream out = client.getOutputStream();
        int first = in.readUnsignedByte();
        boolean socks = first == 5;
        if (!socks && first != 'C') throw new IOException("unknown proxy protocol");
        String dest = socks ? socksDestination(in, out) : httpDestination(in);
        if (spaceApp ? !SpaceSites.allows(dest) : !SITE.equalsIgnoreCase(dest) && !PIN.equals(dest))
            throw new IOException("destination outside space route");
        Log.i(TAG, "requested " + (socks ? "SOCKS " : "CONNECT ") + dest +
                " peerPid=" + client.getPeerCredentials().getPid());
        try (Bridge stream = open(dest)) {
            if (socks) out.write(new byte[]{5,0,0,1,0,0,0,0,0,0});
            else out.write("HTTP/1.1 200 Connection Established\r\n\r\n".getBytes(StandardCharsets.US_ASCII));
            Log.i(TAG, "proxy accepted " + (socks ? "SOCKS " : "CONNECT ") + dest);
            new Thread(() -> {
                try { copy(in, stream.up); } catch (IOException ended) {}
                finally { try { stream.up.close(); } catch (IOException ignored) {} }
            }, "Cage-client-to-core").start();
            copy(stream.down, out);
        }
    }

    private static void copy(InputStream in, OutputStream out) throws IOException {
        byte[] buf = new byte[8192];
        for (int n; (n = in.read(buf)) != -1;) out.write(buf, 0, n);
    }

    private static final class Bridge implements Closeable {
        final OutputStream up;
        final InputStream down;
        Bridge(ParcelFileDescriptor send, ParcelFileDescriptor receive) {
            up = new ParcelFileDescriptor.AutoCloseOutputStream(send);
            down = new ParcelFileDescriptor.AutoCloseInputStream(receive);
        }
        public void close() throws IOException { try { up.close(); } finally { down.close(); } }
    }

    private Bridge open(String destination) throws Exception {
        Bridge stream = requestStream(destination);
        // The original fixed-site helper accepts one stream until its previous
        // pipes have both closed. No TLS bytes have been sent on this request yet.
        if (stream == null) {
            Thread.sleep(350);
            stream = requestStream(destination);
        }
        if (stream == null) throw new IOException("core unavailable");
        return stream;
    }

    private Bridge requestStream(String destination) throws Exception {
        bound.await(3, TimeUnit.SECONDS);
        Messenger remote = service;
        if (remote == null) throw new IOException("proxy service disconnected");
        CompletableFuture<Bridge> result = new CompletableFuture<>();
        // Operation 2 on both helper versions connects to the fixed hostname.
        // A numeric destination must go through the exact-address operation.
        boolean named = SITE.equalsIgnoreCase(destination);
        Message request = Message.obtain(null, named ? 2 : 3);
        if (!named) request.getData().putString("destination", destination);
        request.replyTo = new Messenger(new Handler(main.getLooper(), reply -> {
            ParcelFileDescriptor send = reply.getData().getParcelable("send");
            ParcelFileDescriptor receive = reply.getData().getParcelable("receive");
            if (!named) Log.i(TAG, "exact-address reply for " + destination +
                    " stream=" + (send != null && receive != null));
            if (send == null || receive == null) {
                for (ParcelFileDescriptor fd : new ParcelFileDescriptor[]{send, receive})
                    if (fd != null) try { fd.close(); } catch (IOException ignored) {}
                result.complete(null);
            } else {
                Bridge bridge = new Bridge(send, receive);
                if (!result.complete(bridge)) try { bridge.close(); } catch (IOException ignored) {}
            }
            return true;
        }));
        remote.send(request);
        if (!named) Log.i(TAG, "submitted exact-address request to relay " + destination + ":443");
        try { return result.get(10, TimeUnit.SECONDS); }
        catch (InterruptedException | TimeoutException ended) {
            if (!named && ended instanceof TimeoutException)
                Log.i(TAG, "no exact-address reply from relay for " + destination);
            result.whenComplete((bridge, error) -> {
                if (bridge != null) try { bridge.close(); } catch (IOException ignored) {}
            });
            throw ended;
        }
    }
}

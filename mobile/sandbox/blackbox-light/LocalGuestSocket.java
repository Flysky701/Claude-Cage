package top.niunaijun.blackbox.network;

import android.net.LocalSocket;
import android.net.LocalSocketAddress;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import io.github.leexeo.cage.space.SpaceSites;

/** Outgoing Java streams for the guest process. There is no Internet-socket fallback. */
final class LocalGuestSocket extends SocketImpl {
    private final String path;
    private final boolean spaceApp;
    private final Map<Integer, Object> options = new HashMap<>();
    private final LocalSocket transport = new LocalSocket();

    LocalGuestSocket(String path, boolean spaceApp) { this.path = path; this.spaceApp = spaceApp; }

    @Override protected void create(boolean stream) throws IOException {
        if (!stream) throw new SocketException("datagrams are unavailable");
    }
    @Override protected void connect(String host, int port) throws IOException {
        connect(InetSocketAddress.createUnresolved(host, port), 0);
    }
    @Override protected void connect(InetAddress addr, int port) throws IOException {
        connect(new InetSocketAddress(addr, port), 0);
    }
    @Override protected void connect(SocketAddress target, int timeout) throws IOException {
        if (!(target instanceof InetSocketAddress)) throw new SocketException("unsupported address");
        InetSocketAddress peer = (InetSocketAddress)target;
        boolean proxy = GuestExitCheck.JAVA_PROXY.equals(peer);
        String dest = peer.getHostString();
        if (!proxy && spaceApp && !SpaceSites.allows(dest)) throw new ConnectException("outside space route");
        if (!proxy && !spaceApp && !GuestExitCheck.SITE.equalsIgnoreCase(dest)) {
            if (peer.getAddress() != null) dest = peer.getAddress().getHostAddress();
            if (!GuestExitCheck.PIN.equals(dest)) throw new ConnectException("outside test site");
        }
        if (!proxy && peer.getPort() != 443) throw new ConnectException("unsupported port");
        try {
            transport.connect(new LocalSocketAddress(path, LocalSocketAddress.Namespace.FILESYSTEM));
            fd = transport.getFileDescriptor();
            if (!proxy) {
                transport.setSoTimeout(timeout > 0 ? timeout : 10000);
                String request = "CONNECT " + dest + ":443 HTTP/1.1\r\nHost: " + dest + ":443\r\n\r\n";
                transport.getOutputStream().write(request.getBytes(StandardCharsets.US_ASCII));
                // Read the exact local acknowledgement. TLS thereafter runs in the unmodified app.
                byte[] ok = "HTTP/1.1 200 Connection Established\r\n\r\n".getBytes(StandardCharsets.US_ASCII);
                InputStream response = transport.getInputStream();
                for (byte expected : ok) if (response.read() != expected)
                    throw new ConnectException("proxy unavailable");
            }
            transport.setSoTimeout((Integer)getOption(SO_TIMEOUT));
            address = peer.getAddress();
            port = peer.getPort();
        } catch (IOException e) {
            close();
            throw e;
        }
    }
    @Override protected InputStream getInputStream() throws IOException { return transport.getInputStream(); }
    @Override protected OutputStream getOutputStream() throws IOException { return transport.getOutputStream(); }
    @Override protected int available() throws IOException { return getInputStream().available(); }
    @Override protected void shutdownInput() throws IOException { transport.shutdownInput(); }
    @Override protected void shutdownOutput() throws IOException { transport.shutdownOutput(); }
    @Override protected void close() throws IOException { transport.close(); }
    @Override protected void bind(InetAddress addr, int port) throws IOException { throw outgoingOnly(); }
    @Override protected void listen(int backlog) throws IOException { throw outgoingOnly(); }
    @Override protected void accept(SocketImpl s) throws IOException { throw outgoingOnly(); }
    @Override protected void sendUrgentData(int b) throws IOException { throw outgoingOnly(); }
    private static SocketException outgoingOnly() { return new SocketException("outgoing TLS streams only"); }

    @Override public void setOption(int id, Object value) throws SocketException {
        if (id == SO_TIMEOUT && fd != null) {
            try { transport.setSoTimeout((Integer)value); }
            catch (IOException e) { throw new SocketException(e.toString()); }
        }
        options.put(id, value);
    }
    @Override public Object getOption(int id) throws SocketException {
        if (options.containsKey(id)) return options.get(id);
        switch (id) {
            case SO_BINDADDR: return InetAddress.getLoopbackAddress();
            case SO_TIMEOUT: case IP_TOS: return 0;
            case SO_RCVBUF: case SO_SNDBUF: return 8192;
            case SO_LINGER: case TCP_NODELAY: case SO_KEEPALIVE: case SO_REUSEADDR: case SO_OOBINLINE:
                return false;
            default: throw new SocketException("unsupported socket option " + id);
        }
    }
}

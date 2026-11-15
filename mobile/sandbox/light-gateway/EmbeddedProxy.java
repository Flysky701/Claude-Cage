package io.github.leexeo.cage.localcore;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

/** Optional existing core, launched as this application's UID, with an authenticated loopback port. */
final class EmbeddedProxy implements Closeable {
    private volatile Process process;
    private volatile Socket handshake;
    private volatile boolean stopped;

    synchronized Upstream start(File binary, File files, String privateConfig) throws Exception {
        if (stopped || !binary.isFile() || !binary.canExecute()) throw new IOException("optional core unavailable");
        String secret = UUID.randomUUID().toString();
        int port;
        // Bind only loopback to choose a free port. Auth verifies that the child owns it after launch.
        try (ServerSocket reservation = new ServerSocket(0, 1, InetAddress.getByName("127.0.0.1"))) {
            port = reservation.getLocalPort();
        }
        File runtime = new File(files, "proxy-runtime.yaml");
        Files.write(runtime.toPath(), VlessConfig.render(privateConfig, port, secret).getBytes(StandardCharsets.UTF_8));
        if (stopped) throw new IOException("stopped");
        process = new ProcessBuilder(binary.getAbsolutePath(), "-d", files.getAbsolutePath(), "-f", runtime.getAbsolutePath())
                .redirectErrorStream(true).redirectOutput(new File("/dev/null")).start();
        Upstream upstream = new Upstream("127.0.0.1", port, "cage", secret);
        long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(10);
        while (!stopped && process.isAlive() && System.nanoTime() < deadline) {
            try (Socket socket = new Socket(Proxy.NO_PROXY)) {
                handshake = socket;
                if (stopped) throw new IOException("stopped");
                socket.connect(new InetSocketAddress("127.0.0.1", port), 200);
                socket.setSoTimeout(300);
                DataInputStream input = new DataInputStream(socket.getInputStream());
                OutputStream output = socket.getOutputStream();
                output.write(new byte[]{5, 1, 2}); output.flush();
                if (input.readUnsignedByte() != 5 || input.readUnsignedByte() != 2)
                    throw new IOException("authenticated SOCKS required");
                output.write(1); output.write(upstream.username.length); output.write(upstream.username);
                output.write(upstream.password.length); output.write(upstream.password); output.flush();
                if (input.readUnsignedByte() != 1 || input.readUnsignedByte() != 0)
                    throw new IOException("loopback authentication failed");
                if (!stopped && process.isAlive()) return upstream;
            } catch (IOException notReady) {
                // Discard output and failure messages; never expose config or node credentials.
            } finally { handshake = null; }
            Thread.sleep(75);
        }
        throw new IOException("optional core startup failed");
    }

    boolean isAlive() { Process child = process; return !stopped && child != null && child.isAlive(); }

    // Called immediately from service shutdown, without waiting for a handshake or native Stop.
    void cancel() {
        stopped = true;
        Socket socket = handshake;
        if (socket != null) try { socket.close(); } catch (IOException ignored) {}
        Process child = process;
        if (child != null) child.destroy();
    }

    @Override public void close() {
        cancel();
        Process child = process;
        if (child == null) return;
        try {
            if (!child.waitFor(1, TimeUnit.SECONDS)) {
                child.destroyForcibly(); child.waitFor(2, TimeUnit.SECONDS);
            }
        } catch (InterruptedException interrupted) { child.destroyForcibly(); Thread.currentThread().interrupt(); }
    }
}

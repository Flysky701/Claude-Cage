package io.github.leexeo.cage.localcore;

import android.app.Service;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Intent;
import android.net.LocalServerSocket;
import android.net.LocalSocket;
import android.os.IBinder;
import android.system.ErrnoException;
import android.system.Os;
import android.system.OsConstants;
import android.util.Log;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.*;
import java.util.concurrent.TimeUnit;
import javax.net.ssl.*;
import io.github.leexeo.cage.space.SpaceSites;

/** Disposable test: only the test shell UID can use the two local HTTPS diagnostic entrances. */
public final class CoreService extends Service {
    private static final String HOST = "ipv4.icanhazip.com";
    private static final int PORT = 29461;
    private static final String TAG = "CageLocalCore";
    private final String password = UUID.randomUUID().toString();
    private final List<LocalServerSocket> listeners = new ArrayList<>();
    private final Set<LocalSocket> clients = new HashSet<>();
    private volatile boolean stopped;
    private Thread worker;
    private Process core;
    static volatile CoreService readyCore;
    static volatile boolean running, startFailed;

    @Override public void onCreate() {
        super.onCreate();
        startFailed = false;
        running = true;
    }

    @Override public IBinder onBind(Intent intent) { return null; }
    @Override public int onStartCommand(Intent intent, int flags, int id) {
        NotificationManager manager = getSystemService(NotificationManager.class);
        manager.createNotificationChannel(new NotificationChannel("test", "本地核心测试", NotificationManager.IMPORTANCE_LOW));
        startForeground(1, new Notification.Builder(this,"test").setContentTitle("Cage 本地出口测试")
                .setSmallIcon(android.R.drawable.stat_notify_sync).setOngoing(true).build());
        if (worker == null) {
            worker = new Thread(this::run, "Cage-core-test");
            worker.start();
        }
        return START_NOT_STICKY;
    }
    private void run() {
        File dir = getFilesDir();
        File config = new File(dir, "runtime.yaml");
        try {
            int uid = getPackageManager().getApplicationInfo("top.niunaijun.cagetest", 0).uid;
            String prefix = "mode: rule\nallow-lan: false\nbind-address: 127.0.0.1\nmixed-port: " + PORT
                    + "\nauthentication: ['cage:" + password + "']\nskip-auth-prefixes: []\n"
                    + "tun: {enable: false}\nipv6: false\nlog-level: silent\ngeo-auto-update: false\n"
                    + "profile: {store-selected: false}\nfind-process-mode: off\n";
            try (OutputStream out = new FileOutputStream(config)) {
                out.write(prefix.getBytes(StandardCharsets.UTF_8));
                Files.copy(new File(dir, "upstream.yaml").toPath(), out);
            }
            File binary = new File(getApplicationInfo().nativeLibraryDir, "libmihomo.so");
            synchronized (this) {
                if (stopped) return;
                core = new ProcessBuilder(binary.toString(), "-d", dir.toString(), "-f", config.toString())
                        .redirectErrorStream(true).redirectOutput(new File("/dev/null")).start();
            }
            boolean listening = false;
            for (int i=0; i<60 && !stopped && core.isAlive(); i++) {
                try (Socket s = new Socket()) {
                    s.connect(new InetSocketAddress("127.0.0.1", PORT), 150);
                    listening = true;
                    break;
                } catch (IOException notReady) { Thread.sleep(100); }
            }
            if (!listening || !core.isAlive()) throw new IOException("startup");
            String address = verifyExit();
            // Retain compatibility with the existing, unmodified transport-aware diagnostic APK.
            listen("cage_usb_probe_29387", true, uid);
            listen("cage_usb_tls_29389", false, uid);
            File evidence = new File(dir, "online-reference");
            Files.write(evidence.toPath(), (System.currentTimeMillis()+" "+address+"\n").getBytes(StandardCharsets.US_ASCII));
            readyCore = this;
            Log.i(TAG, "ready: verified HTTPS; two local test endpoints");
            File stop = new File(dir, "stop");
            while (!stopped && core.isAlive() && !stop.exists()) Thread.sleep(200);
            stop.delete();
        } catch (Exception ex) {
            startFailed = !stopped;
            Log.i(TAG, "core unavailable: " + ex.getClass().getSimpleName());
        } finally {
            Log.i(TAG, "test core stopped");
            shutdown();
            config.delete();
            stopSelf();
        }
    }
    Socket connectUpstream() throws IOException {
        return connectUpstream(HOST);
    }
    Socket connectUpstream(String destination) throws IOException {
        // The unchanged numeric-address probe uses this IPv4 for the same TLS site.
        boolean numeric = "104.16.185.241".equals(destination);
        if (!HOST.equals(destination) && !numeric && !SpaceSites.allows(destination))
            throw new IOException("outside space destination");
        Socket s = new Socket();
        try {
            s.connect(new InetSocketAddress("127.0.0.1", PORT), 2000);
            s.setSoTimeout(12000);
            DataInputStream in = new DataInputStream(s.getInputStream());
            DataOutputStream out = new DataOutputStream(s.getOutputStream());
            out.write(new byte[]{5,1,2});
            if (in.readUnsignedByte()!=5 || in.readUnsignedByte()!=2) throw new IOException("unexpected auth mode");
            out.writeByte(1); out.writeByte(4); out.writeBytes("cage");
            out.writeByte(password.length()); out.writeBytes(password);
            if (in.readUnsignedByte()!=1 || in.readUnsignedByte()!=0) throw new IOException("authentication");
            if (numeric) {
                out.write(new byte[]{5,1,0,1,104,16,(byte)185,(byte)241});
            } else {
                out.write(new byte[]{5,1,0,3}); out.writeByte(destination.length()); out.writeBytes(destination);
            }
            out.writeShort(443);
            if (in.readUnsignedByte()!=5 || in.readUnsignedByte()!=0) throw new IOException("upstream");
            in.readUnsignedByte();
            int type=in.readUnsignedByte();
            int len=type==1?4:type==4?16:type==3?in.readUnsignedByte():-1;
            if(len<0) throw new IOException("bad reply");
            in.readFully(new byte[len+2]);
            return s;
        } catch(IOException e) {s.close(); throw e;}
    }
    String verifyExit() throws IOException {
        try (Socket raw=connectUpstream();
             SSLSocket tls=(SSLSocket)((SSLSocketFactory)SSLSocketFactory.getDefault()).createSocket(raw, HOST, 443, true)) {
            SSLParameters params=tls.getSSLParameters();
            params.setEndpointIdentificationAlgorithm("HTTPS"); tls.setSSLParameters(params);
            tls.setSoTimeout(12000); tls.startHandshake();
            tls.getOutputStream().write(("GET / HTTP/1.0\r\nHost: "+HOST+"\r\nConnection: close\r\n\r\n").getBytes(StandardCharsets.US_ASCII));
            BufferedReader in=new BufferedReader(new InputStreamReader(tls.getInputStream(), StandardCharsets.US_ASCII));
            String line=in.readLine();
            if(line==null || !line.matches("HTTP/1\\.[01] 200.*")) throw new IOException("status");
            while((line=in.readLine())!=null && !line.isEmpty()) {}
            String ip=in.readLine();
            if(ip==null || !ip.matches("(?:[0-9]{1,3}\\.){3}[0-9]{1,3}") ||
                    !android.util.Patterns.IP_ADDRESS.matcher(ip).matches()) throw new IOException("address");
            return ip;
        }
    }
    private synchronized void listen(String name, boolean http, int uid) throws IOException {
        if (stopped) throw new IOException("stopped");
        LocalServerSocket server = new LocalServerSocket(name);
        listeners.add(server);
        new Thread(() -> {
            while (!stopped) {
                try {
                    LocalSocket c = server.accept();
                    synchronized (this) {
                        if (stopped || c.getPeerCredentials().getUid()!=uid || clients.size()>=4) {c.close(); continue;}
                        clients.add(c);
                    }
                    new Thread(() -> serve(c,http), "Cage-local-flow").start();
                } catch (IOException ended) { return; }
            }
        }, "Cage-local-listen").start();
    }
    private void serve(LocalSocket c, boolean http) {
        try (LocalSocket client=c) {
            client.setSoTimeout(15000);
            if (http) {
                StringBuilder head=new StringBuilder();
                InputStream in=client.getInputStream();
                while (head.length()<4096 && !head.toString().endsWith("\r\n\r\n")) {
                    int ch=in.read(); if(ch<0)return; head.append((char)ch);
                }
                if (!head.toString().startsWith("CONNECT "+HOST+":443 HTTP/1.1\r\n") || !head.toString().endsWith("\r\n\r\n")) return;
            }
            try(Socket target=connectUpstream()) {
                if(http) client.getOutputStream().write("HTTP/1.1 200 Connection Established\r\n\r\n".getBytes(StandardCharsets.US_ASCII));
                new Thread(()->{
                    try {copy(client.getInputStream(),target.getOutputStream()); target.shutdownOutput();} catch(IOException ignored) {}
                }, "Cage-local-send").start();
                copy(target.getInputStream(),client.getOutputStream());
            }
        } catch(IOException ignored) {}
        finally { synchronized(this) {clients.remove(c);} }
    }
    private static void copy(InputStream in, OutputStream out) throws IOException {
        byte[] buf=new byte[8192];
        for (int n;(n=in.read(buf))!=-1;) out.write(buf,0,n);
    }
    private synchronized void shutdown() {
        if (readyCore == this) readyCore = null;
        stopped=true;
        for (LocalServerSocket listener : listeners) {
            // close() alone can leave accept() holding this abstract socket name.
            try { Os.shutdown(listener.getFileDescriptor(), OsConstants.SHUT_RDWR); }
            catch (ErrnoException ignored) {}
            try { listener.close(); } catch (IOException ignored) {}
        }
        listeners.clear();
        for (LocalSocket s:clients) try{s.close();}catch(IOException ignored){}
        if(core!=null && core.isAlive()){
            core.destroy();
            try{if(!core.waitFor(2,TimeUnit.SECONDS)) core.destroyForcibly();}catch(InterruptedException e){core.destroyForcibly();Thread.currentThread().interrupt();}
        }
    }
    @Override public void onDestroy() { shutdown(); running = false; stopForeground(STOP_FOREGROUND_REMOVE); super.onDestroy(); }
}

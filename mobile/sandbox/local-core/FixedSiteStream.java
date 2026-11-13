package io.github.leexeo.cage.localcore;

import android.os.Message;
import android.os.Messenger;
import android.os.ParcelFileDescriptor;
import android.os.RemoteException;
import android.system.*;
import android.util.Log;
import java.io.FileDescriptor;
import java.io.IOException;
import java.io.InterruptedIOException;
import java.net.Socket;
import java.util.concurrent.Semaphore;
import static android.system.OsConstants.*;
import io.github.leexeo.cage.space.SpaceSites;

/** Two one-way pipes form a duplex byte stream to the core's fixed TLS test destination. */
final class FixedSiteStream {
    private static final Semaphore slots = new Semaphore(4);
    private static final int IDLE_MS = 12000;

    static void open(Messenger client, int operation, String destination) {
        Log.d("CageBoundStream", "request operation=" + operation);
        if (!slots.tryAcquire()) {
            unavailable(client, operation);
            return;
        }
        new Thread(() -> {
            boolean delivered = false;
            try {
                CoreService core = CoreService.readyCore;
                if (core == null) throw new IOException("core stopped");
                try (Socket target = core.connectUpstream(destination);
                     ParcelFileDescriptor socket = ParcelFileDescriptor.fromSocket(target)) {
                    ParcelFileDescriptor[] up = ParcelFileDescriptor.createPipe();
                    try (ParcelFileDescriptor input = up[0]; ParcelFileDescriptor sender = up[1]) {
                        ParcelFileDescriptor[] down = ParcelFileDescriptor.createPipe();
                        try (ParcelFileDescriptor receiver = down[0]; ParcelFileDescriptor output = down[1]) {
                            Message result = Message.obtain(null, operation);
                            result.getData().putParcelable("send", sender);
                            result.getData().putParcelable("receive", receiver);
                            client.send(result);
                            delivered = true;
                            Log.d("CageBoundStream", "connected operation=" + operation);
                            sender.close();
                            receiver.close();
                            relay(input.getFileDescriptor(), output.getFileDescriptor(), socket.getFileDescriptor(),
                                    SpaceSites.allows(destination));
                        }
                    }
                }
            } catch (Exception end) {
                if (!delivered) unavailable(client, operation);
                Log.i("CageBoundStream", "delivered=" + delivered + " end=" + end.getClass().getSimpleName());
            } finally {
                slots.release();
            }
        }, "Cage-fixed-site-stream").start();
    }

    private static void unavailable(Messenger client, int operation) {
        try { client.send(Message.obtain(null, operation)); } catch (RemoteException gone) { /* Caller finished. */ }
    }

    private static StructPollfd watch(FileDescriptor fd, int events) {
        StructPollfd item = new StructPollfd();
        item.fd = fd;
        item.events = (short) events;
        return item;
    }

    private static void relay(FileDescriptor input, FileDescriptor output, FileDescriptor socket, boolean space)
            throws ErrnoException, InterruptedIOException, IOException {
        // Small nonblocking writes also bound the time spent on a guest that stops reading.
        for (FileDescriptor fd : new FileDescriptor[]{output, socket})
            Os.fcntlInt(fd, F_SETFL, Os.fcntlInt(fd, F_GETFL, 0) | O_NONBLOCK);
        StructPollfd downstream = watch(socket, POLLIN);
        StructPollfd[] readable = {watch(input, POLLIN), downstream};
        byte[] buf = new byte[4096];
        long[] bytes = {0, 0};
        while (Os.poll(readable, space ? 120000 : IDLE_MS) > 0) {
            for (StructPollfd item : readable) {
                if (item.revents == 0) continue;
                int i = item == downstream ? 1 : 0;
                int count = Os.read(item.fd, buf, 0, buf.length);
                if (count == 0) {
                    if (i == 1) {
                        Log.i("CageBoundStream", "guestSent=" + bytes[0] + " guestReceived=" + bytes[1]);
                        return;
                    }
                    Os.shutdown(socket, SHUT_WR);
                    readable = new StructPollfd[]{downstream};
                    continue;
                }
                bytes[i] += count;
                if (!space && bytes[i] > 131072) throw new IOException("test stream limit");
                FileDescriptor dest = i == 0 ? socket : output;
                StructPollfd[] writable = {watch(dest, POLLOUT)};
                for (int offset = 0; offset < count;) {
                    if (Os.poll(writable, IDLE_MS) == 0) throw new IOException("write timeout");
                    offset += Os.write(dest, buf, offset, count - offset);
                }
            }
        }
    }
}

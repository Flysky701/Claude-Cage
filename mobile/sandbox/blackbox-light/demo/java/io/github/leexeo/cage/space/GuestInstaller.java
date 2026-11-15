package io.github.leexeo.cage.space;

import android.content.ContentProvider;
import android.content.Context;
import android.content.Intent;
import android.content.IntentSender;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageInstaller;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Binder;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.IInterface;
import android.os.Looper;
import android.os.Parcel;
import android.os.ParcelFileDescriptor;
import android.os.Parcelable;
import android.os.Process;
import android.os.RemoteException;
import android.system.Os;
import android.system.OsConstants;
import android.util.AtomicFile;
import android.util.Log;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import org.json.JSONObject;

/** Android PackageInstaller transport backed exclusively by this private space. */
public final class GuestInstaller {
    static final String HOST = "top.niunaijun.microdem";
    static final String STORE = "com.android.vending";
    static final String CLAUDE = "com.anthropic.claude";
    static final String PROVIDER = "content://top.niunaijun.microdem.blackbox.SystemCallProvider";
    static final String SERVICE = "cage_play_installer";
    static final String SOURCE = "cage_play_install_source";
    static final String INSTALLER = "android.content.pm.IPackageInstaller";
    static final String SESSION = "android.content.pm.IPackageInstallerSession";
    static final long MAX_FILE = 160L * 1024 * 1024;
    static final long MAX_TOTAL = 256L * 1024 * 1024;
    private static volatile Engine engine;
    private static Object client;

    private GuestInstaller() {}

    static Context host() throws Exception {
        Context context = (Context) Class.forName("top.niunaijun.blackbox.BlackBoxCore")
            .getMethod("getContext").invoke(null);
        if (!HOST.equals(context.getPackageName())) throw new SecurityException("Wrong private space");
        return context;
    }

    public static synchronized Object get() {
        try {
            if (client != null && ((IInterface) client).asBinder().isBinderAlive()) return client;
            Bundle result = host().getContentResolver().call(Uri.parse(PROVIDER), SERVICE, null, null);
            IBinder binder = result == null ? null : result.getBinder("service");
            if (binder == null) throw new IllegalStateException("Private installer unavailable");
            client = Class.forName(INSTALLER + "$Stub").getMethod("asInterface", IBinder.class)
                .invoke(null, binder);
            return client;
        } catch (Exception e) {
            throw new IllegalStateException("Private installer unavailable", unwrap(e));
        }
    }

    public static Bundle provide(ContentProvider provider, String method, String arg, Bundle extras) {
        if (!SERVICE.equals(method) && !SOURCE.equals(method) && !SharedGateway.METHOD.equals(method)) return null;
        Context context = provider.getContext();
        if (!HOST.equals(context.getPackageName()) || Binder.getCallingUid() != context.getApplicationInfo().uid)
            throw new SecurityException("Private installer caller required");
        try {
            if (SharedGateway.METHOD.equals(method)) return SharedGateway.localStatus(context);
            Engine current = engine;
            if (current == null) {
                synchronized (GuestInstaller.class) {
                    if (engine == null) engine = new Engine(context, new File(context.getFilesDir(), "play-installer"));
                    current = engine;
                }
            }
            Bundle result = new Bundle();
            if (SERVICE.equals(method)) {
                if (arg != null || extras != null) throw new SecurityException("Unexpected installer parameters");
                result.putBinder("service", current.service);
            } else {
                current.caller();
                if (!CLAUDE.equals(arg)) return result;
                Object source = current.installSource(extras != null && extras.getBoolean("newApi"));
                if (source instanceof String) result.putString("installer", (String) source);
                else if (source instanceof Parcelable) result.putParcelable("info", (Parcelable) source);
            }
            return result;
        } catch (Exception e) {
            throw new IllegalStateException("Private installer service unavailable", unwrap(e));
        }
    }

    /** Only records produced by a completed real store session can report Play as installer. */
    public static Object querySource(Method method, Object[] args) {
        String name = method.getName();
        boolean modern = "getInstallSourceInfo".equals(name);
        if ((!modern && !"getInstallerPackageName".equals(name)) || args == null
                || args.length != (modern ? 2 : 1) || !CLAUDE.equals(args[0])) return null;
        try {
            Class<?> thread = Class.forName("top.niunaijun.blackbox.app.BActivityThread");
            int user = ((Integer) thread.getMethod("getUserId").invoke(null)).intValue();
            if (user != 0 || (modern && !Integer.valueOf(user).equals(args[1])))
                throw new SecurityException("Wrong private installer user");
            Bundle request = new Bundle();
            request.putBoolean("newApi", modern);
            Bundle result = host().getContentResolver().call(Uri.parse(PROVIDER), SOURCE, CLAUDE, request);
            if (result == null) return null;
            return modern ? result.getParcelable("info") : result.getString("installer");
        } catch (Exception e) {
            Log.w("CageInstall", "source_lookup_failed=" + unwrap(e).getClass().getSimpleName());
            return null; // The existing identity code truthfully reports a space import.
        }
    }

    static Throwable unwrap(Throwable e) {
        while (e instanceof InvocationTargetException && e.getCause() != null) e = e.getCause();
        return e;
    }

    static Object field(Object object, String name) throws Exception {
        Field f = declaredField(object.getClass(), name);
        return f.get(object);
    }

    static void set(Object object, String name, Object value) throws Exception {
        declaredField(object.getClass(), name).set(object, value);
    }

    static Field declaredField(Class<?> type, String name) throws Exception {
        for (Class<?> current = type; current != null; current = current.getSuperclass()) {
            try {
                Field field = current.getDeclaredField(name);
                field.setAccessible(true);
                return field;
            } catch (NoSuchFieldException missing) { }
        }
        throw new NoSuchFieldException(name);
    }

    static boolean optionalBoolean(Object object, String name) {
        try { return Boolean.TRUE.equals(field(object, name)); }
        catch (Exception e) { return false; }
    }

    static File child(File parent, String name) throws IOException {
        if (name == null || !name.matches("[A-Za-z0-9][A-Za-z0-9._-]{0,159}") || name.contains(".."))
            throw new IllegalArgumentException("Invalid private session filename");
        File file = new File(parent, name);
        if (!file.getCanonicalFile().getParentFile().equals(parent.getCanonicalFile())
                || Files.isSymbolicLink(file.toPath())) throw new SecurityException("Private session path changed");
        return file;
    }

    static JSONObject read(File file) throws Exception {
        try (InputStream in = new AtomicFile(file).openRead()) {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buffer = new byte[4096];
            for (int n; (n = in.read(buffer)) >= 0;) {
                if (out.size() + n > 65536) throw new IOException("Session metadata too large");
                out.write(buffer, 0, n);
            }
            return new JSONObject(new String(out.toByteArray(), StandardCharsets.UTF_8));
        }
    }

    static void write(File file, JSONObject value) throws Exception {
        AtomicFile atomic = new AtomicFile(file);
        FileOutputStream out = atomic.startWrite();
        try {
            out.write(value.toString().getBytes(StandardCharsets.UTF_8));
            atomic.finishWrite(out);
        } catch (Exception e) {
            atomic.failWrite(out);
            throw e;
        }
    }

    static String sha(File file) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        try (InputStream in = new FileInputStream(file)) {
            byte[] buffer = new byte[65536];
            for (int n; (n = in.read(buffer)) >= 0;) digest.update(buffer, 0, n);
        }
        StringBuilder text = new StringBuilder();
        for (byte b : digest.digest()) {
            text.append(Character.forDigit((b >> 4) & 15, 16));
            text.append(Character.forDigit(b & 15, 16));
        }
        return text.toString();
    }

    /** Uses the platform AIDL interface and transaction names, including Android 16 additions. */
    static final class Endpoint extends Binder {
        final Engine engine;
        final int session;
        final String descriptor;
        final Class<?> api;
        final Method transactionName;

        Endpoint(Engine engine, int session) throws Exception {
            this.engine = engine;
            this.session = session;
            descriptor = session == 0 ? INSTALLER : SESSION;
            api = Class.forName(descriptor);
            transactionName = Class.forName(descriptor + "$Stub").getMethod("getDefaultTransactionName", int.class);
            attachInterface(null, descriptor);
        }

        @Override protected boolean onTransact(int code, Parcel data, Parcel reply, int flags) throws RemoteException {
            if (code == INTERFACE_TRANSACTION) { reply.writeString(descriptor); return true; }
            try {
                String name = (String) transactionName.invoke(null, code);
                if (name == null) return super.onTransact(code, data, reply, flags);
                data.enforceInterface(descriptor);
                Method method = null;
                for (Method candidate : api.getMethods()) if (candidate.getName().equals(name)) { method = candidate; break; }
                if (method == null) throw new UnsupportedOperationException("Unknown installer transaction");
                Class<?>[] types = method.getParameterTypes();
                Object[] args = new Object[types.length];
                for (int i = 0; i < args.length; i++) {
                    if (types[i] == List.class && method.getGenericParameterTypes()[i] instanceof java.lang.reflect.ParameterizedType)
                        args[i] = data.createStringArrayList();
                    else args[i] = readArg(data, types[i]);
                }
                if (data.dataAvail() != 0) throw new IllegalArgumentException("Unexpected installer data");
                Object value = engine.invoke(engine.caller(), session, name, args);
                reply.writeNoException();
                writeResult(reply, method.getReturnType(), value);
            } catch (Throwable error) {
                Throwable cause = unwrap(error);
                Log.w("CageInstall", "transaction_failed session=" + (session != 0) + " reason=" + cause.getClass().getSimpleName());
                if (reply == null) return true;
                Exception e = cause instanceof SecurityException ? (SecurityException) cause
                    : cause instanceof IllegalArgumentException ? (IllegalArgumentException) cause
                    : cause instanceof UnsupportedOperationException ? (UnsupportedOperationException) cause
                    : new IllegalStateException("Private installer: " + cause.getClass().getSimpleName());
                reply.writeException(e);
            }
            return true;
        }

        @SuppressWarnings({"rawtypes", "unchecked"})
        static Object readArg(Parcel p, Class<?> type) throws Exception {
            if (type == int.class) return p.readInt();
            if (type == long.class) return p.readLong();
            if (type == float.class) return p.readFloat();
            if (type == boolean.class) return p.readInt() != 0;
            if (type == String.class) return p.readString();
            if (type == String[].class) return p.createStringArray();
            if (type == byte[].class) return p.createByteArray();
            if (type == int[].class) return p.createIntArray();
            if (type == List.class) return p.readArrayList(GuestInstaller.class.getClassLoader());
            if (IInterface.class.isAssignableFrom(type)) {
                return Class.forName(type.getName() + "$Stub").getMethod("asInterface", IBinder.class)
                    .invoke(null, p.readStrongBinder());
            }
            if (Parcelable.class.isAssignableFrom(type))
                return p.readTypedObject((Parcelable.Creator) type.getField("CREATOR").get(null));
            if (type.isArray() && Parcelable.class.isAssignableFrom(type.getComponentType()))
                return p.createTypedArray((Parcelable.Creator) type.getComponentType().getField("CREATOR").get(null));
            throw new UnsupportedOperationException("Unsupported installer argument");
        }

        static void writeResult(Parcel p, Class<?> type, Object value) {
            if (type == void.class) return;
            if (type == int.class) { p.writeInt((Integer) value); return; }
            if (type == boolean.class) { p.writeInt(Boolean.TRUE.equals(value) ? 1 : 0); return; }
            if (type == String[].class) { p.writeStringArray((String[]) value); return; }
            if (type == int[].class) { p.writeIntArray((int[]) value); return; }
            if (type == List.class) { p.writeStringList((List<String>) value); return; }
            if (IInterface.class.isAssignableFrom(type)) { p.writeStrongBinder((IBinder) value); return; }
            p.writeTypedObject((Parcelable) value, Parcelable.PARCELABLE_WRITE_RETURN_VALUE);
        }
    }

    static final class Registration {
        final String owner;
        final IInterface callback;
        Registration(String owner, IInterface callback) { this.owner = owner; this.callback = callback; }
    }

    static final class Session {
        final int id;
        final String owner;
        final File directory;
        final File payload;
        final List<Object> bridges = new ArrayList<>();
        String packageName;
        String label;
        long expectedSize;
        float progress;
        boolean sealed, finished, active;
        int finalStatus = PackageInstaller.STATUS_FAILURE;
        Session(int id, String owner, File root) throws IOException {
            this.id = id;
            this.owner = owner;
            directory = child(root, Integer.toString(id));
            payload = child(directory, "payload");
        }
        void save() throws Exception {
            JSONObject value = new JSONObject().put("id", id).put("owner", owner)
                .put("package", packageName == null ? JSONObject.NULL : packageName)
                .put("label", label == null ? JSONObject.NULL : label).put("size", expectedSize)
                .put("progress", progress).put("sealed", sealed).put("finished", finished).put("status", finalStatus);
            write(child(directory, "session.json"), value);
        }
    }

    static final class Engine {
        final Context context;
        final File root;
        final Endpoint service;
        final Map<Integer, Session> sessions = new HashMap<>();
        final Map<IBinder, Registration> callbacks = new HashMap<>();
        final ExecutorService commits = Executors.newSingleThreadExecutor();
        final Handler handler = new Handler(Looper.getMainLooper());
        final SecureRandom random = new SecureRandom();

        Engine(Context context, File root) throws Exception {
            this.context = context;
            this.root = root.getCanonicalFile();
            if (!HOST.equals(context.getPackageName()) || !this.root.toPath().startsWith(context.getDataDir().getCanonicalFile().toPath()))
                throw new SecurityException("Installer storage must belong to this space");
            if (!this.root.isDirectory() && !this.root.mkdirs()) throw new IOException("Installer storage unavailable");
            File[] previous = this.root.listFiles();
            if (previous != null) for (File entry : previous) {
                if (!entry.getName().matches("[1-9][0-9]{0,8}") || Files.isSymbolicLink(entry.toPath())) continue;
                try {
                    JSONObject value = read(child(entry, "session.json"));
                    String owner = value.getString("owner");
                    if (!STORE.equals(owner) && !HOST.equals(owner)) continue;
                    Session s = new Session(Integer.parseInt(entry.getName()), owner, this.root);
                    s.packageName = value.isNull("package") ? null : value.getString("package");
                    s.label = value.isNull("label") ? null : value.getString("label");
                    s.expectedSize = value.optLong("size", -1);
                    s.progress = (float) value.optDouble("progress", 0);
                    s.sealed = value.optBoolean("sealed");
                    s.finished = value.optBoolean("finished");
                    s.finalStatus = value.optInt("status", PackageInstaller.STATUS_FAILURE);
                    if (s.sealed && !s.finished) { s.finished = true; s.finalStatus = PackageInstaller.STATUS_FAILURE; s.save(); }
                    sessions.put(s.id, s);
                } catch (Exception e) { Log.w("CageInstall", "session_restore_failed=" + e.getClass().getSimpleName()); }
            }
            service = new Endpoint(this, 0);
        }

        String caller() throws Exception {
            if (Binder.getCallingUid() != context.getApplicationInfo().uid) throw new SecurityException("Foreign installer UID");
            if (Binder.getCallingPid() == Process.myPid()) return HOST;
            Class<?> cls = Class.forName("top.niunaijun.blackbox.core.system.BProcessManagerService");
            Object peer = cls.getMethod("findProcessByPid", int.class).invoke(cls.getMethod("get").invoke(null), Binder.getCallingPid());
            if (peer == null || !Integer.valueOf(0).equals(field(peer, "userId"))) throw new SecurityException("Unknown private installer caller");
            String owner = ((ApplicationInfo) field(peer, "info")).packageName;
            if (!STORE.equals(owner) && !CLAUDE.equals(owner) && !"com.google.android.gms".equals(owner))
                throw new SecurityException("Unsupported private installer caller");
            return owner;
        }

        Session owned(String owner, int id, boolean writable) {
            Session s = sessions.get(id);
            if (s == null || !owner.equals(s.owner)) throw new SecurityException("Session does not belong to caller");
            if (writable && (s.sealed || s.finished)) throw new IllegalStateException("Session is sealed");
            return s;
        }

        synchronized Object invoke(String owner, int id, String name, Object[] args) throws Exception {
            if (id == 0) {
                if ("createSession".equals(name)) return create(owner, args);
                if ("openSession".equals(name)) {
                    Session s = owned(owner, (Integer) args[0], false);
                    if (s.finished) throw new IllegalStateException("Session has finished");
                    s.active = true; notify(s, "onSessionActiveChanged", s.id, true);
                    return new Endpoint(this, s.id);
                }
                if ("abandonSession".equals(name)) { abandon(owned(owner, (Integer) args[0], false)); return null; }
                if ("getSessionInfo".equals(name)) {
                    Session s = sessions.get((Integer) args[0]);
                    return s != null && owner.equals(s.owner) ? info(s) : null;
                }
                if ("getAllSessions".equals(name) || "getMySessions".equals(name) || "getStagedSessions".equals(name)) {
                    if (args.length > 0 && !Integer.valueOf(0).equals(args[args.length - 1])) throw new SecurityException("Wrong installer user");
                    if ("getMySessions".equals(name) && !owner.equals(args[0])) throw new SecurityException("Wrong session owner");
                    List<Object> list = new ArrayList<>();
                    if (!"getStagedSessions".equals(name)) for (Session s : sessions.values())
                        if (owner.equals(s.owner) && !s.finished) list.add(info(s));
                    return Class.forName("android.content.pm.ParceledListSlice").getConstructor(List.class).newInstance(list);
                }
                if ("registerCallback".equals(name)) {
                    if (!Integer.valueOf(0).equals(args[1])) throw new SecurityException("Wrong callback user");
                    IInterface cb = (IInterface) args[0];
                    if (cb != null) callbacks.put(cb.asBinder(), new Registration(owner, cb));
                    return null;
                }
                if ("unregisterCallback".equals(name)) {
                    IInterface cb = (IInterface) args[0];
                    if (cb != null) { Registration r = callbacks.get(cb.asBinder()); if (r != null && owner.equals(r.owner)) callbacks.remove(cb.asBinder()); }
                    return null;
                }
                if ("updateSessionAppIcon".equals(name) || "updateSessionAppLabel".equals(name)) {
                    Session s = owned(owner, (Integer) args[0], true);
                    if ("updateSessionAppLabel".equals(name)) s.label = args[1] == null ? null : args[1].toString().substring(0, Math.min(args[1].toString().length(), 128));
                    s.save(); notify(s, "onSessionBadgingChanged", s.id); return null;
                }
                throw new UnsupportedOperationException("Private installer operation not supported: " + name);
            }
            Session s = owned(owner, id, false);
            if ("close".equals(name)) { s.active = false; notify(s, "onSessionActiveChanged", id, false); return null; }
            if ("getNames".equals(name)) return names(s);
            if ("openRead".equals(name)) return ParcelFileDescriptor.open(child(s.payload, (String) args[0]), ParcelFileDescriptor.MODE_READ_ONLY);
            if ("isMultiPackage".equals(name) || "isStaged".equals(name) || "isApplicationEnabledSettingPersistent".equals(name) || "isRequestUpdateOwnership".equals(name)) return false;
            if ("getChildSessionIds".equals(name)) return new int[0];
            if ("getParentSessionId".equals(name)) return -1;
            if ("getInstallFlags".equals(name)) return 0;
            if ("fetchPackageNames".equals(name)) return s.packageName == null ? Collections.emptyList() : Collections.singletonList(s.packageName);
            if ("getDataLoaderParams".equals(name) || "getAppMetadataFd".equals(name) || "getPreVerifiedDomains".equals(name)) return null;
            if ("abandon".equals(name)) { abandon(s); return null; }
            if ("commit".equals(name)) {
                if (s.finished || s.sealed || Boolean.TRUE.equals(args[1])) throw new IllegalStateException("Session cannot be committed");
                if (args[0] == null) throw new IllegalArgumentException("Result receiver required");
                for (Object bridge : s.bridges) if (!bridgeClosed(bridge)) throw new SecurityException("Session still has open streams");
                s.sealed = true; s.save();
                IntentSender receiver = (IntentSender) args[0];
                commits.execute(() -> commit(s, receiver));
                return null;
            }
            owned(owner, id, true);
            if ("setClientProgress".equals(name) || "addClientProgress".equals(name)) {
                float progress = ((Number) args[0]).floatValue();
                if (Float.isNaN(progress) || Float.isInfinite(progress)) throw new IllegalArgumentException("Invalid progress");
                s.progress = Math.max(0, Math.min(1, ("addClientProgress".equals(name) ? s.progress : 0) + progress));
                s.save(); notify(s, "onSessionProgressChanged", id, s.progress); return null;
            }
            if ("openWrite".equals(name)) return openWrite(s, (String) args[0], (Long) args[1], (Long) args[2]);
            if ("write".equals(name)) {
                try (InputStream in = new ParcelFileDescriptor.AutoCloseInputStream((ParcelFileDescriptor) args[3])) {
                    copyTo(s, (String) args[0], (Long) args[1], (Long) args[2], in);
                }
                return null;
            }
            if ("stageViaHardLink".equals(name)) {
                File src = new File((String) args[0]).getCanonicalFile();
                File allowed = new File(context.getDataDir(), "blackbox/data/user/0/" + owner).getCanonicalFile();
                if (!src.toPath().startsWith(allowed.toPath()) || !src.isFile()) throw new SecurityException("Staging requires a private caller file");
                try (InputStream in = new FileInputStream(src)) { copyTo(s, "staged-" + names(s).length + ".apk", 0, src.length(), in); }
                return null;
            }
            if ("setChecksums".equals(name)) { child(s.payload, (String) args[0]); return null; } // Original APK signatures are checked at commit.
            if ("removeAppMetadata".equals(name)) return null;
            if ("seal".equals(name)) throw new UnsupportedOperationException("Seal through commit");
            throw new UnsupportedOperationException("Private session operation not supported: " + name);
        }

        int create(String owner, Object[] args) throws Exception {
            if (!STORE.equals(owner) && !HOST.equals(owner)) throw new SecurityException("Private Play installer required");
            if (!owner.equals(args[1]) || !Integer.valueOf(0).equals(args[args.length - 1])) throw new SecurityException("Incorrect installer identity");
            PackageInstaller.SessionParams params = (PackageInstaller.SessionParams) args[0];
            int mode = ((Integer) field(params, "mode")).intValue();
            String target = (String) field(params, "appPackageName");
            if (mode != PackageInstaller.SessionParams.MODE_FULL_INSTALL || optionalBoolean(params, "isMultiPackage") || optionalBoolean(params, "isStaged"))
                throw new UnsupportedOperationException("This space supports full, non-staged app sessions");
            if (target != null && !CLAUDE.equals(target)) throw new SecurityException("This DEMO only installs Claude from Play");
            long size = ((Number) field(params, "sizeBytes")).longValue();
            if (size > MAX_TOTAL) throw new IllegalArgumentException("Session is too large");
            int active = 0; for (Session s : sessions.values()) if (!s.finished) active++;
            if (active >= 16) throw new IllegalStateException("Too many active sessions");
            int id; do { id = random.nextInt(900000000) + 1; } while (sessions.containsKey(id) || child(root, Integer.toString(id)).exists());
            Session s = new Session(id, owner, root);
            if (!s.payload.mkdirs()) throw new IOException("Cannot create session storage");
            s.packageName = target; s.expectedSize = size; s.save(); sessions.put(id, s);
            notify(s, "onSessionCreated", id);
            Log.i("CageInstall", "session_created mode=full owner=" + owner);
            return id;
        }

        String[] names(Session s) throws IOException {
            List<String> result = new ArrayList<>();
            File[] files = s.payload.listFiles();
            if (files != null) for (File file : files) if (child(s.payload, file.getName()).isFile()) result.add(file.getName());
            Collections.sort(result);
            return result.toArray(new String[0]);
        }

        ParcelFileDescriptor fileForWrite(Session s, String name, long offset, long length) throws Exception {
            if (offset < 0 || offset > MAX_FILE || length < -1 || length > MAX_FILE || (length >= 0 && offset > MAX_FILE - length))
                throw new IllegalArgumentException("Invalid session file range");
            File file = child(s.payload, name);
            if (!file.exists() && names(s).length >= 64) throw new IllegalArgumentException("Too many APK parts");
            ParcelFileDescriptor fd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_CREATE | ParcelFileDescriptor.MODE_READ_WRITE);
            try { Os.lseek(fd.getFileDescriptor(), offset, OsConstants.SEEK_SET); }
            catch (Exception e) { fd.close(); throw e; }
            return fd;
        }

        ParcelFileDescriptor openWrite(Session s, String name, long offset, long length) throws Exception {
            ParcelFileDescriptor fd = fileForWrite(s, name, offset, length);
            boolean revocable = (Boolean) PackageInstaller.class.getField("ENABLE_REVOCABLE_FD").get(null);
            if (revocable) {
                fd.close();
                final boolean[] closed = { false };
                ParcelFileDescriptor watched = ParcelFileDescriptor.open(child(s.payload, name),
                    ParcelFileDescriptor.MODE_CREATE | ParcelFileDescriptor.MODE_READ_WRITE,
                    handler, error -> { synchronized (Engine.this) { closed[0] = true; } });
                Os.lseek(watched.getFileDescriptor(), offset, OsConstants.SEEK_SET);
                s.bridges.add(closed); return watched;
            }
            try {
                Class<?> cls = Class.forName("android.os.FileBridge");
                Object bridge = cls.getConstructor().newInstance();
                cls.getMethod("setTargetFile", ParcelFileDescriptor.class).invoke(bridge, fd);
                ParcelFileDescriptor client = (ParcelFileDescriptor) cls.getMethod("getClientSocket").invoke(bridge);
                s.bridges.add(bridge);
                ((Thread) bridge).start();
                return client;
            } catch (Exception e) { fd.close(); throw e; }
        }

        void copyTo(Session s, String name, long offset, long length, InputStream in) throws Exception {
            try (FileOutputStream out = new ParcelFileDescriptor.AutoCloseOutputStream(fileForWrite(s, name, offset, length))) {
                byte[] buffer = new byte[65536]; long total = offset;
                for (int n; (n = in.read(buffer)) >= 0;) {
                    if ((total += n) > MAX_FILE || (length >= 0 && total - offset > length)) throw new IOException("Session file too large");
                    out.write(buffer, 0, n);
                }
                out.getFD().sync();
            }
        }

        boolean bridgeClosed(Object bridge) throws Exception {
            return bridge instanceof boolean[] ? ((boolean[]) bridge)[0]
                : Boolean.TRUE.equals(bridge.getClass().getMethod("isClosed").invoke(bridge));
        }

        void abandon(Session s) throws Exception {
            if (s.sealed && !s.finished) throw new IllegalStateException("Commit is already running");
            for (Object bridge : s.bridges) if (!(bridge instanceof boolean[])) bridge.getClass().getMethod("forceClose").invoke(bridge);
            s.finished = true; s.active = false; s.finalStatus = PackageInstaller.STATUS_FAILURE_ABORTED; s.save();
            notify(s, "onSessionFinished", s.id, false);
        }

        Object info(Session s) throws Exception {
            Object info = PackageInstaller.SessionInfo.class.getDeclaredConstructor().newInstance();
            set(info, "sessionId", s.id); set(info, "userId", 0); set(info, "installerPackageName", s.owner);
            set(info, "progress", s.progress); set(info, "sealed", s.sealed); set(info, "active", s.active);
            set(info, "mode", PackageInstaller.SessionParams.MODE_FULL_INSTALL); set(info, "sizeBytes", s.expectedSize);
            set(info, "appPackageName", s.packageName); set(info, "appLabel", s.label);
            return info;
        }

        void notify(Session session, String method, Object... args) {
            List<Registration> snapshot = new ArrayList<>(callbacks.values());
            for (Registration r : snapshot) {
                if (!session.owner.equals(r.owner)) continue;
                try {
                    Class<?> api = Class.forName("android.content.pm.IPackageInstallerCallback");
                    for (Method candidate : api.getMethods()) if (candidate.getName().equals(method)) { candidate.invoke(r.callback, args); break; }
                } catch (Exception e) { callbacks.remove(r.callback.asBinder()); }
            }
        }

        void commit(Session s, IntentSender receiver) {
            int status = PackageInstaller.STATUS_FAILURE_INVALID;
            String reason = "安装包校验或私有安装失败";
            try {
                String[] files;
                synchronized (this) { files = names(s); }
                if (files.length == 0) throw new IOException("Empty session");
                File archive = child(s.directory, "payload.zip");
                String expectedBase = null; long expectedVersion = -1; long total = 0;
                try (ZipOutputStream out = new ZipOutputStream(new FileOutputStream(archive))) {
                    for (String name : files) {
                        File file = child(s.payload, name);
                        if (file.length() <= 0 || file.length() > MAX_FILE || (total += file.length()) > MAX_TOTAL)
                            throw new IOException("Invalid staged file size");
                        Object apk = inspect(file);
                        String split = (String) field(apk, "split");
                        long version = ((Number) field(apk, "version")).longValue();
                        if (expectedVersion != -1 && expectedVersion != version) throw new IOException("Mixed APK versions");
                        expectedVersion = version;
                        if (split == null || split.length() == 0) {
                            if (expectedBase != null) throw new IOException("Duplicate base APK");
                            expectedBase = sha(file);
                        }
                        out.putNextEntry(new ZipEntry("part-" + outIndex(name, files) + ".apk"));
                        try (InputStream in = new FileInputStream(file)) {
                            byte[] buffer = new byte[65536]; for (int n; (n = in.read(buffer)) >= 0;) out.write(buffer, 0, n);
                        }
                        out.closeEntry();
                    }
                }
                if (expectedBase == null) throw new IOException("Missing base APK");
                Log.i("CageInstall", "commit_validated parts=" + files.length);
                Class.forName("io.github.leexeo.cage.space.ClaudeBundle").getMethod("install", Context.class, File.class).invoke(null, context, archive);
                File installed = installedBase();
                PackageInfo info = context.getPackageManager().getPackageArchiveInfo(installed.getPath(), PackageManager.GET_SIGNING_CERTIFICATES);
                if (info == null || !CLAUDE.equals(info.packageName) || info.getLongVersionCode() != expectedVersion || !expectedBase.equals(sha(installed)))
                    throw new IOException("Private install did not match the staged APK");
                JSONObject source = new JSONObject().put("package", CLAUDE).put("installer", s.owner)
                    .put("version", expectedVersion).put("baseSha256", expectedBase).put("session", s.id);
                write(child(root, "provenance.json"), source);
                status = PackageInstaller.STATUS_SUCCESS; reason = "已安装到此空间";
            } catch (Throwable error) {
                Throwable cause = unwrap(error);
                if (cause instanceof SecurityException) status = PackageInstaller.STATUS_FAILURE_BLOCKED;
                Log.w("CageInstall", "commit_failed reason=" + cause.getClass().getSimpleName());
            }
            synchronized (this) {
                s.finished = true; s.active = false; s.packageName = CLAUDE; s.finalStatus = status;
                if (status == PackageInstaller.STATUS_SUCCESS) s.progress = 1;
                try { s.save(); } catch (Exception e) { Log.w("CageInstall", "session_save_failed"); }
                notify(s, "onSessionFinished", s.id, status == PackageInstaller.STATUS_SUCCESS);
            }
            Intent result = new Intent().putExtra(PackageInstaller.EXTRA_SESSION_ID, s.id)
                .putExtra(PackageInstaller.EXTRA_PACKAGE_NAME, CLAUDE).putExtra(PackageInstaller.EXTRA_STATUS, status)
                .putExtra(PackageInstaller.EXTRA_STATUS_MESSAGE, reason);
            try { receiver.sendIntent(context, 0, result, null, null); }
            catch (Exception e) { Log.w("CageInstall", "result_delivery_failed=" + e.getClass().getSimpleName()); }
            Log.i("CageInstall", "session_finished status=" + status);
        }

        int outIndex(String name, String[] names) { for (int i = 0; i < names.length; i++) if (name.equals(names[i])) return i; throw new AssertionError(); }

        Object inspect(File file) throws Exception {
            Method method = Class.forName("io.github.leexeo.cage.space.ClaudeBundle").getDeclaredMethod("inspect", File.class);
            method.setAccessible(true);
            return method.invoke(null, file);
        }

        File installedBase() throws IOException {
            File base = new File(context.getDataDir().getCanonicalFile(), "blackbox/data/app/com.anthropic.claude/base.apk");
            if (!base.getCanonicalFile().equals(base.getAbsoluteFile()) || !base.isFile()) throw new IOException("Private base APK unavailable");
            return base;
        }

        synchronized Object installSource(boolean modern) throws Exception {
            File record = child(root, "provenance.json");
            if (!record.isFile()) return null;
            JSONObject source = read(record);
            File base = installedBase();
            if (!CLAUDE.equals(source.optString("package")) || !STORE.equals(source.optString("installer"))
                    || !source.getString("baseSha256").equals(sha(base))) return null;
            if (!modern) return STORE;
            Class<?> core = Class.forName("top.niunaijun.blackbox.BlackBoxCore");
            Object pm = core.getMethod("getBPackageManager").invoke(null);
            ApplicationInfo app = (ApplicationInfo) pm.getClass().getMethod("getApplicationInfo", String.class, int.class, int.class)
                .invoke(pm, STORE, 0, 0);
            if (app == null || !new File(app.sourceDir).getCanonicalFile().toPath().startsWith(context.getDataDir().getCanonicalFile().toPath())) return null;
            PackageInfo store = context.getPackageManager().getPackageArchiveInfo(app.sourceDir, PackageManager.GET_SIGNING_CERTIFICATES);
            if (store == null || store.signingInfo == null) return null;
            return Class.forName("android.content.pm.InstallSourceInfo")
                .getConstructor(String.class, android.content.pm.SigningInfo.class, String.class, String.class)
                .newInstance(STORE, store.signingInfo, null, STORE);
        }
    }
}

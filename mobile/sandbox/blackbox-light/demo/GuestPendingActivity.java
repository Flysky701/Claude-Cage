package io.github.leexeo.cage.space;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.ComponentName;
import android.content.ContentProvider;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.ResolveInfo;
import android.net.Uri;
import android.os.Binder;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.os.IInterface;
import android.os.SystemClock;
import android.util.Log;
import java.io.File;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.UUID;

/**
 * Transfers this DEMO's one microG sign-in result to the original Claude activity token.
 * The actual Android PendingIntent is still sent first, so Android checks cancellation
 * and consumes its one-shot capability. Only its otherwise result-losing host trampoline
 * is suppressed. Google request extras and the eventual credential response stay opaque.
 * No account, token, signature, consent, or authenticator result is manufactured here.
 */
public final class GuestPendingActivity {
    private static final String HOST = "top.niunaijun.microdem";
    private static final String CLAUDE = "com.anthropic.claude";
    private static final String GMS = "com.google.android.gms";
    private static final String ACTION = "com.google.android.gms.auth.api.credentials.ASSISTED_SIGNIN";
    private static final String ACTIVITY = "org.microg.gms.auth.signin.AssistedSignInActivity";
    private static final String IDENTITY_ACTIVITY = "org.microg.gms.auth.credentials.identity.IdentityCredentialChooserActivity";
    private static final String IDENTITY_PACKAGE = "org.microg.gms.identitycredentials.EXTRA_CALLING_PACKAGE";
    private static final String IDENTITY_REQUEST = "org.microg.gms.identitycredentials.EXTRA_GET_REQUEST";
    private static final String CALLER = "androidx.credentials.playservices.controllers.identityauth.HiddenActivity";
    private static final String METHOD = "cage_demo_google_pending";
    private static final String AUTHORITY = HOST + ".blackbox.SystemCallProvider";
    private static final String MARKER = "io.github.leexeo.cage.space.GOOGLE_PENDING";
    private static final String SCHEME = "cage-private-google-pending";
    private static final long LIFETIME_MS = 120_000;
    private static final int REQUIRED_FLAGS = PendingIntent.FLAG_ONE_SHOT | PendingIntent.FLAG_IMMUTABLE;
    private static final int IDENTITY_FLAGS = PendingIntent.FLAG_ONE_SHOT
            | PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_MUTABLE;
    // Accessed only in the private system provider's process, never written to disk.
    private static final Map<IBinder, Route> ROUTES = new HashMap<>();

    private GuestPendingActivity() {}

    private static final class Route {
        final Intent target;
        final Object creator;
        final long created = SystemClock.elapsedRealtime();
        Route(Intent target, Object creator) { this.target = new Intent(target); this.creator = creator; }
    }

    /** Called after GetIntentSender wraps Intent[], immediately before its real system call. */
    public static void prepare(Method method, Object[] args) {
        if (!guest(GMS)) return;
        Intent wrapper = wrapper(args);
        Intent target = inner(wrapper);
        if (!candidate(target)) return;
        try {
            creationShape(method, args);
            targetShape(target);
            if (wrapper.getData() != null || wrapper.hasExtra(MARKER)) throw denied();
            String id = UUID.randomUUID().toString();
            wrapper.putExtra(MARKER, id);
            // The upstream wrapper otherwise makes unrelated UPDATE_CURRENT intents equal.
            // A unique host-only data URI prevents one request replacing another's target.
            wrapper.setData(new Uri.Builder().scheme(SCHEME).authority("request").appendPath(id).build());
            Log.i("CageDemo", "Google pending: prepared");
        } catch (Exception failure) { throw blocked("prepare", failure); }
    }

    /** Called with the real IIntentSender result before GetIntentSender overwrites its locals. */
    public static void created(IInterface sender, Method method, Object[] args) {
        if (!guest(GMS)) return;
        Intent wrapper = wrapper(args);
        if (!candidate(inner(wrapper))) return;
        try {
            creationShape(method, args);
            marker(wrapper);
            if (sender == null || sender.asBinder() == null) throw denied();
            Bundle request = new Bundle();
            request.putBinder("sender", sender.asBinder());
            request.putParcelable("wrapper", new Intent(wrapper));
            Bundle reply = request("register", request);
            if (reply == null || !reply.getBoolean("registered")) throw denied();
        } catch (Exception failure) {
            // This is our own newly-created host capability, not another app's pending work.
            try {
                if (sender != null) Class.forName("android.app.IActivityManager")
                        .getMethod("cancelIntentSender", Class.forName("android.content.IIntentSender"))
                        .invoke(realActivityManager(), sender);
            } catch (Exception ignored) {}
            throw blocked("register-client", failure);
        }
    }

    /** Insert at the start of the private SystemCallProvider.call implementation. */
    public static Bundle call(ContentProvider provider, String method, String argument, Bundle extras) {
        if (!METHOD.equals(method)) return null;
        String stage = "provider-caller";
        try {
            Context host = provider.getContext();
            if (host == null || !HOST.equals(host.getPackageName()) || extras == null
                    || Binder.getCallingUid() != host.getApplicationInfo().uid) throw denied();
            Object caller = process(Binder.getCallingPid());
            ApplicationInfo app = (ApplicationInfo) field(caller, "info");
            if (((Integer) field(caller, "userId")) != 0) throw denied();
            IBinder sender = extras.getBinder("sender");
            if (sender == null || !sender.isBinderAlive()) throw denied();
            stage = "provider-system-owner";
            boolean immutable = requireRealSenderOwner(host, sender);
            if ("register".equals(argument)) {
                stage = "register-shape";
                if (!GMS.equals(app.packageName)) throw denied();
                Intent wrapper = extras.getParcelable("wrapper");
                marker(wrapper);
                String expected = (String) Class.forName("top.niunaijun.blackbox.proxy.ProxyManifest")
                        .getMethod("getProxyPendingActivity", int.class).invoke(null, field(caller, "bpid"));
                if (!new ComponentName(HOST, expected).equals(wrapper.getComponent())
                        || wrapper.getIntExtra("_B_|_P_user_id_", -1) != 0) throw denied();
                Intent target = inner(wrapper);
                targetShape(target);
                stage = "register-mutability";
                requireMutability(target, immutable);
                stage = "register-private-target";
                privateTarget(host, target);
                synchronized (ROUTES) {
                    expire();
                    if (ROUTES.size() >= 16 || ROUTES.containsKey(sender)) throw denied();
                    ROUTES.put(sender, new Route(target, caller));
                }
                Bundle result = new Bundle();
                result.putBoolean("registered", true);
                Log.i("CageDemo", "Google pending: registered");
                return result;
            }
            if (!"claim".equals(argument) || !CLAUDE.equals(app.packageName)) throw denied();
            IBinder resultTo = extras.getBinder("resultTo");
            IBinder appThread = extras.getBinder("caller");
            if (!(field(caller, "appThread") instanceof IInterface)
                    || !((IInterface) field(caller, "appThread")).asBinder().equals(appThread)) throw denied();
            stage = "claim-result-owner";
            verifyResultOwner(caller, resultTo);
            Route route;
            synchronized (ROUTES) {
                expire();
                route = ROUTES.remove(sender); // A second claim, including after failure, is rejected.
            }
            if (route == null || process((Integer) field(route.creator, "pid")) != route.creator) throw denied();
            Intent target = new Intent(route.target);
            stage = "claim-mutability";
            requireMutability(target, immutable);
            stage = "claim-private-target";
            privateTarget(host, target);
            Bundle result = new Bundle();
            result.putParcelable("target", target);
            Log.i("CageDemo", "Google pending: claimed");
            return result;
        } catch (Exception failure) { throw blocked(stage, failure); }
    }

    /**
     * Called by IActivityTaskManagerProxy.invoke before its ordinary method dispatch.
     * null means untouched. Every unknown sender in this Claude-only method is rejected.
     */
    public static Object start(Object base, Method method, Object[] args) {
        if (!"startActivityIntentSender".equals(method.getName()) || !guest(CLAUDE)) return null;
        String stage = "start-shape";
        try {
            startShape(method, args);
            IInterface sender = (IInterface) args[1];
            Bundle request = new Bundle();
            request.putBinder("sender", sender.asBinder());
            request.putBinder("caller", ((IInterface) args[0]).asBinder());
            request.putBinder("resultTo", (IBinder) args[5]);
            stage = "start-claim";
            Bundle reply = request("claim", request);
            Intent target = reply == null ? null : reply.getParcelable("target");
            targetShape(target);

            // Consume the real one-shot PendingIntent normally, with no fill-in.
            // The identity chooser's original capability is mutable; no target or
            // extra is changed when sending it. Its host
            // trampoline must not send an extra RESULT_CANCELED to the guest caller.
            Object[] dispatch = args.clone();
            dispatch[5] = null;
            dispatch[6] = null;
            dispatch[7] = -1;
            stage = "system-send";
            int accepted = (Integer) method.invoke(base, dispatch);
            // Unique, fresh host wrappers must return START_SUCCESS (0). Non-fatal
            // errors such as START_ABORTED (102) also block the private launch.
            // START_CANCELED (-96) makes Activity report SendIntentException normally.
            if (accepted != 0) return accepted < 0 ? accepted : -96;
            Log.i("CageDemo", "Google pending: systemAccepted");

            // Use the raw private service: its wrapper has broad external fallbacks.
            stage = "private-service";
            Class<?> core = Class.forName("top.niunaijun.blackbox.BlackBoxCore");
            Object manager = core.getMethod("getBActivityManager").invoke(null);
            Object service = manager.getClass().getMethod("getService").invoke(manager);
            if (service == null) throw denied();
            Method start = Class.forName("top.niunaijun.blackbox.core.system.am.IBActivityManagerService")
                    .getMethod("startActivityAms", int.class, Intent.class, String.class, IBinder.class,
                            String.class, int.class, int.class, Bundle.class);
            // The original Android activity token, resultWho and requestCode are passed intact.
            stage = "private-dispatch";
            Object result = start.invoke(service, 0, target, args[4], args[5], args[6], args[7], 0, args[10]);
            Log.i("CageDemo", "Google pending: privateDispatched");
            return result;
        } catch (Exception failure) {
            blocked(stage, failure);
            // Android turns START_CANCELED into SendIntentException, which the
            // original credentials activity already handles as a failed request.
            return -96;
        }
    }

    /** Called after ProxyPendingActivity's super.onCreate and before its old finish/start code. */
    public static boolean finishProxy(Activity activity) {
        Intent wrapper = activity.getIntent();
        boolean ours = wrapper != null && (wrapper.hasExtra(MARKER)
                || (wrapper.getData() != null && SCHEME.equals(wrapper.getData().getScheme())));
        if (!ours && (!guest(GMS) || !candidate(inner(wrapper)))) return false;
        // A marked or unrecognized old Google pending trampoline never launches a second target.
        activity.finish();
        Log.i("CageDemo", "Google pending: trampolineSuppressed");
        return true;
    }

    private static void verifyResultOwner(Object caller, IBinder token) throws Exception {
        if (token == null || !token.isBinderAlive()) throw denied();
        Object manager = Class.forName("top.niunaijun.blackbox.core.system.am.BActivityManagerService")
                .getMethod("get").invoke(null);
        @SuppressWarnings("unchecked") Map<Integer, ?> spaces = (Map<Integer, ?>) field(manager, "mUserSpace");
        Object space;
        synchronized (spaces) { space = spaces.get(0); }
        if (space == null) throw denied();
        Object stack = field(space, "mStack");
        synchronized (stack) {
            Object tasks = field(stack, "mTasks");
            synchronized (tasks) {
                Method find = stack.getClass().getDeclaredMethod("findActivityRecordByToken", int.class, IBinder.class);
                find.setAccessible(true);
                Object record = find.invoke(stack, 0, token);
                if (record == null || !Boolean.FALSE.equals(field(record, "finished"))
                        || field(record, "processRecord") != caller || !token.equals(field(record, "token"))
                        || !new ComponentName(CLAUDE, CALLER).equals(field(record, "component"))) throw denied();
            }
        }
    }

    private static void privateTarget(Context host, Intent target) throws Exception {
        targetShape(target);
        boolean identity = identity(target);
        String expectedActivity = identity ? IDENTITY_ACTIVITY : ACTIVITY;
        Class<?> pm = Class.forName("top.niunaijun.blackbox.core.system.pm.BPackageManagerService");
        ResolveInfo resolved = (ResolveInfo) pm.getMethod("resolveActivity", Intent.class, int.class, String.class, int.class)
                .invoke(pm.getMethod("get").invoke(null), target, 0, null, 0);
        ActivityInfo activity = resolved == null ? null : resolved.activityInfo;
        // The identity chooser is intentionally non-exported. Only the registered
        // microG-created capability above may reach it; no direct external route.
        if (activity == null || !GMS.equals(activity.packageName) || !expectedActivity.equals(activity.name)
                || !activity.enabled || activity.exported == identity) throw denied();
        SpacePackages packages = new SpacePackages(host);
        PackageInfo installed = packages.installed(GMS);
        if (!packages.privateCopy(installed) || activity.applicationInfo == null
                || !new File(installed.applicationInfo.sourceDir).getCanonicalFile()
                    .equals(new File(activity.applicationInfo.sourceDir).getCanonicalFile())) throw denied();
        SpacePackages.inspect(host, new File(installed.applicationInfo.sourceDir));
        target.setComponent(new ComponentName(GMS, expectedActivity));
    }

    private static Object process(int pid) throws Exception {
        Class<?> processes = Class.forName("top.niunaijun.blackbox.core.system.BProcessManagerService");
        Object result = processes.getMethod("findProcessByPid", int.class).invoke(processes.getMethod("get").invoke(null), pid);
        if (result == null || (Integer) field(result, "pid") != pid) throw denied();
        return result;
    }

    private static Object field(Object object, String name) throws Exception {
        Field field = object.getClass().getDeclaredField(name);
        field.setAccessible(true);
        return field.get(object);
    }

    private static boolean guest(String pkg) {
        if (Build.VERSION.SDK_INT < 34) return false;
        try {
            Class<?> core = Class.forName("top.niunaijun.blackbox.BlackBoxCore");
            Context host = (Context) core.getMethod("getContext").invoke(null);
            if (!HOST.equals(host.getPackageName())
                    || !(Boolean) core.getMethod("isBlackProcess").invoke(core.getMethod("get").invoke(null))) return false;
            Class<?> thread = Class.forName("top.niunaijun.blackbox.app.BActivityThread");
            return pkg.equals(thread.getMethod("getAppPackageName").invoke(null))
                    && (Integer) thread.getMethod("getUserId").invoke(null) == 0;
        } catch (ReflectiveOperationException failure) { throw denied(); }
    }

    private static Bundle request(String operation, Bundle extras) throws Exception {
        Context host = (Context) Class.forName("top.niunaijun.blackbox.BlackBoxCore").getMethod("getContext").invoke(null);
        return host.getContentResolver().call(Uri.parse("content://" + AUTHORITY), METHOD, operation, extras);
    }

    private static boolean requireRealSenderOwner(Context host, IBinder sender) throws Exception {
        Class<?> senderType = Class.forName("android.content.IIntentSender");
        Object senderInterface = Class.forName("android.content.IIntentSender$Stub")
                .getMethod("asInterface", IBinder.class).invoke(null, sender);
        Object info = Class.forName("android.app.IActivityManager")
                .getMethod("getInfoForIntentSender", senderType).invoke(realActivityManager(), senderInterface);
        if (info != null) Log.i("CageDemo", "Google pending owner: package="
                + info.getClass().getMethod("getCreatorPackage").invoke(info)
                + " uidMatches=" + Integer.valueOf(host.getApplicationInfo().uid).equals(info.getClass().getMethod("getCreatorUid").invoke(info))
                + " immutable=" + info.getClass().getMethod("isImmutable").invoke(info)
                + " type=" + info.getClass().getMethod("getIntentSenderType").invoke(info));
        if (info == null || !HOST.equals(info.getClass().getMethod("getCreatorPackage").invoke(info))
                || (Integer) info.getClass().getMethod("getCreatorUid").invoke(info) != host.getApplicationInfo().uid
                || !Integer.valueOf(2).equals(info.getClass().getMethod("getIntentSenderType").invoke(info))) throw denied();
        Object immutable = info.getClass().getMethod("isImmutable").invoke(info);
        if (!(immutable instanceof Boolean)) throw denied();
        return (Boolean) immutable;
    }

    private static void requireMutability(Intent target, boolean immutable) {
        // Do not broaden the old assisted-sign-in route to accept mutable senders.
        if (immutable != !identity(target)) throw denied();
    }

    /** Never consult the virtual GetPackage/UidForIntentSender registry for host ownership. */
    private static Object realActivityManager() throws Exception {
        IBinder binder = (IBinder) Class.forName("android.os.ServiceManager")
                .getMethod("getService", String.class).invoke(null, "activity");
        Class<?> hook = Class.forName("top.niunaijun.blackbox.fake.hook.BinderInvocationStub");
        Field original = hook.getDeclaredField("mBaseBinder");
        original.setAccessible(true);
        for (int depth = 0; depth < 4 && hook.isInstance(binder); depth++)
            binder = (IBinder) original.get(binder);
        if (binder == null || !"android.os.BinderProxy".equals(binder.getClass().getName())
                || !binder.isBinderAlive()) throw denied();
        Object manager = Class.forName("android.app.IActivityManager$Stub")
                .getMethod("asInterface", IBinder.class).invoke(null, binder);
        if (!(manager instanceof IInterface) || Proxy.isProxyClass(manager.getClass())
                || !binder.equals(((IInterface) manager).asBinder())) throw denied();
        return manager;
    }

    private static Intent wrapper(Object[] args) {
        if (args == null) return null;
        for (Object arg : args) if (arg instanceof Intent[]) {
            Intent[] intents = (Intent[]) arg;
            return intents.length == 1 ? intents[0] : null;
        }
        return null;
    }

    private static Intent inner(Intent wrapper) {
        return wrapper == null ? null : wrapper.getParcelableExtra("_B_|_P_target_");
    }

    private static boolean candidate(Intent intent) {
        return intent != null && (ACTION.equals(intent.getAction()) || identity(intent));
    }

    private static boolean identity(Intent intent) {
        return intent != null && new ComponentName(GMS, IDENTITY_ACTIVITY).equals(intent.getComponent());
    }

    private static void targetShape(Intent target) {
        if (!candidate(target) || target.getData() != null || target.getType() != null
                || target.getSelector() != null || target.getClipData() != null || target.getFlags() != 0) throw denied();
        if (identity(target)) {
            Bundle extras = target.getExtras();
            if (target.getAction() != null || target.getPackage() != null || target.getCategories() != null
                    || !CLAUDE.equals(target.getStringExtra(IDENTITY_PACKAGE))
                    || extras == null || extras.size() != 2 || target.getBundleExtra(IDENTITY_REQUEST) == null) throw denied();
            // The nested Bundle contains a microG Parcelable. Keep it opaque here;
            // the original chooser sets its own request class loader before reading.
            return;
        }
        if (!GMS.equals(target.getPackage())
                || (target.getComponent() != null && !new ComponentName(GMS, ACTIVITY).equals(target.getComponent()))
                || !CLAUDE.equals(target.getStringExtra("client_package_name"))
                || !target.hasExtra("get_sign_in_intent_request") || !target.hasExtra("google_sign_in_options")) throw denied();
    }

    private static void marker(Intent wrapper) {
        if (wrapper == null) throw denied();
        String id = wrapper.getStringExtra(MARKER);
        if (id == null || !id.matches("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")) throw denied();
        Uri expected = new Uri.Builder().scheme(SCHEME).authority("request").appendPath(id).build();
        if (!expected.equals(wrapper.getData())) throw denied();
    }

    private static void creationShape(Method method, Object[] args) {
        if (!("getIntentSender".equals(method.getName()) || "getIntentSenderWithFeature".equals(method.getName())
                || "getIntentSenderWithSourceToken".equals(method.getName())) || args == null
                || args.length != method.getParameterTypes().length || !Integer.valueOf(2).equals(args[0])) throw denied();
        int found = -1;
        Class<?>[] types = method.getParameterTypes();
        for (int i = 0; i < types.length; i++) if (types[i] == Intent[].class) {
            if (found >= 0) throw denied();
            found = i;
        }
        if (found < 0 || found + 2 >= args.length || types[found + 1] != String[].class
                || types[found + 2] != int.class || !(args[found + 2] instanceof Integer)) throw denied();
        int flags = (Integer) args[found + 2];
        if (identity(inner(wrapper(args)))) {
            if (flags != IDENTITY_FLAGS) throw denied();
        } else if ((flags & REQUIRED_FLAGS) != REQUIRED_FLAGS
                || (flags & ~(REQUIRED_FLAGS | PendingIntent.FLAG_UPDATE_CURRENT)) != 0) throw denied();
    }

    private static void startShape(Method method, Object[] args) {
        String[] expected = {"android.app.IApplicationThread", "android.content.IIntentSender", "android.os.IBinder",
                "android.content.Intent", "java.lang.String", "android.os.IBinder", "java.lang.String", "int", "int", "int", "android.os.Bundle"};
        Class<?>[] types = method.getParameterTypes();
        if (args == null || args.length != expected.length || types.length != expected.length || method.getReturnType() != int.class) throw denied();
        for (int i = 0; i < expected.length; i++) if (!expected[i].equals(types[i].getName())) throw denied();
        if (!(args[0] instanceof IInterface) || !(args[1] instanceof IInterface) || args[2] != null || args[3] != null
                || args[4] != null || !(args[5] instanceof IBinder) || (args[6] != null && !(args[6] instanceof String))
                || !(args[7] instanceof Integer) || (Integer) args[7] < 0 || (Integer) args[7] > 65535
                || !Integer.valueOf(0).equals(args[8]) || !Integer.valueOf(0).equals(args[9]) || args[10] != null) throw denied();
    }

    private static void expire() {
        long now = SystemClock.elapsedRealtime();
        Iterator<Map.Entry<IBinder, Route>> entries = ROUTES.entrySet().iterator();
        while (entries.hasNext()) {
            Map.Entry<IBinder, Route> entry = entries.next();
            if (now - entry.getValue().created > LIFETIME_MS || !entry.getKey().isBinderAlive()) entries.remove();
        }
    }

    private static SecurityException denied() { return new SecurityException("Private Google sign-in result route unavailable"); }

    private static SecurityException blocked(String stage, Exception failure) {
        Throwable kind = failure;
        if (failure instanceof java.lang.reflect.InvocationTargetException && failure.getCause() != null)
            kind = failure.getCause();
        // Fixed stage and class only: no request extras, messages, accounts, or token values.
        Log.w("CageDemo", "Private Google pending blocked at " + stage + ": " + kind.getClass().getSimpleName());
        return denied();
    }
}

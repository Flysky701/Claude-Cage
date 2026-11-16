import com.sun.jdi.*;
import com.sun.jdi.connect.*;
import com.sun.jdi.event.*;
import com.sun.jdi.request.*;
import java.util.*;

/** Read-only, bounded observation of DroidGuard's Java/JNI-facing calls.
 * Emits allowlisted key names and path categories, never signal values, file
 * contents, account data, key aliases, certificates, or request/response bytes.
 * Native direct syscalls are outside this trace. Debugger runs are diagnostic,
 * never integrity acceptance evidence. No target method is invoked or changed.
 */
public final class SignalTrace {
    private static final String DG = "com.google.ccc.abuse.droidguard.";
    private static final Set<String> PACKAGES = Set.of("com.google.android.gms", "com.android.vending",
            "com.android.vending.mgc", "com.google.android.gsf", "io.github.flysky701.integritytest",
            "io.github.flysky701.cage.open", "com.cage.android", "android");
    private static final Set<String> SERVICES = Set.of("package", "activity", "account", "connectivity",
            "phone", "wifi", "SurfaceFlinger", "thermalservice", "android.security.keystore2",
            "sensorservice", "power", "battery", "window", "display", "user", "device_identifiers");
    private static final Map<String, Set<String>> TARGETS = new LinkedHashMap<>();
    static {
        TARGETS.put("android.os.SystemProperties", Set.of("get", "getInt", "getLong", "getBoolean", "find"));
        TARGETS.put("java.lang.System", Set.of("getProperty", "getenv"));
        TARGETS.put("android.app.ApplicationPackageManager", Set.of("getPackageInfo", "getApplicationInfo",
                "getPackagesForUid", "getNameForUid", "getInstallerPackageName", "getInstallSourceInfo",
                "hasSystemFeature", "getInstalledPackages", "getInstalledApplications", "checkSignatures"));
        TARGETS.put("android.provider.Settings$Secure", Set.of("getString", "getStringForUser", "getInt"));
        TARGETS.put("android.provider.Settings$Global", Set.of("getString", "getStringForUser", "getInt"));
        TARGETS.put("android.os.ServiceManager", Set.of("getService", "checkService", "listServices"));
        TARGETS.put("android.os.Build", Set.of("getSerial", "getRadioVersion", "getFingerprintedPartitions"));
        TARGETS.put("android.net.ConnectivityManager", Set.of("getActiveNetwork", "getActiveNetworkInfo",
                "getNetworkCapabilities", "getAllNetworks", "getLinkProperties"));
        TARGETS.put("android.telephony.TelephonyManager", Set.of("getDeviceId", "getImei", "getMeid",
                "getSubscriberId", "getSimOperator", "getNetworkOperator", "getPhoneType", "getSimState"));
        TARGETS.put("java.net.NetworkInterface", Set.of("getNetworkInterfaces", "getByName", "getInetAddresses"));
        TARGETS.put("libcore.io.Linux", Set.of("open", "access", "stat", "lstat", "readlink", "uname"));
        TARGETS.put("libcore.io.BlockGuardOs", TARGETS.get("libcore.io.Linux"));
        TARGETS.put("libcore.io.ForwardingOs", TARGETS.get("libcore.io.Linux"));
        TARGETS.put("java.security.KeyStore", Set.of("getInstance", "load", "size", "aliases",
                "containsAlias", "getCertificateChain", "getCertificate", "getKey", "deleteEntry"));
        TARGETS.put("java.security.KeyPairGenerator", Set.of("getInstance", "initialize", "generateKeyPair"));
        TARGETS.put("org.microg.gms.droidguard.core.HardwareAttestationBlockingKeyStore",
                Set.of("engineGetCertificateChain", "engineGetCertificate"));
        TARGETS.put("com.google.ccc.abuse.droidguard.DroidGuard", Set.of("init", "initNative", "ss", "run", "rb", "close"));
        TARGETS.put("org.microg.gms.droidguard.core.DroidGuardHandleImpl", Set.of("initWithRequest", "snapshot", "close"));
        TARGETS.put("org.microg.gms.droidguard.core.FallbackCreator", Set.of("create"));
        TARGETS.put("org.microg.gms.droidguard.HandleProxy", Set.of("init", "run", "close"));
    }

    private static String pathCategory(String path) {
        if (path.matches("/proc/(self|[0-9]+)/(maps|status|mounts|mountinfo|cmdline|stat|task/.*)"))
            return path.replaceFirst("/proc/[0-9]+/", "/proc/<pid>/").replaceFirst("/task/.*", "/task/<entry>");
        if (Set.of("/proc/cpuinfo", "/proc/meminfo", "/proc/version", "/proc/uptime", "/proc/net/route",
                "/proc/net/unix", "/proc/net/tcp", "/sys/fs/selinux/enforce").contains(path)) return path;
        if (path.contains("/blackbox/")) return "<blackbox-private-path>";
        if (path.contains("/app_cache_dg/") || path.contains("/cache_dg/")) return "<droidguard-cache>";
        if (path.startsWith("/data/app/")) return "<installed-apk-path>";
        if (path.startsWith("/data/user/") || path.startsWith("/data/data/")) return "<app-private-path>";
        if (path.startsWith("/system/") || path.startsWith("/apex/") || path.startsWith("/vendor/")) return "<system-path>";
        if (path.startsWith("/proc/")) return "<other-proc-path>";
        if (path.startsWith("/sys/")) return "<other-sys-path>";
        return "<other-path>";
    }

    private static String detail(Method method, StackFrame frame) {
        String owner = method.declaringType().name(), name = method.name();
        // Do not even fetch arguments for key operations or VM lifecycle calls.
        if (!(owner.equals("android.os.SystemProperties") || owner.equals("java.lang.System")
                || owner.equals("android.app.ApplicationPackageManager") || owner.startsWith("android.provider.Settings$")
                || owner.equals("android.os.ServiceManager") || owner.startsWith("libcore.io."))) return "";
        try {
            for (Value arg : frame.getArgumentValues()) {
                if (!(arg instanceof StringReference)) continue;
                String s = ((StringReference) arg).value();
                if (owner.startsWith("libcore.io.")) return " path=" + pathCategory(s);
                if (owner.equals("android.app.ApplicationPackageManager"))
                    return " query=" + (PACKAGES.contains(s) ? s : s.startsWith("android.hardware.")
                            && s.matches("[a-zA-Z0-9._]{1,100}") ? s : "<other-package-or-feature>");
                if (owner.equals("android.os.ServiceManager")) return " service=" + (SERVICES.contains(s) ? s : "<other-service>");
                if (owner.startsWith("android.provider.Settings$")) return " key=" +
                        (Set.of("android_id", "adb_enabled", "development_settings_enabled", "device_provisioned",
                                "mock_location", "install_non_market_apps", "auto_time", "auto_time_zone").contains(s) ? s : "<other-setting>");
                if (owner.equals("android.os.SystemProperties")) return " key=" +
                        (s.matches("(?:ro|persist|sys|init\\.svc|gsm)\\.[a-zA-Z0-9._-]{1,100}") ? s : "<other-property>");
                if (owner.equals("java.lang.System")) return " key=" +
                        (s.matches("(?:java|os|http)\\.[a-zA-Z0-9._-]{1,100}") ? s : "<other-property-or-env>");
            }
        } catch (RuntimeException unavailable) { return " detail=<" + unavailable.getClass().getSimpleName() + ">"; }
        return "";
    }

    public static void main(String[] args) throws Exception {
        AttachingConnector connector = Bootstrap.virtualMachineManager().attachingConnectors().stream()
                .filter(c -> c.name().endsWith("SocketAttach")).findFirst().orElseThrow();
        Map<String, Connector.Argument> config = connector.defaultArguments();
        config.get("hostname").setValue("127.0.0.1");
        config.get("port").setValue(args[0]);
        VirtualMachine vm = connector.attach(config);
        Map<String, Integer> counts = new TreeMap<>();
        Set<String> shown = new HashSet<>();
        int ignored = 0;
        try {
            for (String type : TARGETS.keySet()) {
                MethodEntryRequest request = vm.eventRequestManager().createMethodEntryRequest();
                request.addClassFilter(type);
                request.setSuspendPolicy(EventRequest.SUSPEND_EVENT_THREAD);
                request.enable();
            }
            for (String type : new String[]{"java.security.NoSuchAlgorithmException", "java.lang.UnsupportedOperationException",
                    "java.lang.SecurityException", "android.system.ErrnoException", "java.lang.IllegalArgumentException"}) {
                for (ReferenceType loaded : vm.classesByName(type)) {
                    ExceptionRequest request = vm.eventRequestManager().createExceptionRequest(loaded, true, true);
                    request.setSuspendPolicy(EventRequest.SUSPEND_EVENT_THREAD);
                    request.enable();
                }
            }
            if (vm.canGetMethodReturnValues()) {
                MethodExitRequest request = vm.eventRequestManager().createMethodExitRequest();
                request.addClassFilter(DG + "DroidGuard");
                request.setSuspendPolicy(EventRequest.SUSPEND_EVENT_THREAD);
                request.enable();
            }
            System.out.println("READY: Java/JNI calls only; names/categories only; diagnostic, not acceptance");
            System.out.flush();
            long deadline = System.currentTimeMillis() + 45000;
            while (System.currentTimeMillis() < deadline) {
                EventSet events = vm.eventQueue().remove(500);
                if (events == null) continue;
                try {
                    for (Event event : events) {
                        ThreadReference thread;
                        String key;
                        Method method = null;
                        boolean lifecycle = false;
                        if (event instanceof MethodEntryEvent) {
                            MethodEntryEvent entry = (MethodEntryEvent) event;
                            method = entry.method();
                            if (!TARGETS.getOrDefault(method.declaringType().name(), Set.of()).contains(method.name())) continue;
                            thread = entry.thread();
                            key = method.declaringType().name() + "." + method.name();
                            lifecycle = method.declaringType().name().startsWith("org.microg.gms.droidguard.");
                        } else if (event instanceof MethodExitEvent) {
                            MethodExitEvent entry = (MethodExitEvent) event;
                            String name = entry.method().name();
                            if (!Set.of("init", "ss", "run", "rb").contains(name)) continue;
                            thread = entry.thread();
                            key = "RETURN " + entry.method().declaringType().name() + "." + name;
                            Value returned = entry.returnValue();
                            if (name.equals("init") && returned instanceof BooleanValue)
                                key += " success=" + ((BooleanValue) returned).value();
                            else if ((name.equals("ss") || name.equals("run")) && returned instanceof ArrayReference)
                                key += " arrayLength=" + ((ArrayReference) returned).length();
                            else key += " nonNull=" + (returned != null);
                            lifecycle = true;
                        } else if (event instanceof ExceptionEvent) {
                            ExceptionEvent entry = (ExceptionEvent) event;
                            thread = entry.thread();
                            key = "throws " + entry.exception().referenceType().name() + " at "
                                    + entry.location().declaringType().name() + "." + entry.location().method().name();
                        } else continue;
                        List<StackFrame> frames = thread.frames(0, Math.min(24, thread.frameCount()));
                        boolean fromVm = frames.stream().anyMatch(f -> f.location().declaringType().name().startsWith(DG));
                        if (!fromVm && !lifecycle) { ignored++; continue; }
                        if (method != null) key += detail(method, frames.get(0));
                        counts.merge(key, 1, Integer::sum);
                        if (shown.add(key)) {
                            System.out.println(key);
                            for (StackFrame frame : frames.subList(0, Math.min(frames.size(), 6))) {
                                Location location = frame.location();
                                System.out.println("  at " + location.declaringType().name() + "." + location.method().name());
                            }
                            System.out.flush();
                        }
                    }
                } finally { events.resume(); }
            }
            counts.forEach((key, count) -> System.out.println("COUNT " + key + "=" + count));
            System.out.println("Ignored events without a DroidGuard VM frame=" + ignored);
        } finally { vm.dispose(); }
    }
}

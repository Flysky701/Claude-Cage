import com.sun.jdi.*;
import com.sun.jdi.connect.*;
import com.sun.jdi.event.*;
import com.sun.jdi.request.*;
import java.util.*;

/** Short, read-only JDWP call trace. Never reads key aliases, parameters or return values.
 * Debugger-attached requests are diagnostic only, not acceptance evidence.
 */
public final class KeystoreTrace {
    public static void main(String[] args) throws Exception {
        AttachingConnector connector = Bootstrap.virtualMachineManager().attachingConnectors().stream()
                .filter(c -> c.name().endsWith("SocketAttach")).findFirst().orElseThrow();
        Map<String, Connector.Argument> config = connector.defaultArguments();
        config.get("hostname").setValue("127.0.0.1");
        config.get("port").setValue(args[0]);
        VirtualMachine vm = connector.attach(config);
        Map<String, Integer> counts = new TreeMap<>();
        Set<String> shown = new HashSet<>();
        try {
            for (String name : new String[]{
                    "org.microg.gms.droidguard.core.HardwareAttestationBlockingProvider",
                    "org.microg.gms.droidguard.core.HardwareAttestationBlockingKeyStore"}) {
                for (ReferenceType type : vm.classesByName(name)) {
                    for (String fieldName : new String[]{"currentlyEnabled", "realSpi", "originalProvider"}) {
                        Field field = type.fieldByName(fieldName);
                        if (field == null || !field.isStatic()) continue;
                        Value value = type.getValue(field);
                        System.out.println(name + "." + fieldName + "=" +
                                (value instanceof ObjectReference ? ((ObjectReference) value).referenceType().name() : value));
                    }
                }
            }
            for (String name : new String[]{"java.security.KeyPairGenerator", "java.security.KeyStore",
                    "android.security.keystore2.AndroidKeyStoreKeyPairGeneratorSpi",
                    "android.security.keystore2.AndroidKeyStoreSpi",
                    "org.microg.gms.droidguard.core.HardwareAttestationBlockingKeyStore"}) {
                MethodEntryRequest request = vm.eventRequestManager().createMethodEntryRequest();
                request.addClassFilter(name);
                request.setSuspendPolicy(EventRequest.SUSPEND_EVENT_THREAD);
                request.enable();
            }
            for (ReferenceType type : vm.classesByName("java.security.NoSuchAlgorithmException")) {
                ExceptionRequest request = vm.eventRequestManager().createExceptionRequest(type, true, true);
                request.setSuspendPolicy(EventRequest.SUSPEND_EVENT_THREAD);
                request.enable();
            }
            System.out.println("READY");
            System.out.flush();
            long deadline = System.currentTimeMillis() + 40000;
            while (System.currentTimeMillis() < deadline) {
                EventSet events = vm.eventQueue().remove(1000);
                if (events == null) continue;
                try {
                    for (Event event : events) {
                        String key;
                        ThreadReference thread;
                        if (event instanceof MethodEntryEvent) {
                            MethodEntryEvent entry = (MethodEntryEvent) event;
                            key = entry.method().declaringType().name() + "." + entry.method().name();
                            thread = entry.thread();
                        } else if (event instanceof ExceptionEvent) {
                            ExceptionEvent entry = (ExceptionEvent) event;
                            key = "throws " + entry.exception().referenceType().name();
                            thread = entry.thread();
                        } else continue;
                        counts.merge(key, 1, Integer::sum);
                        if (shown.add(key)) {
                            System.out.println(key);
                            for (StackFrame frame : thread.frames(0, Math.min(6, thread.frameCount()))) {
                                Location location = frame.location();
                                System.out.println("  at " + location.declaringType().name() + "." + location.method().name());
                            }
                            System.out.flush();
                        }
                    }
                } finally { events.resume(); }
            }
            counts.forEach((key, count) -> System.out.println("COUNT " + key + "=" + count));
        } finally { vm.dispose(); }
    }
}

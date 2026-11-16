import com.sun.jdi.*;
import com.sun.jdi.connect.*;
import java.util.*;

/** Compare loaded profile fields without printing device identifiers or changing them. */
public final class ProfileAudit {
    private static Value field(ReferenceType type, String name) {
        Field field = type.fieldByName(name);
        return field == null ? null : type.getValue(field);
    }
    private static Object content(Value value) {
        return value instanceof StringReference ? ((StringReference) value).value() : value;
    }
    public static void main(String[] args) throws Exception {
        AttachingConnector connector = Bootstrap.virtualMachineManager().attachingConnectors().stream()
                .filter(c -> c.name().endsWith("SocketAttach")).findFirst().orElseThrow();
        Map<String, Connector.Argument> config = connector.defaultArguments();
        config.get("hostname").setValue("127.0.0.1");
        config.get("port").setValue(args[0]);
        VirtualMachine vm = connector.attach(config);
        try {
            for (ReferenceType manager : vm.classesByName("org.microg.gms.profile.ProfileManager")) {
                Object active = content(field(manager, "activeProfile"));
                System.out.println("activeProfile=" + (active instanceof String && Set.of("native", "real", "auto", "remote", "user", "system").contains(active) ? active : "other-or-uninitialized"));
            }
            List<ReferenceType> profiles = vm.classesByName("org.microg.gms.profile.Build");
            List<ReferenceType> actuals = vm.classesByName("android.os.Build");
            System.out.println("profileBuildLoaded=" + !profiles.isEmpty());
            if (!profiles.isEmpty() && !actuals.isEmpty()) for (String name : new String[]{
                    "MANUFACTURER", "MODEL", "FINGERPRINT", "BRAND", "PRODUCT", "DEVICE", "ID",
                    "HARDWARE", "BOARD", "BOOTLOADER", "CPU_ABI", "CPU_ABI2", "DISPLAY", "HOST",
                    "RADIO", "SERIAL", "TAGS", "TYPE", "USER"}) {
                Value profile = field(profiles.get(0), name), actual = field(actuals.get(0), name);
                System.out.println(name + "=" + (profile == null || actual == null ? "missing" :
                        Objects.equals(content(profile), content(actual)) ? "same" : "different"));
            }
        } finally { vm.dispose(); }
    }
}

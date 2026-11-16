import com.sun.jdi.*;
import com.sun.jdi.connect.*;
import java.util.*;

/** Read-only object observer for original Claude 1.261113.19 / 26111319.
 * Version-specific names. Does not invoke methods, change state, install event
 * requests, or print credentials, tokens, response bodies or account identifiers.
 * Debugger runs are diagnostic, not Play Integrity acceptance evidence.
 */
public final class LoginTrace {
    private static Value field(Value value, String name) {
        if (!(value instanceof ObjectReference)) return null;
        ObjectReference object = (ObjectReference) value;
        Field f = object.referenceType().fieldByName(name);
        return f == null ? null : object.getValue(f);
    }
    private static String present(Value value) {
        if (value instanceof StringReference) {
            int length = ((StringReference) value).value().length();
            return "present=" + (length > 0) + " length=" + length;
        }
        return "present=" + (value != null);
    }
    private static String category(Value value) {
        Value name = field(value, "name");
        if (name instanceof StringReference) {
            String text = ((StringReference) name).value();
            if (text.matches("[A-Z_]{1,60}")) return text;
        }
        return value == null ? "none" : "<unclassified>";
    }
    private static void request(ObjectReference object) {
        System.out.println("LOGIN Google credential " + present(field(object, "a")));
        System.out.println("LOGIN Recaptcha " + present(field(object, "d")));
        System.out.println("LOGIN Classic integrity " + present(field(object, "f")));
        Value attestation = field(object, "g");
        System.out.println("LOGIN Client attestation " + present(attestation));
        if (attestation != null) {
            System.out.println("LOGIN Client integrity " + present(field(attestation, "a")));
            System.out.println("LOGIN Client mint error=" + category(field(attestation, "b")));
        }
    }
    private static String number(Value value) {
        if (value instanceof LongValue) return Long.toString(((LongValue) value).value());
        if (value instanceof IntegerValue) return Integer.toString(((IntegerValue) value).value());
        Value boxed = field(value, "value");
        return boxed instanceof PrimitiveValue ? number(boxed) : "none";
    }
    private static String outcome(Value value) {
        if (!(value instanceof ObjectReference)) return "none";
        String type = ((ObjectReference) value).referenceType().name();
        if (type.equals("ixt")) return "MINTED";
        if (type.equals("hxt")) return category(field(value, "a"));
        return "<other>";
    }
    private static String statusText(Value value) {
        if (!(value instanceof StringReference)) return "none";
        String text = ((StringReference) value).value();
        // These fields are statically verified telemetry outcomes, not free text.
        return text.matches("[a-z_]{1,64}") ? text : "<other>";
    }
    private static void branch(ObjectReference object) {
        Value legacy = field(object, "b"), challenge = field(object, "c");
        System.out.println("BRANCH legacy=" + outcome(field(legacy, "a"))
                + " legacyMintMs=" + number(field(legacy, "b")));
        System.out.println("BRANCH challengeAttempted=" + (challenge != null));
        if (challenge != null) {
            System.out.println("BRANCH challenge=" + outcome(field(challenge, "a"))
                    + " mintMs=" + number(field(challenge, "b"))
                    + " waitedMs=" + number(field(challenge, "c"))
                    + " firstError=" + category(field(challenge, "d")));
        }
    }
    private static void telemetry(ObjectReference object) {
        System.out.println("TELEMETRY legacy=" + statusText(field(object, "b"))
                + " challenge=" + statusText(field(object, "m"))
                + " challengeMintMs=" + number(field(object, "n"))
                + " challengeWaitedMs=" + number(field(object, "o"))
                + " challengeFirstError=" + statusText(field(object, "p")));
    }
    private static void error(ObjectReference object) {
        System.out.println("SERVER enum=" + category(field(object, "a")));
        Value code = field(object, "f");
        if (code instanceof StringReference) {
            String text = ((StringReference) code).value();
            if (text.matches("[a-z_]{1,64}")) System.out.println("SERVER code=" + text);
        }
        Value message = field(object, "b");
        if (message instanceof StringReference) {
            String text = ((StringReference) message).value().toLowerCase(Locale.ROOT);
            System.out.println("SERVER mentionsPlay=" + text.contains("play")
                    + " mentionsIntegrity=" + text.contains("integrity")
                    + " mentionsDevice=" + text.contains("device"));
        }
    }
    public static void main(String[] args) throws Exception {
        AttachingConnector connector = Bootstrap.virtualMachineManager().attachingConnectors().stream()
                .filter(c -> c.name().endsWith("SocketAttach")).findFirst().orElseThrow();
        Map<String, Connector.Argument> config = connector.defaultArguments();
        config.get("hostname").setValue("127.0.0.1");
        config.get("port").setValue(args[0]);
        VirtualMachine vm = connector.attach(config);
        boolean poll = args.length > 1 && args[1].equals("poll");
        try {
            System.out.println("READY read-only objects; mode=" + (poll ? "poll" : "snapshot"));
            System.out.flush();
            long deadline = System.currentTimeMillis() + (poll ? 45000 : 0);
            Set<Long> seen = new HashSet<>();
            boolean seenRequest = false, seenBranch = false;
            do {
                for (String name : List.of("ps3", "lir", "ipg0", "com.anthropic.claude.api.errors.ClaudeApiError$InvalidRequestError")) {
                    for (ReferenceType type : vm.classesByName(name)) {
                        for (ObjectReference object : type.instances(12)) {
                            if (!seen.add(object.uniqueID())) continue;
                            try {
                                if (name.equals("ps3")) { branch(object); seenBranch = true; }
                                else if (name.equals("lir")) telemetry(object);
                                else if (name.equals("ipg0")) { request(object); seenRequest = true; }
                                else error(object);
                            } catch (ObjectCollectedException collected) {
                                System.out.println("Object collected; no state modified");
                            }
                        }
                    }
                }
                System.out.flush();
                if (!poll) return;
                Thread.sleep(200);
            } while (System.currentTimeMillis() < deadline);
            System.out.println("Observation window ended; requestObserved=" + seenRequest
                    + " branchObserved=" + seenBranch);
        } finally { vm.dispose(); }
    }
}

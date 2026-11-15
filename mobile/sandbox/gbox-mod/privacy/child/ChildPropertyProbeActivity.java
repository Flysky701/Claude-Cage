package io.github.leexeo.cage.childprobe;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.widget.TextView;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.FutureTask;
import java.util.concurrent.TimeUnit;
import org.json.JSONObject;

/** No permissions, accounts or network. All policy environment is child-only. */
public final class ChildPropertyProbeActivity extends Activity {
    private static final String TAG = "CageChildProbe";
    private static final String PREFIX = "CAGE_CHILD ";
    private static final String PACKAGE = "io.github.leexeo.cage.childprobe";
    private static final String[] ENV_KEYS = {"LD_PRELOAD", "CAGE_CHILD_SCOPE", "CAGE_CHILD_POLICY",
        "CAGE_CHILD_SIM", "CAGE_CHILD_TIMEZONE", "CAGE_CHILD_ZONE", "CAGE_CHILD_DIAGNOSTIC", "TZ"};
    private static final String[] CAPACITY = {"persist.radio.multisim.config", "telephony.active_modems.max_count"};
    private static final String[] APIS = {"get", "read", "callback"};
    private static final Map<String, String> EXPECTED = new LinkedHashMap<>();
    static {
        EXPECTED.put("gsm.sim.state", "ABSENT");
        EXPECTED.put("gsm.sim.operator.alpha", "");
        EXPECTED.put("gsm.sim.operator.numeric", "");
        EXPECTED.put("gsm.sim.operator.iso-country", "");
        EXPECTED.put("gsm.operator.alpha", "");
        EXPECTED.put("gsm.operator.numeric", "");
        EXPECTED.put("gsm.operator.iso-country", "");
        EXPECTED.put("gsm.operator.isroaming", "false");
        EXPECTED.put("gsm.current.phone-type", "0");
        EXPECTED.put("persist.sys.timezone", "Asia/Tokyo");
    }

    @Override public void onCreate(Bundle saved) {
        super.onCreate(saved);
        TextView label = new TextView(this);
        label.setText("Checking child property inheritance. No account access.");
        setContentView(label);
        new Thread(() -> runProbe(label), "child-property-probe").start();
    }

    private static String hex(String value) {
        StringBuilder result = new StringBuilder();
        for (byte b : value.getBytes(StandardCharsets.UTF_8)) result.append(String.format(java.util.Locale.ROOT, "%02x", b & 255));
        return result.toString();
    }

    private File asset(String name, boolean executable) throws Exception {
        File directory = new File(getFilesDir(), "child-policy");
        if (!directory.isDirectory() && !directory.mkdirs()) throw new java.io.IOException("mkdir");
        File target = new File(directory, name);
        try (InputStream in = getAssets().open("cage-child/x86_64/" + name);
             FileOutputStream out = new FileOutputStream(target)) {
            byte[] block = new byte[8192];
            for (int n; (n = in.read(block)) != -1;) out.write(block, 0, n);
        }
        if (!target.setReadable(true, true) || (executable && !target.setExecutable(true, true))) throw new java.io.IOException("mode");
        return target;
    }

    private static int elfMachine(File file) {
        try (InputStream in = new FileInputStream(file)) {
            byte[] header = new byte[20];
            int done = 0;
            while (done < header.length) { int n = in.read(header, done, header.length - done); if (n < 0) return 0; done += n; }
            if (header[0] != 127 || header[1] != 'E' || header[2] != 'L' || header[3] != 'F' || header[5] != 1) return 0;
            return (header[18] & 255) | (header[19] & 255) << 8;
        } catch (Exception ignored) { return 0; }
    }

    private static byte[] readBounded(InputStream input) throws Exception {
        try (InputStream in = input; ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            byte[] data = new byte[2048];
            for (int n; (n = in.read(data)) != -1;) {
                if (out.size() + n > 65536) throw new java.io.IOException("bounded-output");
                out.write(data, 0, n);
            }
            return out.toByteArray();
        }
    }

    private static final class Result {
        int exit;
        String stdout, stderr;
        Map<String, String> values = new HashMap<>();
        Map<String, String> fields = new HashMap<>();
        boolean lengths = true;
        boolean loaded() { return stderr.contains(PREFIX + "loaded=1 mainElf=62 "); }
        boolean enabled() { return loaded() && stderr.contains(" enabled=1 "); }
    }

    private static Result launch(Map<String, String> environment, String... command) throws Exception {
        ProcessBuilder builder = new ProcessBuilder(command);
        builder.environment().clear();
        builder.environment().putAll(environment);
        Process process = builder.start();
        FutureTask<byte[]> stdout = new FutureTask<>(() -> readBounded(process.getInputStream()));
        FutureTask<byte[]> stderr = new FutureTask<>(() -> readBounded(process.getErrorStream()));
        Thread a = new Thread(stdout, "child-stdout"), b = new Thread(stderr, "child-stderr");
        a.setDaemon(true); b.setDaemon(true); a.start(); b.start();
        try {
            if (!process.waitFor(15, TimeUnit.SECONDS)) throw new java.io.IOException("child-timeout");
            Result result = new Result();
            result.exit = process.exitValue();
            result.stdout = new String(stdout.get(3, TimeUnit.SECONDS), StandardCharsets.UTF_8).trim();
            result.stderr = new String(stderr.get(3, TimeUnit.SECONDS), StandardCharsets.UTF_8);
            for (String line : result.stdout.split("\\r?\\n")) {
                if (line.startsWith("value|")) {
                    String[] pieces = line.split("\\|", -1);
                    if (pieces.length != 5) throw new java.io.IOException("reader-format");
                    result.values.put(pieces[1] + "|" + pieces[2], pieces[4]);
                    result.lengths &= Integer.parseInt(pieces[3]) * 2 == pieces[4].length();
                } else if (line.contains("=")) {
                    int split = line.indexOf('='); result.fields.put(line.substring(0, split), line.substring(split + 1));
                }
            }
            return result;
        } finally { process.destroy(); }
    }

    private static String prepend(String added, String original) {
        return original == null || original.isEmpty() ? added : added + " " + original;
    }

    private static JSONObject readerResult(Result result, Result baseline, boolean active) throws Exception {
        JSONObject report = new JSONObject();
        report.put("exitZero", result.exit == 0);
        report.put("actualMainElf", result.fields.get("mainElf"));
        report.put("policyLoaded", result.loaded());
        report.put("policyEnabled", result.enabled());
        report.put("policyState", result.fields.get("policyState"));
        report.put("existingPreloadPreserved", "true".equals(result.fields.get("existingPreload")));
        report.put("returnLengthsMatch", result.lengths);
        JSONObject apiResults = new JSONObject();
        for (String api : APIS) {
            int checked = 0, missing = 0;
            boolean equal = true;
            for (Map.Entry<String, String> item : EXPECTED.entrySet()) {
                String key = api + "|" + item.getKey();
                if (!result.values.containsKey(key)) { missing++; continue; }
                checked++;
                equal &= result.values.get(key).equals(active ? hex(item.getValue()) : baseline.values.get(key));
            }
            apiResults.put(api, new JSONObject().put("checked", checked).put("missingProperties", missing).put("expected", checked > 0 && equal));
        }
        report.put("api", apiResults);
        JSONObject capacity = new JSONObject();
        for (String key : CAPACITY) {
            boolean preserved = true;
            for (String api : APIS) preserved &= java.util.Objects.equals(result.values.get(api + "|" + key), baseline.values.get(api + "|" + key));
            capacity.put(key, preserved);
        }
        report.put("capacityPreserved", capacity);
        report.put("unrelatedPropertyPreserved", java.util.Objects.equals(result.values.get("get|ro.build.version.sdk"), baseline.values.get("get|ro.build.version.sdk")));
        report.put("allValuesEqualBaseline", result.values.equals(baseline.values));
        return report;
    }

    private void runProbe(TextView label) {
        JSONObject report = new JSONObject();
        String stage = "extract";
        try {
            report.put("version", 1).put("scope", "own ProcessBuilder children only").put("noAccountsOrNetwork", true);
            Map<String, String> before = new HashMap<>(System.getenv());
            File library = asset("libcage_child_properties.so", false);
            File sentinel = asset("libcage_existing_preload.so", false);
            File reader = asset("cage_property_reader", true);
            JSONObject executables = new JSONObject();
            executables.put("reader", elfMachine(reader));
            executables.put("getprop", elfMachine(new File("/system/bin/getprop")));
            executables.put("date", elfMachine(new File("/system/bin/date")));
            report.put("executableElfMachines", executables);
            Map<String, String> base = new HashMap<>(before);
            for (String key : ENV_KEYS) if (!key.equals("LD_PRELOAD") && !key.equals("TZ")) base.remove(key);
            base.put("LD_PRELOAD", prepend(sentinel.getAbsolutePath(), before.get("LD_PRELOAD")));
            stage = "reader.baseline";
            Result baseline = launch(base, reader.getAbsolutePath());
            report.put("baseline", readerResult(baseline, baseline, false));
            boolean simSignal = false;
            for (String key : Arrays.asList("gsm.sim.operator.alpha", "gsm.sim.operator.numeric", "gsm.sim.operator.iso-country", "gsm.operator.alpha", "gsm.operator.numeric", "gsm.operator.iso-country")) {
                String value = baseline.values.get("get|" + key); simSignal |= value != null && !value.isEmpty();
            }
            report.put("baselineHasRealOperatorSignal", simSignal);
            Map<String, String> active = new HashMap<>(base);
            active.put("LD_PRELOAD", prepend(library.getAbsolutePath(), base.get("LD_PRELOAD")));
            active.put("CAGE_CHILD_SCOPE", PACKAGE); active.put("CAGE_CHILD_POLICY", "1");
            active.put("CAGE_CHILD_SIM", "1"); active.put("CAGE_CHILD_TIMEZONE", "1");
            active.put("CAGE_CHILD_ZONE", "Asia/Tokyo"); active.put("CAGE_CHILD_DIAGNOSTIC", "1");
            active.put("TZ", "Asia/Tokyo");
            stage = "reader.active";
            Result enabled = launch(active, reader.getAbsolutePath());
            report.put("enabled", readerResult(enabled, baseline, true));
            stage = "reader.unselected";
            Map<String, String> unselected = new HashMap<>(active);
            unselected.put("CAGE_CHILD_SCOPE", "unselected.test");
            report.put("unselected", readerResult(launch(unselected, reader.getAbsolutePath()), baseline, false));
            stage = "reader.deactivated";
            Map<String, String> deactivated = new HashMap<>(active);
            deactivated.put("CAGE_CHILD_POLICY", "0");
            report.put("deactivated", readerResult(launch(deactivated, reader.getAbsolutePath()), baseline, false));
            stage = "system.getprop";
            JSONObject system = new JSONObject();
            for (Map.Entry<String, String> item : EXPECTED.entrySet()) {
                Result raw = launch(base, "/system/bin/getprop", item.getKey());
                Result changed = launch(active, "/system/bin/getprop", item.getKey());
                system.put(item.getKey(), new JSONObject().put("exitZero", changed.exit == 0)
                    .put("loaded", changed.loaded()).put("enabled", changed.enabled())
                    .put("expected", changed.stdout.equals(item.getValue())).put("baselineDifferent", !raw.stdout.equals(item.getValue())));
            }
            for (String key : CAPACITY) {
                Result raw = launch(base, "/system/bin/getprop", key), changed = launch(active, "/system/bin/getprop", key);
                system.put(key, new JSONObject().put("exitZero", changed.exit == 0).put("loaded", changed.loaded()).put("preserved", raw.stdout.equals(changed.stdout)));
            }
            report.put("systemGetprop", system);
            stage = "system.date";
            Result date = launch(active, "/system/bin/date", "+%z");
            report.put("systemDate", new JSONObject().put("exitZero", date.exit == 0).put("loaded", date.loaded())
                .put("enabled", date.enabled()).put("TokyoOffset", "+0900".equals(date.stdout)));
            stage = "restore";
            Result restored = launch(base, reader.getAbsolutePath());
            report.put("restored", readerResult(restored, baseline, false));
            report.put("parentEnvironmentUnchanged", before.equals(new HashMap<>(System.getenv())));
            report.put("completed", true);
        } catch (Throwable failure) {
            try { report.put("completed", false).put("failedStage", stage).put("exception", failure.getClass().getSimpleName()); } catch (Exception ignored) { }
        }
        try {
            String text = report.toString(2);
            try (FileOutputStream out = new FileOutputStream(new File(getFilesDir(), "latest-child-property-report.json"))) { out.write(text.getBytes(StandardCharsets.UTF_8)); }
            Log.i(TAG, "report=" + report.toString());
            runOnUiThread(() -> label.setText("Child property probe completed. Report saved."));
        } catch (Throwable failure) { Log.i(TAG, "reportWriteFailure=" + failure.getClass().getSimpleName()); }
    }
}


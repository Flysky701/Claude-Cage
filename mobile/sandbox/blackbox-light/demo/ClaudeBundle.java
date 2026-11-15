package io.github.leexeo.cage.space;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.Signature;
import android.content.res.AssetManager;
import android.content.res.XmlResourceParser;
import android.net.Uri;
import android.os.Build;
import android.util.AtomicFile;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.channels.FileLock;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.Enumeration;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import org.json.JSONArray;
import org.json.JSONObject;

/** Imports unchanged, platform-verified Claude config APKs into this DEMO's private runtime. */
public final class ClaudeBundle {
    static final String HOST = "top.niunaijun.microdem";
    static final String PACKAGE = "com.anthropic.claude";
    private static final String NS = "http://schemas.android.com/apk/res/android";
    private static final String ABI = "arm64-v8a";
    private static final String ABI_SPLIT = "config.arm64_v8a";
    private static final String OTHER_ABI_SPLIT = "config.armeabi_v7a";
    // Anthropic's Android Digital Asset Links release certificates; every APK must use one current key.
    private static final Set<String> SIGNERS = new HashSet<>(Arrays.asList(
            "305a1e8a432e5ec0c612b2465359c3b88e3c95d6253599ac6088562b818b64a0",
            "ed0b07c55cc0a9a0085e2c7779e6abf85a4c5f1e6b236c940a77fe7b2b1c20cb"));
    private static final Set<String> DENSITIES = new HashSet<>(Arrays.asList(
            "config.ldpi", "config.mdpi", "config.tvdpi", "config.hdpi", "config.xhdpi",
            "config.xxhdpi", "config.xxxhdpi"));
    static final long MAX_ARCHIVE = 256L * 1024 * 1024;
    static final long MAX_APK = 160L * 1024 * 1024;
    private static final long MAX_EXPANDED = 512L * 1024 * 1024;
    static final long MAX_LIBRARY = 64L * 1024 * 1024;
    static final int MAX_APKS = 64;

    private ClaudeBundle() {}

    /** Imports original APKs; upgrades use a recoverable, private-only transaction. */
    public static synchronized String install(Context host, File archive) throws Exception {
        File root = root(host, true);
        requireArm64();
        File lockPath = child(root, "install.lock");
        try (FileOutputStream lockStream = new FileOutputStream(lockPath, true);
             FileLock lock = lockStream.getChannel().tryLock()) {
            if (lock == null) throw new IOException("另一次 Claude 导入仍在进行。");
            String recovered = ClaudeUpgrade.recoverIfNeeded(host);
            if (recovered != null) return recovered;
            if (archive == null || !archive.isFile() || archive.length() <= 0 || archive.length() > MAX_ARCHIVE)
                throw new IOException("Claude 安装包为空或超过 256 MB。");
            File staging = child(root, ".staging-" + UUID.randomUUID());
            if (!staging.mkdir()) throw new IOException("无法创建独立导入目录。");
            try {
                File input = child(staging, "input");
                if (!input.mkdir()) throw new IOException("无法创建校验目录。");
                Selection selection = select(unpack(archive, input));
                SpacePackages packages = new SpacePackages(host);
                PackageInfo current = packages.installed(PACKAGE);
                AtomicFile active = active(root);
                State old = null;
                if (active.getBaseFile().exists() || new File(active.getBaseFile() + ".bak").exists()) {
                    old = readState(host, true);
                    if (current == null || !packages.privateCopy(current)
                            || SpacePackages.version(current) != old.version)
                        throw new IOException("现有 Claude 安装记录不完整，已停止升级并保留数据。");
                    if (same(old, selection))
                        return "Claude " + selection.versionName + " 已完整安装在空间内。";
                    if (selection.version <= old.version || !old.signer.equals(selection.signer))
                        throw new IOException("升级必须使用更高版本且当前官方签名完全相同的 Claude 完整分包。");
                }
                if (old == null && (current != null || privateBase(host).getParentFile().exists()
                        || new File(data(host), "blackbox/data/user/0/" + PACKAGE).exists()
                        || new File(data(host), "blackbox/data/user_de/0/" + PACKAGE).exists())) {
                    Apk selectedBase = selection.apks.get(0);
                    File existingBase = privateBase(host);
                    File prepared = child(root, selection.version + "-" + selectedBase.sha256);
                    boolean emptyAttempt = current == null && !existingBase.exists()
                            && emptyTree(existingBase.getParentFile(), new int[]{0})
                            && emptyTree(new File(data(host), "blackbox/data/user/0/" + PACKAGE), new int[]{0})
                            && emptyTree(new File(data(host), "blackbox/data/user_de/0/" + PACKAGE), new int[]{0});
                    // Resume only an importer's prepared payload with an identical original private base.
                    // The private installer replaces application files, while retaining guest user data.
                    if (!prepared.isDirectory() || (!emptyAttempt && (!existingBase.isFile()
                            || existingBase.length() != selectedBase.size
                            || !selectedBase.sha256.equals(sha(existingBase, MAX_APK))
                            || (current != null && SpacePackages.version(current) != selection.version))))
                        throw new IOException("检测到不同或无法核实的 Claude 安装，已停止覆盖并保留数据。");
                }

                File payload = child(staging, "payload");
                if (!payload.mkdir()) throw new IOException("无法创建安装包目录。");
                State candidate = materialize(selection, payload);
                File committed = child(root, candidate.directory);
                if (committed.exists()) {
                    // A prior pre-install failure may have left this complete immutable payload.
                    candidate.directoryFile = committed;
                    validateStored(candidate, true, null);
                } else {
                    if (!payload.renameTo(committed)) throw new IOException("无法提交已校验的 Claude 文件。");
                    candidate.directoryFile = committed;
                }

                if (old != null) return ClaudeUpgrade.install(host, old, candidate, current.applicationInfo.uid);

                Object core = Class.forName("top.niunaijun.blackbox.BlackBoxCore").getMethod("get").invoke(null);
                Object result = core.getClass().getMethod("installPackageAsUser", Uri.class, int.class)
                        .invoke(core, Uri.fromFile(child(committed, "base.apk")), 0);
                if (result == null || !result.getClass().getField("success").getBoolean(result))
                    throw new IOException("Claude 私有安装未完成；已保留文件和数据，未开放启动。");
                PackageInfo saved = packages.installed(PACKAGE);
                if (saved == null || !PACKAGE.equals(saved.packageName)
                        || SpacePackages.version(saved) != candidate.version)
                    throw new IOException("Claude 私有安装记录未完成；已保留数据，未开放启动。");
                validateStored(candidate, true, privateBase(host));
                publish(active, candidate);
                return "Claude " + selection.versionName + " 已安装在空间内（保留原版签名）。";
            } finally {
                // Only this invocation's exclusive temporary directory is eligible for cleanup.
                removeOwned(staging, staging);
            }
        }
    }

    /** Explicit recovery entry point; never launches a guest or downloads another version. */
    public static synchronized String recoverUpgrade(Context host) throws Exception {
        File root = root(host, false);
        try (FileOutputStream stream = new FileOutputStream(child(root, "install.lock"), true);
             FileLock lock = stream.getChannel().tryLock()) {
            if (lock == null) throw new IOException("另一次 Claude 导入仍在进行。");
            String recovered = ClaudeUpgrade.recoverIfNeeded(host);
            return recovered == null ? "没有待恢复的 Claude 升级。" : recovered;
        }
    }

    private static List<Apk> unpack(File archive, File input) throws Exception {
        List<Apk> apks = new ArrayList<>();
        Set<String> names = new HashSet<>();
        long total = 0;
        int count = 0;
        try (ZipFile zip = new ZipFile(archive)) {
            Enumeration<? extends ZipEntry> entries = zip.entries();
            while (entries.hasMoreElements()) {
                ZipEntry entry = entries.nextElement();
                String name = entry.getName();
                if (++count > 96 || !simple(name) || !names.add(name.toLowerCase(Locale.ROOT))
                        || entry.isDirectory() || entry.getSize() < 0)
                    throw new IOException("安装包包含重复、过多或不安全的文件路径。");
                total += entry.getSize();
                if (total > MAX_EXPANDED) throw new IOException("安装包解压后过大。");
                if (!name.endsWith(".apk")) {
                    if (entry.getSize() > 1024 * 1024) throw new IOException("安装包附加文件过大。");
                    continue; // XAPK descriptions/icons are never executed or used as authority.
                }
                if (apks.size() >= MAX_APKS || entry.getSize() <= 0 || entry.getSize() > MAX_APK)
                    throw new IOException("Claude APK 数量或大小超出限制。");
                File extracted = child(input, name);
                try (InputStream source = zip.getInputStream(entry)) {
                    copyNew(source, extracted, entry.getSize(), MAX_APK);
                }
                readOnly(extracted);
                apks.add(inspect(extracted));
            }
        }
        return apks;
    }

    private static Apk inspect(File file) throws Exception {
        Apk apk = new Apk();
        apk.file = file;
        apk.size = file.length();
        if (apk.size <= 0 || apk.size > MAX_APK) throw new IOException("无效 APK 大小。");
        apk.sha256 = sha(file, MAX_APK);
        apk.signer = verifiedSigner(file);
        readManifest(file, apk);
        if (!PACKAGE.equals(apk.pkg) || apk.version <= 0 || apk.minSdk > Build.VERSION.SDK_INT)
            throw new IOException("请选择适合此手机的原版 Claude 安装包。");
        apk.nativeFiles = inspectContents(apk);
        return apk;
    }

    /** Full v2-or-newer verification, including signed content digests, never certificate extraction alone. */
    static String verifiedSigner(File file) throws Exception {
        Class<?> verifier = Class.forName("android.util.apk.ApkSignatureVerifier");
        Object details;
        Method modern = null;
        Class<?> parseInput = null;
        try {
            parseInput = Class.forName("android.content.pm.parsing.result.ParseInput");
            modern = verifier.getDeclaredMethod("verify", parseInput, String.class, int.class);
        } catch (ClassNotFoundException | NoSuchMethodException oldPlatform) { /* pre-ParseResult API */ }
        try {
            if (modern != null) {
                Class<?> inputType = Class.forName("android.content.pm.parsing.result.ParseTypeImpl");
                Object input = inputType.getMethod("forDefaultParsing").invoke(null);
                input = inputType.getMethod("reset").invoke(input);
                modern.setAccessible(true);
                Object result = modern.invoke(null, input, file.getPath(), 2);
                Class<?> resultType = Class.forName("android.content.pm.parsing.result.ParseResult");
                if (result == null || (Boolean) resultType.getMethod("isError").invoke(result))
                    throw new IOException("Claude APK 完整签名校验未通过。");
                details = resultType.getMethod("getResult").invoke(result);
            } else {
                Method old = verifier.getDeclaredMethod("verify", String.class, int.class);
                old.setAccessible(true);
                details = old.invoke(null, file.getPath(), 2);
            }
        } catch (InvocationTargetException invalid) {
            throw new IOException("Claude APK 完整签名校验未通过。", invalid.getCause());
        }
        if (details == null) throw new IOException("Android 未返回已验证的签名。");
        Signature[] signatures;
        try { signatures = (Signature[]) details.getClass().getMethod("getSignatures").invoke(details); }
        catch (NoSuchMethodException olderPlatform) {
            signatures = (Signature[]) field(details.getClass(), "signatures").get(details);
        }
        if (signatures == null || signatures.length != 1)
            throw new IOException("Claude APK 必须只有一个已验证的当前签名。");
        String signer = hex(MessageDigest.getInstance("SHA-256").digest(signatures[0].toByteArray()));
        if (!SIGNERS.contains(signer)) throw new IOException("Claude APK 不是已知 Anthropic 官方签名。");
        return signer;
    }

    private static void readManifest(File file, Apk apk) throws Exception {
        AssetManager assets = AssetManager.class.getDeclaredConstructor().newInstance();
        try {
            Method add = AssetManager.class.getDeclaredMethod("addAssetPath", String.class);
            add.setAccessible(true);
            int cookie = (Integer) add.invoke(assets, file.getPath());
            if (cookie == 0) throw new IOException("无法读取 Claude APK 清单。");
            try (XmlResourceParser xml = assets.openXmlResourceParser(cookie, "AndroidManifest.xml")) {
                boolean root = false, application = false;
                int tags = 0;
                for (int event; (event = xml.next()) != XmlResourceParser.END_DOCUMENT;) {
                    if (event != XmlResourceParser.START_TAG) continue;
                    if (++tags > 10000) throw new IOException("APK 清单过大。");
                    String tag = xml.getName();
                    int depth = xml.getDepth();
                    if (depth == 1) {
                        if (root || !"manifest".equals(tag)) throw new IOException("无效 APK 清单。");
                        root = true;
                        apk.pkg = xml.getAttributeValue(null, "package");
                        apk.split = value(xml.getAttributeValue(null, "split"));
                        if (!value(xml.getAttributeValue(NS, "sharedUserId")).isEmpty())
                            throw new IOException("此导入器不支持共享身份的 Claude 包。");
                        int low = xml.getAttributeIntValue(NS, "versionCode", 0);
                        int high = xml.getAttributeIntValue(NS, "versionCodeMajor", 0);
                        if (high < 0) throw new IOException("不支持此 APK 版本编码。");
                        apk.version = ((long) high << 32) | (low & 0xffffffffL);
                        apk.versionName = value(xml.getAttributeValue(NS, "versionName"));
                        apk.required = types(xml.getAttributeValue(NS, "requiredSplitTypes"));
                        apk.types = types(xml.getAttributeValue(NS, "splitTypes"));
                        if (xml.getAttributeBooleanValue(NS, "isFeatureSplit", false)
                                || xml.getAttributeBooleanValue(NS, "isolatedSplits", false)
                                || !value(xml.getAttributeValue(null, "configForSplit")).isEmpty()
                                || !value(xml.getAttributeValue(NS, "configForSplit")).isEmpty())
                            throw new IOException("此 DEMO 不支持功能分拆或独立分拆加载。");
                    }
                    if ("uses-split".equals(tag)) throw new IOException("此 DEMO 不支持分拆依赖。");
                    if (depth == 2 && "uses-sdk".equals(tag))
                        apk.minSdk = xml.getAttributeIntValue(NS, "minSdkVersion", 1);
                    if (depth == 2 && "application".equals(tag)) {
                        if (application) throw new IOException("APK 包含重复 application 清单。");
                        application = true;
                        apk.hasCode = xml.getAttributeBooleanValue(NS, "hasCode", true);
                        if (!apk.split.isEmpty() && xml.getAttributeValue(NS, "classLoader") != null)
                            throw new IOException("不支持分拆自定义类加载器。");
                    }
                    if (!apk.split.isEmpty() && ((depth == 2 && !"application".equals(tag) && !"uses-sdk".equals(tag))
                            || (depth >= 3 && !(depth == 3 && "meta-data".equals(tag)))))
                        throw new IOException("此 DEMO 只接受资源或原生库配置分拆。");
                }
                if (!root || !application || (!apk.split.isEmpty() && apk.hasCode))
                    throw new IOException("配置分拆缺少有效清单，或包含可执行代码。");
            }
        } finally { assets.close(); }
    }

    private static Set<String> types(String raw) throws IOException {
        Set<String> result = new HashSet<>();
        if (raw == null || raw.isEmpty()) return result;
        for (String type : raw.split(",", -1)) {
            if (!("base__abi".equals(type) || "base__density".equals(type)) || !result.add(type))
                throw new IOException("安装包包含当前 DEMO 不支持的分拆类型。");
        }
        return result;
    }

    private static List<NativeFile> inspectContents(Apk apk) throws Exception {
        List<NativeFile> libraries = new ArrayList<>();
        Set<String> entries = new HashSet<>();
        long expanded = 0;
        boolean dex = false;
        int count = 0;
        try (ZipFile zip = new ZipFile(apk.file)) {
            Enumeration<? extends ZipEntry> values = zip.entries();
            while (values.hasMoreElements()) {
                ZipEntry item = values.nextElement();
                String name = item.getName();
                if (++count > 30000 || !safeZipPath(name) || !entries.add(name)
                        || item.getSize() < 0 || item.getSize() > MAX_EXPANDED)
                    throw new IOException("APK 文件结构不安全或超出限制。");
                expanded += item.getSize();
                if (expanded > MAX_EXPANDED) throw new IOException("APK 展开后过大。");
                if (item.isDirectory()) continue;
                if (name.endsWith(".dex")) dex = true;
                if (!name.startsWith("lib/")) continue;
                String[] parts = name.split("/", -1);
                boolean arm32 = OTHER_ABI_SPLIT.equals(apk.split);
                if (parts.length != 3 || !(arm32 ? "armeabi-v7a" : ABI).equals(parts[1])
                        || !libraryName(parts[2]) || item.getSize() <= 0 || item.getSize() > MAX_LIBRARY
                        || !(arm32 || ABI_SPLIT.equals(apk.split)))
                    throw new IOException("安装包包含不支持的原生库位置或架构。");
                if (libraries.size() >= 128) throw new IOException("APK 原生库数量过多。");
                NativeFile library = new NativeFile();
                library.name = parts[2];
                library.entry = name;
                library.owner = apk.file;
                library.size = item.getSize();
                try (InputStream source = zip.getInputStream(item)) {
                    library.sha256 = digestNative(source, library.size, arm32);
                }
                libraries.add(library);
            }
        }
        if (!apk.split.isEmpty() && dex) throw new IOException("配置分拆中包含 DEX 代码。");
        if (apk.split.isEmpty() && (!dex || !apk.hasCode)) throw new IOException("Claude 基础 APK 缺少应用代码。");
        return libraries;
    }

    private static Selection select(List<Apk> apks) throws IOException {
        if (apks.size() < 3 || apks.size() > MAX_APKS) throw new IOException("请选择包含基础包、架构和密度分拆的完整 Claude 包。");
        Apk base = null;
        Set<String> names = new HashSet<>();
        for (Apk apk : apks) {
            if (!names.add(apk.split)) throw new IOException("安装包包含重复分拆名称。");
            if (apk.split.isEmpty()) base = apk;
        }
        if (base == null || !base.types.isEmpty()) throw new IOException("缺少唯一的 Claude 基础 APK。");
        Selection result = new Selection();
        result.apks.add(base);
        result.version = base.version;
        result.versionName = base.versionName.isEmpty() ? Long.toString(base.version) : base.versionName;
        result.signer = base.signer;
        Set<String> provided = new HashSet<>();
        int density = 0, abi = 0;
        for (Apk apk : apks) {
            if (!PACKAGE.equals(apk.pkg) || apk.version != base.version || !base.signer.equals(apk.signer))
                throw new IOException("所有 Claude 分拆必须具有相同包名、版本和当前官方签名。");
            if (apk == base) continue;
            if (!apk.required.isEmpty()) throw new IOException("配置分拆不可再要求其他分拆。");
            if (OTHER_ABI_SPLIT.equals(apk.split)) {
                if (!apk.types.equals(Collections.singleton("base__abi")) || apk.nativeFiles.isEmpty())
                    throw new IOException("32 位配置分拆结构无效。");
                continue; // Verified, but never loaded into this arm64 process.
            }
            if (ABI_SPLIT.equals(apk.split)) {
                if (!apk.types.equals(Collections.singleton("base__abi")) || apk.nativeFiles.isEmpty())
                    throw new IOException("64 位原生库配置不完整。");
                abi++;
            } else if (DENSITIES.contains(apk.split)) {
                if (!apk.types.equals(Collections.singleton("base__density")) || !apk.nativeFiles.isEmpty())
                    throw new IOException("屏幕密度配置无效。");
                density++;
            } else if (!apk.split.matches("config\\.[a-z]{2,3}(_r[A-Z]{2})?")
                    || !apk.types.isEmpty() || !apk.nativeFiles.isEmpty()) {
                throw new IOException("此 DEMO 不支持所选配置分拆。");
            }
            result.apks.add(apk);
            provided.addAll(apk.types);
        }
        if (abi != 1 || density != 1 || !provided.containsAll(base.required))
            throw new IOException("缺少唯一的 arm64 架构或屏幕密度分拆。");
        Collections.sort(result.apks, Comparator.comparing(apk -> apk.split));
        Set<String> nativeNames = new HashSet<>();
        for (Apk apk : result.apks) for (NativeFile library : apk.nativeFiles) {
            if (!nativeNames.add(library.name)) throw new IOException("配置分拆包含重复原生库。");
            result.libraries.add(library);
        }
        Collections.sort(result.libraries, Comparator.comparing(library -> library.name));
        return result;
    }

    private static State materialize(Selection selection, File payload) throws Exception {
        State state = new State();
        state.version = selection.version;
        state.versionName = selection.versionName;
        state.signer = selection.signer;
        state.directory = state.version + "-" + selection.apks.get(0).sha256;
        state.directoryFile = payload;
        for (Apk apk : selection.apks) {
            Record record = new Record();
            record.name = apk.split.isEmpty() ? "base.apk" : apk.split + ".apk";
            record.split = apk.split;
            record.sha256 = apk.sha256;
            record.size = apk.size;
            File destination = child(payload, record.name);
            try (InputStream source = new FileInputStream(apk.file)) {
                copyNew(source, destination, apk.size, MAX_APK);
            }
            readOnly(destination);
            state.apks.add(record);
        }
        File libRoot = child(payload, "lib");
        File nativeDir = child(libRoot, ABI);
        if (!libRoot.mkdir() || !nativeDir.mkdir()) throw new IOException("无法创建原生库目录。");
        for (NativeFile library : selection.libraries) {
            Record record = new Record();
            record.name = library.name;
            record.size = library.size;
            record.sha256 = library.sha256;
            File destination = child(nativeDir, record.name);
            try (ZipFile zip = new ZipFile(library.owner);
                 InputStream source = zip.getInputStream(zip.getEntry(library.entry))) {
                copyNew(source, destination, library.size, MAX_LIBRARY);
            }
            if (!record.sha256.equals(sha(destination, MAX_LIBRARY))) throw new IOException("原生库复制校验失败。");
            readOnly(destination);
            state.libraries.add(record);
        }
        validateStored(state, true, null);
        return state;
    }

    static State readState(Context host, boolean full) throws Exception {
        requireArm64();
        ClaudeUpgrade.requireIdle(host);
        File root = root(host, false);
        child(root, "active.json");
        child(root, "active.json.bak");
        child(root, "active.json.new");
        byte[] bytes;
        try (InputStream input = active(root).openRead()) { bytes = bytes(input, 128 * 1024); }
        State state = decodeState(host, new JSONObject(new String(bytes, StandardCharsets.UTF_8)), full, privateBase(host));
        ClaudeUpgrade.requireIdle(host);
        return state;
    }

    /** Also reads the immutable old/new records inside this importer's pending transaction. */
    static State decodeState(Context host, JSONObject json, boolean full, File installedBase) throws Exception {
        State state = parseState(host, json);
        validateStored(state, full, installedBase);
        return state;
    }

    static State parseState(Context host, JSONObject json) throws Exception {
        File root = root(host, false);
        if (json.getInt("schema") != 1 || !PACKAGE.equals(json.getString("package")))
            throw new IOException("Claude 安装记录无效。");
        State state = new State();
        state.version = json.getLong("version");
        state.versionName = json.getString("versionName");
        state.signer = json.getString("signer");
        state.directory = json.getString("directory");
        if (state.version <= 0 || !SIGNERS.contains(state.signer) || state.versionName.length() > 128
                || !state.directory.matches("[0-9]+-[0-9a-f]{64}"))
            throw new IOException("Claude 安装记录不符合预期。");
        state.directoryFile = child(root, state.directory);
        readRecords(json.getJSONArray("apks"), state.apks, true);
        readRecords(json.getJSONArray("libraries"), state.libraries, false);
        if (state.apks.size() < 3 || !state.apks.get(0).split.isEmpty()
                || !state.directory.equals(state.version + "-" + state.apks.get(0).sha256))
            throw new IOException("Claude 基础包安装记录缺失。");
        return state;
    }

    private static void readRecords(JSONArray items, List<Record> result, boolean apks) throws Exception {
        if (items.length() < 1 || items.length() > (apks ? MAX_APKS : 128)) throw new IOException("安装记录文件数无效。");
        Set<String> names = new HashSet<>();
        String prior = "";
        for (int i = 0; i < items.length(); i++) {
            JSONObject item = items.getJSONObject(i);
            Record record = new Record();
            record.name = item.getString("file");
            record.size = item.getLong("size");
            record.sha256 = item.getString("sha256");
            record.split = apks ? item.getString("split") : "";
            String sort = apks ? record.split : record.name;
            if (!simple(record.name) || !names.add(record.name) || record.size <= 0
                    || record.size > (apks ? MAX_APK : MAX_LIBRARY) || !record.sha256.matches("[0-9a-f]{64}")
                    || (i > 0 && prior.compareTo(sort) >= 0)
                    || (apks && !(record.split.isEmpty() ? "base.apk" : record.split + ".apk").equals(record.name))
                    || (!apks && !libraryName(record.name))) throw new IOException("安装记录包含非法文件。");
            prior = sort;
            result.add(record);
        }
    }

    static void validateStored(State state, boolean full, File installedBase) throws Exception {
        if (!state.directoryFile.isDirectory()) throw new IOException("Claude 配置分拆目录不存在。");
        List<Apk> inspected = new ArrayList<>();
        for (Record record : state.apks) {
            File apk = child(state.directoryFile, record.name);
            requireFile(apk, record.size);
            if (full) {
                Apk parsed = inspect(apk);
                if (!record.sha256.equals(parsed.sha256) || !record.split.equals(parsed.split))
                    throw new IOException("Claude 原版 APK 已改变。");
                inspected.add(parsed);
            }
        }
        File nativeDir = nativeDir(state);
        if (!nativeDir.isDirectory()) throw new IOException("Claude 原生库目录缺失。");
        String[] actual = nativeDir.list();
        if (actual == null || actual.length != state.libraries.size()) throw new IOException("Claude 原生库集合已改变。");
        Set<String> expected = new HashSet<>();
        for (Record record : state.libraries) {
            expected.add(record.name);
            File lib = child(nativeDir, record.name);
            requireFile(lib, record.size);
            if (full && !record.sha256.equals(sha(lib, MAX_LIBRARY))) throw new IOException("Claude 原生库已改变。");
        }
        for (String name : actual) if (!expected.contains(name)) throw new IOException("Claude 原生库目录包含未知文件。");
        if (full) {
            Selection selection = select(inspected);
            if (!same(state, selection)) throw new IOException("Claude 配置分拆与安装记录不一致。");
        }
        if (installedBase != null) {
            Record base = state.apks.get(0);
            requireFile(installedBase, base.size);
            if (!base.sha256.equals(sha(installedBase, MAX_APK))) throw new IOException("Claude 私有基础 APK 已改变。");
            Apk manifest = new Apk();
            readManifest(installedBase, manifest);
            if (!PACKAGE.equals(manifest.pkg) || !manifest.split.isEmpty() || manifest.version != state.version)
                throw new IOException("Claude 私有基础 APK 版本不一致。");
            if (full && !state.signer.equals(verifiedSigner(installedBase)))
                throw new IOException("Claude 私有基础 APK 签名不一致。");
        }
    }

    private static boolean same(State state, Selection selection) {
        if (state.version != selection.version || !state.signer.equals(selection.signer)
                || state.apks.size() != selection.apks.size() || state.libraries.size() != selection.libraries.size()) return false;
        for (int i = 0; i < state.apks.size(); i++) {
            Record saved = state.apks.get(i);
            Apk selected = selection.apks.get(i);
            if (!saved.split.equals(selected.split) || !saved.sha256.equals(selected.sha256) || saved.size != selected.size) return false;
        }
        for (int i = 0; i < state.libraries.size(); i++) {
            Record saved = state.libraries.get(i);
            NativeFile selected = selection.libraries.get(i);
            if (!saved.name.equals(selected.name) || !saved.sha256.equals(selected.sha256) || saved.size != selected.size) return false;
        }
        return true;
    }

    static JSONObject encodeState(State state) throws Exception {
        JSONObject json = new JSONObject();
        json.put("schema", 1).put("package", PACKAGE).put("version", state.version)
                .put("versionName", state.versionName).put("signer", state.signer).put("directory", state.directory)
                .put("apks", records(state.apks, true)).put("libraries", records(state.libraries, false));
        return json;
    }

    static void publish(AtomicFile active, State state) throws Exception {
        JSONObject json = encodeState(state);
        FileOutputStream output = null;
        try {
            output = active.startWrite();
            output.write(json.toString().getBytes(StandardCharsets.UTF_8));
            active.finishWrite(output);
        } catch (Exception failure) {
            if (output != null) active.failWrite(output);
            throw failure;
        }
    }

    private static JSONArray records(List<Record> records, boolean apks) throws Exception {
        JSONArray json = new JSONArray();
        for (Record record : records) {
            JSONObject item = new JSONObject().put("file", record.name).put("size", record.size).put("sha256", record.sha256);
            if (apks) item.put("split", record.split);
            json.put(item);
        }
        return json;
    }

    static File data(Context host) throws IOException {
        if (host == null || !HOST.equals(host.getPackageName())) throw new IOException("Claude 导入只适用于此 DEMO 空间。");
        File data = host.getDataDir().getCanonicalFile();
        if (!HOST.equals(data.getName()) || !data.isDirectory()) throw new IOException("无法确认空间私有目录。");
        return data;
    }

    static File root(Context host, boolean create) throws IOException {
        File files = child(data(host), "files");
        if (create && !files.isDirectory() && !files.mkdir()) throw new IOException("无法创建空间文件目录。");
        File root = child(files, "claude-bundles");
        if (create && !root.isDirectory() && !root.mkdir()) throw new IOException("无法创建安装包存储目录。");
        return root;
    }

    static File privateBase(Context host) throws IOException {
        File directory = new File(data(host), "blackbox/data/app/" + PACKAGE);
        return exact(new File(directory, "base.apk"));
    }

    static File nativeDir(State state) throws IOException { return child(child(state.directoryFile, "lib"), ABI); }
    static AtomicFile active(File root) throws IOException { return new AtomicFile(child(root, "active.json")); }
    static File child(File root, String name) throws IOException {
        if (!simple(name)) throw new IOException("不安全的私有文件名。");
        return exact(new File(root, name));
    }
    static File exact(File file) throws IOException {
        File absolute = file.getAbsoluteFile();
        if (!absolute.equals(file.getCanonicalFile())) throw new IOException("私有安装路径包含链接或路径跳转。");
        return absolute;
    }
    private static boolean simple(String name) {
        return name != null && name.length() <= 160 && !".".equals(name) && !"..".equals(name)
                && name.matches("[A-Za-z0-9._+-]+");
    }
    private static boolean emptyTree(File directory, int[] visited) throws IOException {
        exact(directory);
        if (!directory.exists()) return true;
        if (++visited[0] > 128 || !directory.isDirectory()) return false;
        File[] entries = directory.listFiles();
        if (entries == null) return false;
        for (File entry : entries) if (!emptyTree(entry, visited)) return false;
        return true;
    }
    private static boolean libraryName(String name) { return simple(name) && name.startsWith("lib") && name.endsWith(".so"); }
    private static boolean safeZipPath(String name) {
        if (name.isEmpty() || name.length() > 1024 || name.startsWith("/") || name.indexOf('\\') >= 0 || name.indexOf('\0') >= 0) return false;
        String clean = name.endsWith("/") ? name.substring(0, name.length() - 1) : name;
        // Internal resource names may contain ':' (Kotlin module metadata does). They are never extracted.
        // Extracted APK filenames and native library leaves use the stricter simple() allowlist.
        for (String part : clean.split("/", -1)) if (part.isEmpty() || ".".equals(part) || "..".equals(part)) return false;
        return true;
    }
    private static void requireArm64() throws IOException {
        if (!android.os.Process.is64Bit() || !Arrays.asList(Build.SUPPORTED_ABIS).contains(ABI))
            throw new IOException("此 DEMO 的 Claude 导入目前仅支持 arm64 空间。");
    }
    private static void requireFile(File file, long size) throws IOException {
        exact(file);
        if (!file.isFile() || file.length() != size) throw new IOException("Claude 安装文件缺失或大小改变。");
    }
    private static void readOnly(File file) throws IOException {
        if (!file.setReadOnly()) throw new IOException("无法将已校验的安装文件设为只读。");
    }
    private static void copyNew(InputStream input, File output, long expected, long limit) throws IOException {
        if (!output.createNewFile()) throw new IOException("拒绝覆盖现有安装文件。");
        long count = 0;
        byte[] buffer = new byte[64 * 1024];
        try (FileOutputStream stream = new FileOutputStream(output)) {
            for (int read; (read = input.read(buffer)) != -1;) {
                count += read;
                if (count > limit || count > expected) throw new IOException("解压数据超过声明大小。");
                stream.write(buffer, 0, read);
            }
            if (count != expected) throw new IOException("安装文件数据不完整。");
            stream.getFD().sync();
        }
    }
    static String sha(File file, long limit) throws Exception {
        try (InputStream source = new FileInputStream(file)) { return digest(source, limit, null); }
    }
    private static String digestNative(InputStream source, long size, boolean arm32) throws Exception {
        byte[] header = new byte[64];
        int offset = 0;
        while (offset < header.length) {
            int count = source.read(header, offset, header.length - offset);
            if (count < 0) throw new IOException("原生库 ELF 文件头不完整。");
            offset += count;
        }
        if (header[0] != 0x7f || header[1] != 'E' || header[2] != 'L' || header[3] != 'F'
                || header[4] != (arm32 ? 1 : 2) || header[5] != 1 || header[6] != 1
                || header[16] != 3 || header[17] != 0 || (header[18] & 0xff) != (arm32 ? 40 : 183) || header[19] != 0)
            throw new IOException("原生库 ELF 架构或类型不匹配。");
        CountingInputStream bounded = new CountingInputStream(source);
        String hash = digest(bounded, MAX_LIBRARY - header.length, header);
        if (bounded.count + header.length != size) throw new IOException("原生库数据长度不一致。");
        return hash;
    }
    private static String digest(InputStream source, long limit, byte[] prefix) throws Exception {
        MessageDigest hash = MessageDigest.getInstance("SHA-256");
        if (prefix != null) hash.update(prefix);
        long size = 0;
        byte[] buffer = new byte[64 * 1024];
        for (int count; (count = source.read(buffer)) != -1;) {
            size += count;
            if (size > limit) throw new IOException("文件超出校验大小限制。");
            hash.update(buffer, 0, count);
        }
        return hex(hash.digest());
    }
    private static byte[] bytes(InputStream source, int limit) throws IOException {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        byte[] buffer = new byte[8192];
        for (int count; (count = source.read(buffer)) != -1;) {
            if (output.size() + count > limit) throw new IOException("安装记录过大。");
            output.write(buffer, 0, count);
        }
        return output.toByteArray();
    }
    private static String hex(byte[] digest) {
        StringBuilder text = new StringBuilder(digest.length * 2);
        for (byte b : digest) text.append(Character.forDigit((b >> 4) & 15, 16)).append(Character.forDigit(b & 15, 16));
        return text.toString();
    }
    private static String value(String text) { return text == null ? "" : text; }
    static Field field(Class<?> type, String name) throws NoSuchFieldException {
        for (Class<?> cursor = type; cursor != null; cursor = cursor.getSuperclass()) {
            try { Field found = cursor.getDeclaredField(name); found.setAccessible(true); return found; }
            catch (NoSuchFieldException absent) { /* try parent */ }
        }
        throw new NoSuchFieldException(name);
    }
    private static void removeOwned(File file, File owned) {
        try {
            File canonical = file.getCanonicalFile(), root = owned.getCanonicalFile();
            if (!canonical.equals(file.getAbsoluteFile()) || !(canonical.equals(root)
                    || canonical.getPath().startsWith(root.getPath() + File.separator))) return;
            if (file.isDirectory()) {
                File[] children = file.listFiles();
                if (children != null) for (File nested : children) removeOwned(nested, owned);
            }
            file.delete();
        } catch (IOException ignored) { /* Preserve uncertain paths. */ }
    }

    static final class State {
        long version;
        String versionName, signer, directory;
        File directoryFile;
        final List<Record> apks = new ArrayList<>(), libraries = new ArrayList<>();
    }
    static final class Record { String name, split = "", sha256; long size; }
    private static final class Apk {
        File file;
        String pkg, split = "", versionName = "", signer, sha256;
        long version, size;
        int minSdk = 1;
        boolean hasCode;
        Set<String> required = Collections.emptySet(), types = Collections.emptySet();
        List<NativeFile> nativeFiles = Collections.emptyList();
    }
    private static final class NativeFile { String name, entry, sha256; File owner; long size; }
    private static final class Selection {
        long version;
        String versionName, signer;
        final List<Apk> apks = new ArrayList<>();
        final List<NativeFile> libraries = new ArrayList<>();
    }
    private static final class CountingInputStream extends java.io.FilterInputStream {
        long count;
        CountingInputStream(InputStream source) { super(source); }
        @Override public int read(byte[] bytes, int offset, int length) throws IOException {
            int result = in.read(bytes, offset, length);
            if (result > 0) count += result;
            return result;
        }
    }
}

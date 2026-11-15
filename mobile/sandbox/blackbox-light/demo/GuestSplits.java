package io.github.leexeo.cage.space;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.Signature;
import android.util.Log;
import java.io.File;

/** Restores verified config split resources/native paths omitted by the legacy private package parser. */
public final class GuestSplits {
    private GuestSplits() {}

    public static ApplicationInfo apply(ApplicationInfo info, int userId) {
        if (info == null || !ClaudeBundle.PACKAGE.equals(info.packageName)) return info;
        try {
            Context host = host();
            if (!ClaudeBundle.HOST.equals(host.getPackageName())) return info;
            if (userId != 0 || info.sourceDir == null) return null;
            File base = new File(info.sourceDir).getCanonicalFile();
            if (!base.getPath().startsWith(ClaudeBundle.data(host).getPath() + File.separator)) return null;
            if (ClaudeUpgrade.pending(host)) {
                // Registration parses the immutable incoming base before copying it to privateBase.
                // Neither this metadata exception nor a matching base allows guest application binding.
                return ClaudeUpgrade.allowRegistration(host, base) ? info : null;
            }
            File active = ClaudeBundle.child(ClaudeBundle.root(host, false), "active.json");
            if (!active.exists() && !new File(active + ".bak").exists()) {
                // Component registration needs the parsed base before commit. verify() still blocks launch.
                return info;
            }
            if (!base.equals(ClaudeBundle.privateBase(host))) return null;
            ClaudeBundle.State state = ClaudeBundle.readState(host, false);
            int count = state.apks.size() - 1;
            String[] paths = new String[count], names = new String[count];
            for (int i = 0; i < count; i++) {
                ClaudeBundle.Record split = state.apks.get(i + 1);
                names[i] = split.split;
                paths[i] = ClaudeBundle.child(state.directoryFile, split.name).getPath();
            }
            info.splitSourceDirs = paths;
            info.splitPublicSourceDirs = paths.clone();
            ClaudeBundle.field(ApplicationInfo.class, "splitNames").set(info, names);
            info.nativeLibraryDir = ClaudeBundle.nativeDir(state).getPath();
            ClaudeBundle.field(ApplicationInfo.class, "primaryCpuAbi").set(info, "arm64-v8a");
            optional(info, "secondaryCpuAbi", null);
            optional(info, "secondaryNativeLibraryDir", null);
            optional(info, "nativeLibraryRootDir", info.nativeLibraryDir);
            optional(info, "nativeLibraryRootRequiresIsa", false);
            optional(info, "splitClassLoaderNames", new String[count]);
            optional(info, "splitDependencies", null);
            return info;
        } catch (Exception incomplete) {
            // During first install there is deliberately no active record until the private base is complete.
            Log.w("CageDemo", "Claude split metadata unavailable: " + incomplete.getClass().getSimpleName());
            return null;
        }
    }

    public static PackageInfo packageInfo(PackageInfo info, int flags) {
        if (info == null || !ClaudeBundle.PACKAGE.equals(info.packageName) || info.applicationInfo == null) return info;
        try {
            Context host = host();
            if (!ClaudeBundle.HOST.equals(host.getPackageName())) return info;
            String[] names = (String[]) ClaudeBundle.field(ApplicationInfo.class, "splitNames").get(info.applicationInfo);
            info.splitNames = names == null ? null : names.clone();
            info.splitRevisionCodes = names == null ? null : new int[names.length];
            int signatureFlags = flags & (PackageManager.GET_SIGNATURES | PackageManager.GET_SIGNING_CERTIFICATES);
            if (signatureFlags != 0 && !ClaudeUpgrade.pending(host)) {
                File base = ClaudeBundle.privateBase(host);
                if (!base.equals(new File(info.applicationInfo.sourceDir).getCanonicalFile()))
                    throw new SecurityException("Unexpected private package source");
                ClaudeBundle.State state = ClaudeBundle.readState(host, false);
                PackageInfo archive = host.getPackageManager().getPackageArchiveInfo(base.getPath(),
                        PackageManager.GET_SIGNING_CERTIFICATES);
                if (archive == null || !ClaudeBundle.PACKAGE.equals(archive.packageName)
                        || SpacePackages.version(archive) != state.version || archive.signingInfo == null)
                    throw new SecurityException("Original package signing metadata unavailable");
                Signature[] signers = archive.signingInfo.getApkContentsSigners();
                if (signers == null || signers.length != 1)
                    throw new SecurityException("Unexpected original package signers");
                byte[] digest = java.security.MessageDigest.getInstance("SHA-256").digest(signers[0].toByteArray());
                StringBuilder hex = new StringBuilder();
                for (byte value : digest) hex.append(String.format(java.util.Locale.ROOT, "%02x", value & 255));
                if (!state.signer.equals(hex.toString()))
                    throw new SecurityException("Original package signer changed");
                // Preserve Android's actual signing history. The old shell's
                // PackageParser.SigningDetails constructor is obsolete on newer Android.
                if ((flags & PackageManager.GET_SIGNING_CERTIFICATES) != 0) info.signingInfo = archive.signingInfo;
                if ((flags & PackageManager.GET_SIGNATURES) != 0) info.signatures = signers.clone();
            }
            return info;
        } catch (Exception unavailable) { throw new SecurityException("Claude split metadata unavailable", unavailable); }
    }

    /** Called before guest application binding; every APK and extracted native library is checked again. */
    public static void verify(Context host) {
        try { ClaudeBundle.readState(host, true); }
        catch (Exception invalid) { throw new SecurityException("Claude original bundle verification failed", invalid); }
    }

    public static void beforeContext(ApplicationInfo info) {
        if (info == null || !ClaudeBundle.PACKAGE.equals(info.packageName)) return;
        try { verify(host()); }
        catch (Exception invalid) { throw new SecurityException("Claude cannot load before bundle commit", invalid); }
    }

    public static boolean ready(Context host) {
        try { ClaudeBundle.readState(host, false); return true; }
        catch (Exception incomplete) { return false; }
    }

    private static Context host() throws Exception {
        return (Context) Class.forName("top.niunaijun.blackbox.BlackBoxCore").getMethod("getContext").invoke(null);
    }

    private static void optional(ApplicationInfo info, String name, Object value) throws Exception {
        try { ClaudeBundle.field(ApplicationInfo.class, name).set(info, value); }
        catch (NoSuchFieldException olderPlatform) { /* Optional metadata was introduced on different Android releases. */ }
    }
}

package io.github.leexeo.cage.space;

import android.accounts.AccountManager;
import android.accounts.AuthenticatorDescription;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.content.pm.ServiceInfo;
import android.content.res.Resources;
import android.content.res.XmlResourceParser;
import android.os.Build;
import android.util.Log;
import java.io.IOException;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Set;
import org.xmlpull.v1.XmlPullParserException;

/** Read-only discovery from the calling guest's package manifest and its own space's services. */
public final class GuestAuthenticatorTypes {
    private static final String ANDROID = "http://schemas.android.com/apk/res/android";
    private static final String ROOT = "top.niunaijun.blackbox.";
    private static final String AUTH = AccountManager.ACTION_AUTHENTICATOR_INTENT;

    public static boolean cannotAddAccount(Context context, String accountType) {
        return "com.google".equals(accountType) && Build.VERSION.SDK_INT == 36
                && context.checkSelfPermission(android.Manifest.permission.ACCOUNT_MANAGER)
                        != PackageManager.PERMISSION_GRANTED;
    }

    public static AuthenticatorDescription[] forCaller(int userId, int callerPid) {
        LinkedHashMap<String, AuthenticatorDescription> found = new LinkedHashMap<>();
        try {
            // Resolve the real Binder caller on the server instead of trusting a guest-supplied package.
            Class<?> processes = Class.forName(ROOT + "core.system.BProcessManagerService");
            Object caller = processes.getMethod("findProcessByPid", int.class)
                    .invoke(processes.getMethod("get").invoke(null), callerPid);
            if (caller == null || caller.getClass().getField("userId").getInt(caller) != userId)
                return new AuthenticatorDescription[0];
            ApplicationInfo app = (ApplicationInfo) caller.getClass().getField("info").get(caller);
            Context context = (Context) Class.forName(ROOT + "BlackBoxCore").getMethod("getContext").invoke(null);
            Class<?> pmType = Class.forName(ROOT + "core.system.pm.BPackageManagerService");
            Object pm = pmType.getMethod("get").invoke(null);
            PackageInfo pkg = (PackageInfo) pmType.getMethod("getPackageInfo", String.class, int.class, int.class)
                    .invoke(pm, app.packageName, PackageManager.GET_PERMISSIONS, userId);
            if (pkg == null || pkg.applicationInfo == null) return new AuthenticatorDescription[0];
            Visibility visibility = new Visibility(context, pkg);
            @SuppressWarnings("unchecked")
            List<ResolveInfo> services = (List<ResolveInfo>) pmType.getMethod("queryIntentServices",
                    Intent.class, int.class, int.class).invoke(pm, new Intent(AUTH), PackageManager.GET_META_DATA, userId);
            for (ResolveInfo match : services) {
                ServiceInfo service = match.serviceInfo;
                if (service == null || service.metaData == null || !service.enabled
                        || !service.applicationInfo.enabled || !visibility.includes(service)) continue;
                AuthenticatorDescription description = readDescription(context, service);
                if (description != null && !found.containsKey(description.type))
                    found.put(description.type, description);
            }
        } catch (ReflectiveOperationException | IOException | XmlPullParserException
                 | PackageManager.NameNotFoundException | RuntimeException unavailable) {
            Log.w("CageSpace", "Guest authenticator discovery unavailable: " + unavailable.getClass().getSimpleName());
        }
        return found.values().toArray(new AuthenticatorDescription[0]);
    }

    private static AuthenticatorDescription readDescription(Context context, ServiceInfo service) {
        int xmlId = service.metaData.getInt(AccountManager.AUTHENTICATOR_META_DATA_NAME);
        if (xmlId == 0) return null;
        try {
            Resources res = context.getPackageManager().getResourcesForApplication(service.applicationInfo);
            try (XmlResourceParser xml = res.getXml(xmlId)) {
                while (xml.next() != XmlResourceParser.END_DOCUMENT) {
                    if (xml.getEventType() != XmlResourceParser.START_TAG) continue;
                    if (!AccountManager.AUTHENTICATOR_ATTRIBUTES_NAME.equals(xml.getName())) return null;
                    int id = xml.getAttributeResourceValue(ANDROID, "accountType", 0);
                    String type = id == 0 ? xml.getAttributeValue(ANDROID, "accountType") : res.getString(id);
                    if (type == null || type.isEmpty()) return null;
                    return new AuthenticatorDescription(type, service.packageName,
                            xml.getAttributeResourceValue(ANDROID, "label", 0),
                            xml.getAttributeResourceValue(ANDROID, "icon", 0),
                            xml.getAttributeResourceValue(ANDROID, "smallIcon", 0),
                            xml.getAttributeResourceValue(ANDROID, "accountPreferences", 0),
                            xml.getAttributeBooleanValue(ANDROID, "customTokens", false));
                }
            }
        } catch (IOException | XmlPullParserException | PackageManager.NameNotFoundException | RuntimeException invalid) {
            Log.w("CageSpace", "Unreadable guest authenticator metadata: " + invalid.getClass().getSimpleName());
        }
        return null;
    }

    private static final class Visibility {
        final PackageInfo caller;
        final boolean allPackages;
        final Set<String> packages = new HashSet<>();
        boolean queriesAuthenticators;

        Visibility(Context context, PackageInfo caller)
                throws PackageManager.NameNotFoundException, IOException, XmlPullParserException {
            this.caller = caller;
            allPackages = Build.VERSION.SDK_INT < 30 || caller.applicationInfo.targetSdkVersion < 30
                    || (caller.requestedPermissions != null && Arrays.asList(caller.requestedPermissions)
                            .contains("android.permission.QUERY_ALL_PACKAGES"));
            if (allPackages) return;
            Resources res = context.getPackageManager().getResourcesForApplication(caller.applicationInfo);
            // Use this APK's manifest, not the host shell's QUERY_ALL_PACKAGES permission.
            try (XmlResourceParser xml = res.getAssets().openXmlResourceParser("AndroidManifest.xml")) {
                boolean queries = false, intent = false, matches = false, restricted = false;
                for (int event; (event = xml.next()) != XmlResourceParser.END_DOCUMENT;) {
                    String tag = xml.getName();
                    int depth = xml.getDepth();
                    if (event == XmlResourceParser.START_TAG) {
                        if (depth == 2) queries = "queries".equals(tag);
                        if (!queries) continue;
                        if (depth == 3 && "package".equals(tag)) packages.add(xml.getAttributeValue(ANDROID, "name"));
                        if (depth == 3) { intent = "intent".equals(tag); matches = false; restricted = false; }
                        if (intent && depth == 4) {
                            if ("action".equals(tag)) matches |= AUTH.equals(xml.getAttributeValue(ANDROID, "name"));
                            else restricted = true;
                        }
                    } else if (event == XmlResourceParser.END_TAG) {
                        if (queries && intent && depth == 3) {
                            queriesAuthenticators |= matches && !restricted;
                            intent = false;
                        }
                        if (depth == 2) queries = false;
                    }
                }
            }
        }

        boolean includes(ServiceInfo service) {
            // This API lists descriptions of visible *packages*. A private service is not bindable
            // by a guest, but explicit package visibility still permits its type to be listed.
            return service.packageName.equals(caller.packageName) || allPackages
                    || packages.contains(service.packageName) || (queriesAuthenticators && service.exported);
        }
    }
}

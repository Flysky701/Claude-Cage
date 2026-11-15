package io.github.leexeo.cage.shell;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.os.Build;
import android.os.SystemClock;
import android.provider.Settings;
import android.telephony.TelephonyManager;
import android.webkit.WebView;
import java.net.NetworkInterface;
import java.util.Enumeration;
import java.util.Locale;
import java.util.TimeZone;
import org.json.JSONArray;
import org.json.JSONObject;
import io.github.leexeo.cage.preflight.NetworkProbe;
import io.github.leexeo.cage.preflight.NetworkMetadata;

final class Checks {
    private static final String[] SIM_JAVA = {"simCountry","simOperator","simOperatorName",
        "networkCountry","networkOperator","networkOperatorName"};
    private static final String[] SIM_KEYS = {"gsm.sim.operator.iso-country","gsm.sim.operator.alpha",
        "gsm.sim.operator.numeric","gsm.operator.iso-country","gsm.operator.alpha","gsm.operator.numeric"};
    static final class Outer {
        boolean network, networkKnown, vpn, vpnKnown, sim, simKnown, tunnel;
        JSONObject egress, linkMetadata;
        boolean protectionReadable, protectionConfigured, activeVpn;
    }
    static Outer outer(Context context) {
        Outer out = new Outer();
        try {
            ConnectivityManager manager = context.getSystemService(ConnectivityManager.class);
            Network network = manager.getActiveNetwork();
            NetworkCapabilities cap = network == null ? null : manager.getNetworkCapabilities(network);
            out.networkKnown = true;
            out.network = cap != null && cap.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                && cap.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED);
            out.vpnKnown = true;
            out.vpn = cap != null && cap.hasTransport(NetworkCapabilities.TRANSPORT_VPN);
            out.activeVpn = out.vpn;
            out.linkMetadata = NetworkMetadata.link(network == null ? null : manager.getLinkProperties(network));
            for (Network item : manager.getAllNetworks()) {
                NetworkCapabilities c = manager.getNetworkCapabilities(item);
                if (c != null && c.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) out.vpn = true;
            }
        } catch (RuntimeException ignored) { }
        try {
            TelephonyManager phone = context.getSystemService(TelephonyManager.class);
            if (phone != null) {
                out.simKnown = true;
                out.sim = phone.getSimState() == TelephonyManager.SIM_STATE_READY
                    || !phone.getSimOperator().isEmpty() || !phone.getNetworkOperator().isEmpty();
            }
        } catch (RuntimeException ignored) { }
        try {
            Enumeration<NetworkInterface> list = NetworkInterface.getNetworkInterfaces();
            while (list.hasMoreElements()) if (tunnel(list.nextElement().getName())) out.tunnel = true;
        } catch (Exception ignored) { }
        boolean[] protection = protectionConfiguration(context);
        out.protectionReadable = protection[0];
        out.protectionConfigured = protection[1];
        out.egress = out.network ? NetworkProbe.measure() : new JSONObject();
        return out;
    }
    static String fingerprint(Context context) {
        StringBuilder out = new StringBuilder(Build.VERSION.SDK_INT + "|" + TimeZone.getDefault().getID()
            + "|" + Locale.getDefault().toLanguageTag());
        try {
            ConnectivityManager cm = context.getSystemService(ConnectivityManager.class);
            Network active = cm.getActiveNetwork();
            NetworkCapabilities caps = active == null ? null : cm.getNetworkCapabilities(active);
            out.append('|').append(active).append('|').append(caps == null ? "none" :
                caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN) + ":" + caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED));
            android.content.pm.PackageInfo web = WebView.getCurrentWebViewPackage();
            out.append('|').append(web == null ? "none" : web.packageName + ":" + web.getLongVersionCode());
        } catch (Exception ignored) { out.append("|unavailable"); }
        boolean[] protection = protectionConfiguration(context);
        out.append('|').append(protection[0]).append(':').append(protection[1]);
        return out.toString();
    }
    private static boolean[] protectionConfiguration(Context context) {
        try {
            String lockdown = Settings.Secure.getString(context.getContentResolver(), "always_on_vpn_lockdown");
            String owner = Settings.Secure.getString(context.getContentResolver(), "always_on_vpn_app");
            boolean enabled = "1".equals(lockdown) && owner != null && !owner.isEmpty();
            return new boolean[]{"0".equals(lockdown) || enabled, enabled};
        } catch (RuntimeException unavailable) {
            return new boolean[]{false, false};
        }
    }
    static JSONObject object(JSONObject value, String key) {
        JSONObject result = value == null ? null : value.optJSONObject(key);
        return result == null ? new JSONObject() : result;
    }
    static Object value(JSONObject read) {
        String status = read.optString("status");
        if ((!"OK".equals(status) && !"EMPTY".equals(status) && !"NULL".equals(status)) || !read.has("value")) return null;
        return read.opt("value");
    }
    private static boolean tunnel(String name) {
        return name != null && (name.startsWith("tun") || name.startsWith("tap") || name.startsWith("wg")
            || name.startsWith("ppp") || name.startsWith("utun"));
    }
    private static final class Measure {
        boolean complete=true, signal, matches=true;
        void empty(Object item) { if (!(item instanceof String)) complete=false; else if(!((String)item).isEmpty()) signal=true; }
        void equalsValue(Object item, Object expected) { if(item==null || item==JSONObject.NULL) complete=false; else if(!expected.equals(item)) matches=false; }
        void number(Object item, int expected) { if(!(item instanceof Number)) complete=false; else if(((Number)item).intValue()!=expected) matches=false; }
        void network(JSONObject cap) {
            if (!(cap.opt("vpn") instanceof Boolean) || !(cap.opt("notVpn") instanceof Boolean)) complete=false;
            else if(cap.optBoolean("vpn") || !cap.optBoolean("notVpn")) signal=true;
        }
        void iface(Object name) { if(name!=JSONObject.NULL && !(name instanceof String)) complete=false; else if(name instanceof String && tunnel((String)name)) signal=true; }
    }
    static void evaluate(CheckReport report, Outer outer, JSONObject guest, String target) {
        report.add("network", "网络连接", !outer.networkKnown ? CheckPolicy.State.UNKNOWN : outer.network ? CheckPolicy.State.PASSED : CheckPolicy.State.FAILED,
            outer.network ? "手机当前网络可用。" : "未确认手机已连接可用网络，请检查代理连接。");
        JSONObject nativeData=object(guest,"nativeInProcess"), child=object(guest,"nativeSubprocess");
        JSONObject nativeProps=object(nativeData,"properties"), childProps=object(child,"properties");
        JSONObject apis=object(nativeData,"propertyApis"), legacy=object(apis,"legacyRead"), callback=object(apis,"callback");
        Measure sim=new Measure();
        JSONObject javaSim=object(guest,"sim");
        for(String key:SIM_JAVA) sim.empty(value(object(javaSim,key)));
        Object state=value(object(javaSim,"defaultState"));
        if(!(state instanceof Number)) sim.complete=false;
        else if(((Number)state).intValue()!=1) sim.signal=true;
        JSONArray slots=javaSim.optJSONArray("slots");
        if(slots==null || slots.length()<2) sim.complete=false;
        else for(int i=0;i<slots.length();i++) {
            Object slot=value(object(slots.optJSONObject(i),"state"));
            if(!(slot instanceof Number)) sim.complete=false; else if(((Number)slot).intValue()!=1) sim.signal=true;
        }
        for(String key:SIM_KEYS) {
            sim.empty(value(object(nativeProps,key))); sim.empty(value(object(childProps,key)));
            sim.empty(legacy.opt(key)); sim.empty(callback.opt(key));
        }
        if(!"OK".equals(nativeData.optString("status")) || !apis.optBoolean("callbacksValid")) sim.complete=false;
        CheckPolicy.State simState=CheckPolicy.mask(sim.complete,outer.simKnown && outer.sim,sim.signal);
        report.add("sim_mask", "SIM 屏蔽", simState, simState==CheckPolicy.State.PASSED
            ? "手机有 SIM 信号；空间内已测系统、原生和子进程接口未显示运营商信息。"
            : sim.signal ? "空间内仍有接口能读取 SIM 信号。" : "缺少完整读数或手机端阳性对照，不能确认屏蔽有效。");

        Measure vpn=new Measure(); JSONObject network=object(guest,"network");
        Object active=value(object(network,"active"));
        if(!(active instanceof JSONObject)) vpn.complete=false;
        else {
            Object cap=value(object((JSONObject)active,"capabilities"));
            if(cap instanceof JSONObject) vpn.network((JSONObject)cap); else vpn.complete=false;
            vpn.iface(value(object((JSONObject)active,"interface")));
        }
        Object all=value(object(network,"allNetworks"));
        if(!(all instanceof JSONArray)) vpn.complete=false;
        else for(int i=0;i<((JSONArray)all).length();i++) {
            JSONObject row=((JSONArray)all).optJSONObject(i);
            Object cap=value(object(row,"capabilities"));
            if(cap instanceof JSONObject) vpn.network((JSONObject)cap); else vpn.complete=false;
            vpn.iface(value(object(row,"interface")));
        }
        Object ifaces=value(object(network,"interfaces"));
        if(!(ifaces instanceof JSONArray)) vpn.complete=false;
        else for(int i=0;i<((JSONArray)ifaces).length();i++) {
            JSONObject row=((JSONArray)ifaces).optJSONObject(i);
            vpn.iface(row==null?null:row.opt("name"));
        }
        Object nativeIfaces=value(object(nativeData,"interfaces"));
        if(!(nativeIfaces instanceof JSONArray)) vpn.complete=false;
        else for(int i=0;i<((JSONArray)nativeIfaces).length();i++) vpn.iface(((JSONArray)nativeIfaces).opt(i));
        JSONObject events=object(guest,"networkCallback"); JSONArray caps=events.optJSONArray("events");
        if(!"OK".equals(events.optString("status")) || caps==null || caps.length()==0) vpn.complete=false;
        else for(int i=0;i<caps.length();i++) { JSONObject cap=caps.optJSONObject(i); if(cap==null)vpn.complete=false;else vpn.network(cap); }
        CheckPolicy.State vpnState=CheckPolicy.mask(vpn.complete,outer.vpnKnown && outer.vpn && outer.tunnel,vpn.signal);
        report.add("vpn_mask", "VPN 状态屏蔽", vpnState, vpnState==CheckPolicy.State.PASSED
            ? "手机 VPN 正在运行；空间内已测网络能力、回调和接口未显示 VPN。"
            : vpn.signal ? "空间内仍可观察到 VPN 状态或接口。" : "需要活动 VPN 和完整接口读数作对照。");

        JSONObject linkMetadata = active instanceof JSONObject ? object((JSONObject)active, "metadata") : new JSONObject();
        JSONArray linkEvents = events.optJSONArray("linkProperties");
        boolean metadataComplete = guest.optInt("networkMetadataVersion") == 1
            && NetworkMetadata.complete(outer.linkMetadata) && NetworkMetadata.complete(linkMetadata)
            && "OK".equals(events.optString("status")) && linkEvents != null && linkEvents.length() > 0;
        boolean metadataEmpty = NetworkMetadata.empty(linkMetadata);
        if (linkEvents != null) for (int i=0;i<linkEvents.length();i++) {
            JSONObject sample = object(linkEvents.optJSONObject(i), "metadata");
            metadataComplete &= NetworkMetadata.complete(sample);
            metadataEmpty &= NetworkMetadata.empty(sample);
        }
        boolean metadataPositive = outer.activeVpn && NetworkMetadata.hasPayload(outer.linkMetadata)
            && outer.linkMetadata.optBoolean("tunnelInterfaceName");
        CheckPolicy.State metadataState = CheckPolicy.networkMetadata(metadataComplete, metadataPositive, metadataEmpty);
        report.add("vpn_metadata", "VPN 网络信息", metadataState,
            metadataState == CheckPolicy.State.PASSED
                ? "已测 VPN 链路及回调未携带地址、DNS、路由或代理信息；其他网络接口仍需单独验证。"
                : metadataState == CheckPolicy.State.FAILED
                    ? "活动链路或回调仍含网络信息，需要核对过滤范围。"
                    : "缺少有效的 VPN 网络信息对照或完整读数，不能认定已隔离。", true);

        Measure zone=new Measure(); JSONObject time=object(guest,"timezone");
        for(String key:new String[]{"javaId","icuId","environmentTZ"}) zone.equalsValue(value(object(time,key)),CheckPolicy.ZONE);
        for(String key:new String[]{"javaOffsetMinutes","icuOffsetMinutes"}) zone.number(value(object(time,key)),540);
        zone.equalsValue(value(object(nativeProps,"persist.sys.timezone")),CheckPolicy.ZONE);
        zone.equalsValue(value(object(childProps,"persist.sys.timezone")),CheckPolicy.ZONE);
        zone.equalsValue(legacy.opt("persist.sys.timezone"),CheckPolicy.ZONE);
        zone.equalsValue(callback.opt("persist.sys.timezone"),CheckPolicy.ZONE);
        Object date=value(object(child,"date"));
        if(!(date instanceof String)) zone.complete=false; else if(!((String)date).contains("|+0900|"))zone.matches=false;
        for(String key:new String[]{"initialTime","afterTzsetTime"}) {
            Object reading=value(object(nativeData,key));
            if(!(reading instanceof JSONObject)) zone.complete=false;
            else zone.number(((JSONObject)reading).opt("offsetSeconds"),32400);
        }
        report.add("guest_settings", "系统时区", CheckPolicy.timezone(zone.complete,zone.matches),
            zone.complete && zone.matches ? "已测 Java、ICU、原生与子进程均为东京（UTC+9）。" : "存在缺失或不一致的时区读数；目标为东京（UTC+9）。");
        JSONObject web=object(guest,"webview"); Object webValue=value(web);
        JSONObject page=webValue instanceof JSONObject?(JSONObject)webValue:new JSONObject(), first=object(page,"firstScript");
        boolean complete=page.has("timezone") && first.has("timezone") && page.has("offsetMinutes") && first.has("offsetMinutes");
        boolean correct=CheckPolicy.ZONE.equals(page.optString("timezone")) && CheckPolicy.ZONE.equals(first.optString("timezone"))
            && page.optInt("offsetMinutes")==540 && first.optInt("offsetMinutes")==540;
        report.add("browser_settings", "网页时区", !complete ? CheckPolicy.State.UNKNOWN : CheckPolicy.State.FAILED,
            !complete ? "本轮未取得完整网页读数。" : correct
                ? "本次读数为东京，但当前版本仍有已知的首次脚本时区竞态，尚未稳定通过。"
                : "网页首次脚本仍读到原系统时区，随后才切到东京；这一缺口尚未解决。");

        JSONObject egress=object(guest,"egress"); String ip=egress.optString("ip"), hostIp=outer.egress.optString("ip");
        boolean validIp="OK".equals(egress.optString("status")) && NetworkProbe.publicIpv4(ip);
        report.add("proxy_transport", "空间联网", validIp?CheckPolicy.State.PASSED:CheckPolicy.State.UNKNOWN,
            validIp?"空间已通过固定 HTTPS 服务取得出口读数。":"出口检测未完成或超时，请确认手机代理可用后重试。");
        String country=egress.optString("country"), locationZone=egress.optString("timezone");
        report.location=country.matches("[A-Z]{2}") ? "出口地区 " + country : "出口地区尚未确认";
        report.add("exit_region", "出口地区", !country.matches("[A-Z]{2}")?CheckPolicy.State.UNKNOWN:
            "CN".equals(country)?CheckPolicy.State.FAILED:CheckPolicy.State.PASSED,
            country.matches("[A-Z]{2}")?"检测地区："+country+"；当前规则为中国大陆以外。":"地区查询未取得有效结果，不能凭连接成功判断地区。");
        report.add("exit_consistency", "出口一致性", !validIp || !NetworkProbe.publicIpv4(hostIp)?CheckPolicy.State.UNKNOWN:
            ip.equals(hostIp)?CheckPolicy.State.PASSED:CheckPolicy.State.FAILED,
            validIp && ip.equals(hostIp)?"手机与空间在本轮测得相同公网出口。":"手机与空间出口不同，或有一侧未取得读数。");
        report.add("exit_timezone", "出口与时区匹配", locationZone.isEmpty()?CheckPolicy.State.UNKNOWN:
            CheckPolicy.ZONE.equals(locationZone)?CheckPolicy.State.PASSED:CheckPolicy.State.FAILED,
            locationZone.isEmpty()?"未取得出口时区，无法核对。":"出口时区："+locationZone+"；空间目标：Asia/Tokyo。");
        report.add("app_scope", "应用适配范围", target==null || CheckPolicy.selected(target)?CheckPolicy.State.PASSED:CheckPolicy.State.FAILED,
            target==null || CheckPolicy.selected(target)?"当前屏蔽适配覆盖 Claude 与内置检测组件；不代表其他应用均已覆盖。":"所选应用尚未接入屏蔽策略，当前检查结果不能替代该应用的验证。");
        CheckPolicy.State protection = CheckPolicy.failClosedConfiguration(outer.protectionReadable, outer.protectionConfigured);
        report.add("fail_closed", "代理断线保护", protection,
            protection == CheckPolicy.State.FAILED ? "系统尚未启用无 VPN 时阻止连接；代理停止后不能保证阻止直接联网。"
                : outer.protectionConfigured ? "系统保护设置已开启，但尚未通过实际断线验证。"
                : "应用无法完整读取系统保护设置；尚未验证代理中断后能否阻止直接联网。", true);
        report.add("dns_transport", "DNS 防泄漏", CheckPolicy.State.UNKNOWN,"联网成功不等于 DNS 无泄漏；安卓端尚未接入独立的解析约束验证。",true);
        report.add("udp_ipv6", "UDP 与 IPv6 约束", CheckPolicy.State.UNKNOWN,"尚未验证全部 UDP、IPv6 和直接系统调用路径。",true);
        report.add("filesystem_boundary", "文件与管理边界", CheckPolicy.State.UNKNOWN,"保留各应用原数据目录；尚未完成针对跨应用访问与宿主管理接口的对抗性检查。",true);
    }
}

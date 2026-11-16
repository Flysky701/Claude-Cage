package top.niunaijun.blackbox.fake.service;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.IBinder;
import android.os.LocaleList;
import java.lang.reflect.Method;
import black.android.os.BRServiceManager;
import top.niunaijun.blackbox.BlackBoxCore;
import top.niunaijun.blackbox.app.BActivityThread;
import top.niunaijun.blackbox.fake.hook.BinderInvocationStub;
import top.niunaijun.blackbox.fake.hook.MethodHook;
import top.niunaijun.blackbox.fake.hook.ProxyMethods;

/** Keep a guest's application-language preference inside its own data. */
public final class ILocaleManagerProxy extends BinderInvocationStub {
    public ILocaleManagerProxy() { super(BRServiceManager.get().getService("locale")); }
    @Override protected Object getWho() {
        try { return Class.forName("android.app.ILocaleManager$Stub").getMethod("asInterface",IBinder.class)
                .invoke(null,BRServiceManager.get().getService("locale")); }
        catch (ReflectiveOperationException error) { throw new IllegalStateException(error); }
    }
    @Override protected void inject(Object base,Object proxy) { replaceSystemService("locale"); }
    @Override public boolean isBadEnv() { return false; }
    @ProxyMethods({"getApplicationLocales","setApplicationLocales"})
    public static final class ApplicationLocales extends MethodHook {
        @Override protected Object hook(Object who,Method method,Object[] args) throws Throwable {
            String guest=BActivityThread.getAppPackageName();
            if (guest == null || args == null || args.length < 2 || !guest.equals(args[0]))
                return method.invoke(who,args);
            android.app.Application app=BActivityThread.getApplication();
            if(app == null) return method.invoke(who,args);
            SharedPreferences preferences=app.getSharedPreferences("cage_application_locales",Context.MODE_PRIVATE);
            if("getApplicationLocales".equals(method.getName()))
                return LocaleList.forLanguageTags(preferences.getString("tags",""));
            LocaleList locales=(LocaleList)args[2];
            if(locales == null) throw new IllegalArgumentException("Locales required");
            if(!preferences.edit().putString("tags",locales.toLanguageTags()).commit())
                throw new IllegalStateException("Unable to save guest language preference");
            android.content.res.Configuration config=new android.content.res.Configuration(app.getResources().getConfiguration());
            config.setLocales(locales.isEmpty() ? android.content.res.Resources.getSystem().getConfiguration().getLocales() : locales);
            app.getResources().updateConfiguration(config,app.getResources().getDisplayMetrics());
            return null;
        }
    }
}

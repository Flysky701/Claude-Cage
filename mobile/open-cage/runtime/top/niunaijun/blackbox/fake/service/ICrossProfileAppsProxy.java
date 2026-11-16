package top.niunaijun.blackbox.fake.service;

import android.os.IBinder;
import java.lang.reflect.Method;
import java.util.Collections;
import black.android.os.BRServiceManager;
import top.niunaijun.blackbox.app.BActivityThread;
import top.niunaijun.blackbox.fake.hook.BinderInvocationStub;
import top.niunaijun.blackbox.fake.hook.MethodHook;
import top.niunaijun.blackbox.fake.hook.ProxyMethod;

/** Cage guests have no cross-profile installation on the physical device. */
public final class ICrossProfileAppsProxy extends BinderInvocationStub {
    public ICrossProfileAppsProxy() { super(BRServiceManager.get().getService("crossprofileapps")); }
    @Override protected Object getWho() {
        try { return Class.forName("android.content.pm.ICrossProfileApps$Stub")
                .getMethod("asInterface", IBinder.class)
                .invoke(null, BRServiceManager.get().getService("crossprofileapps")); }
        catch (ReflectiveOperationException error) { throw new IllegalStateException(error); }
    }
    @Override protected void inject(Object base, Object proxy) { replaceSystemService("crossprofileapps"); }
    @Override public boolean isBadEnv() { return false; }
    @ProxyMethod("getTargetUserProfiles")
    public static final class TargetProfiles extends MethodHook {
        @Override protected Object hook(Object who, Method method, Object[] args) throws Throwable {
            String guest = BActivityThread.getAppPackageName();
            if (guest != null && args != null && args.length == 1 && guest.equals(args[0]))
                return Collections.emptyList();
            return method.invoke(who, args);
        }
    }
}

package top.niunaijun.blackbox.fake.service;

import android.os.IBinder;
import black.android.os.BRServiceManager;
import top.niunaijun.blackbox.fake.hook.BinderInvocationStub;

/** Subscription reads reach the same selected-guest privacy policy as telephony. */
public final class ISubProxy extends BinderInvocationStub {
    public ISubProxy() { super(BRServiceManager.get().getService("isub")); }
    @Override protected Object getWho() {
        try {
            return Class.forName("com.android.internal.telephony.ISub$Stub")
                    .getMethod("asInterface", IBinder.class)
                    .invoke(null, BRServiceManager.get().getService("isub"));
        } catch (ReflectiveOperationException unavailable) {
            throw new IllegalStateException("Subscription service unavailable", unavailable);
        }
    }
    @Override protected void inject(Object base, Object proxy) { replaceSystemService("isub"); }
    @Override public boolean isBadEnv() { return false; }
}

package io.github.flysky701.cage.open;

import android.content.AttributionSource;
import java.lang.reflect.Field;
import top.niunaijun.blackbox.BlackBoxCore;
import top.niunaijun.blackbox.app.BActivityThread;

/** Attribute private-provider calls to the real guest, and system calls to its host. */
public final class ProviderAttribution {
    private ProviderAttribution() {}
    public static Object[] arguments(Object[] original,String providerPackage) throws ReflectiveOperationException {
        if(original == null || original.length == 0) return original;
        Object[] args=original.clone();
        String guest=BActivityThread.getAppPackageName();
        boolean privateProvider=guest != null && providerPackage != null && !BlackBoxCore.getHostPkg().equals(providerPackage);
        int uid=privateProvider ? BActivityThread.getBUid() : BlackBoxCore.getHostUid();
        String caller=privateProvider ? guest : BlackBoxCore.getHostPkg();
        if(android.os.Build.VERSION.SDK_INT >= 31 && args[0] instanceof AttributionSource) {
            AttributionSource copy=new AttributionSource.Builder((AttributionSource)args[0]).build();
            Field stateField=AttributionSource.class.getDeclaredField("mAttributionSourceState");
            stateField.setAccessible(true);
            Object state=stateField.get(copy);
            state.getClass().getField("uid").setInt(state,uid);
            state.getClass().getField("pid").setInt(state,android.os.Process.myPid());
            state.getClass().getField("packageName").set(state,caller);
            args[0]=copy;
        } else if(args[0] instanceof String && (args[0].equals(guest) || args[0].equals(BlackBoxCore.getHostPkg()))) {
            args[0]=caller;
        }
        return args;
    }
}

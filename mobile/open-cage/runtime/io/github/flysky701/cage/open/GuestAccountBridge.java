package io.github.flysky701.cage.open;

import android.accounts.AbstractAccountAuthenticator;
import android.app.Service;
import android.content.ContentProvider;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Binder;
import android.os.Bundle;
import android.os.IBinder;
import java.lang.reflect.Field;
import top.niunaijun.blackbox.BlackBoxCore;
import top.niunaijun.blackbox.core.system.accounts.BAccountManagerService;

/** Authenticate only the live account service of this Cage instance. */
public final class GuestAccountBridge {
    public static final String METHOD = "cage_account_peer";
    private static volatile Peer peer;
    private static final class Peer {
        final int pid, uid;
        final IBinder service;
        Peer(int pid, int uid, IBinder service) { this.pid=pid; this.uid=uid; this.service=service; }
    }
    private GuestAccountBridge() {}
    public static Bundle identify(ContentProvider provider, String argument, Bundle extras) {
        if (argument != null || extras != null || Binder.getCallingUid() != BlackBoxCore.getHostUid())
            throw new SecurityException("Private account service caller required");
        Bundle answer = new Bundle();
        answer.putInt("pid", android.os.Process.myPid());
        answer.putBinder("service", BAccountManagerService.get().asBinder());
        return answer;
    }
    public static boolean isServerCaller(int pid, int uid) {
        Peer expected=peer;
        return expected != null && pid == expected.pid && uid == expected.uid
                && expected.service.isBinderAlive();
    }
    public static void serviceCreated(Service service) {
        if (android.os.Build.VERSION.SDK_INT < 36
                || !"org.microg.gms.auth.loginservice.GoogleLoginService".equals(service.getClass().getName())) return;
        try {
            Context host=BlackBoxCore.getContext();
            Bundle identity=host.getContentResolver().call(Uri.parse("content://"+BlackBoxCore.getHostPkg()+".blackbox.SystemCallProvider"),METHOD,null,null);
            if (identity == null || identity.getInt("pid") <= 0 || identity.getBinder("service") == null)
                throw new IllegalStateException("Account service unavailable");
            peer=new Peer(identity.getInt("pid"),BlackBoxCore.getHostUid(),identity.getBinder("service"));
            Field authenticator=service.getClass().getDeclaredField("authenticator");
            authenticator.setAccessible(true);
            IBinder transport=((AbstractAccountAuthenticator)authenticator.get(service)).getIBinder();
            Context context=new ContextWrapper(service) {
                @Override public int checkPermission(String permission,int pid,int uid) {
                    if ("android.permission.ACCOUNT_MANAGER".equals(permission))
                        return isServerCaller(pid,uid) && Binder.getCallingPid()==pid
                                ? PackageManager.PERMISSION_GRANTED : PackageManager.PERMISSION_DENIED;
                    return super.checkPermission(permission,pid,uid);
                }
            };
            Object enforcer=Class.forName("android.os.PermissionEnforcer").getConstructor(Context.class).newInstance(context);
            Field target=Class.forName("android.accounts.IAccountAuthenticator$Stub").getDeclaredField("mEnforcer");
            target.setAccessible(true); target.set(transport,enforcer);
            android.util.Log.i("CageAccountBridge","Private authenticator ready");
        } catch (ReflectiveOperationException unavailable) {
            throw new IllegalStateException("Private authenticator unavailable",unavailable);
        }
    }
}

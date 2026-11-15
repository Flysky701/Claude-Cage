package io.github.flysky701.cage.open;

import android.app.Application;
import android.content.Context;
import top.niunaijun.blackbox.BlackBoxCore;
import top.niunaijun.blackbox.app.configuration.ClientConfiguration;

/** Independent source-built host. No access to the existing Cage/GBox data. */
public final class CageApplication extends Application {
    @Override protected void attachBaseContext(Context base) {
        super.attachBaseContext(base);
        BlackBoxCore.get().doAttachBaseContext(base, new ClientConfiguration() {
            @Override public String getHostPackageName() { return base.getPackageName(); }
            @Override public boolean isEnableDaemonService() { return false; }
            @Override public boolean isEnableLauncherActivity() { return false; }
            @Override public boolean isUseVpnNetwork() { return false; }
            @Override public String getLogSenderChatId() { return null; }
        });
    }
    @Override public void onCreate() {
        super.onCreate();
        BlackBoxCore.get().doCreate();
    }
}

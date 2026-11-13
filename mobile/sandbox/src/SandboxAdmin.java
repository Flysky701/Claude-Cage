package io.github.leexeo.cage.sandbox;

import android.app.admin.DeviceAdminReceiver;
import android.app.admin.DevicePolicyManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;

public final class SandboxAdmin extends DeviceAdminReceiver {
    @Override public void onProfileProvisioningComplete(Context context, Intent intent) {
        DevicePolicyManager policy = context.getSystemService(DevicePolicyManager.class);
        ComponentName admin = new ComponentName(context, SandboxAdmin.class);
        policy.setProfileName(admin, "Cage 测试空间");
        policy.setProfileEnabled(admin);
    }
}

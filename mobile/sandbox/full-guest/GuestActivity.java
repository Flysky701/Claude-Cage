package io.github.leexeo.cage.fullguest;
import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.widget.TextView;
import com.max2idea.android.limbo.jni.VMExecutor;
import java.io.*;
import java.nio.file.Files;
import java.util.*;

public final class GuestActivity extends Activity {
    private static boolean launched;
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        TextView status = new TextView(this);
        status.setText("正在启动隔离的 Android-x86 内核。");
        setContentView(status);
        if (launched) return;
        launched=true;
        new Thread(() -> {
            try {
                File dir=getFilesDir();
                File bios = new File(dir, "roms");
                if(!bios.isDirectory() && !bios.mkdir())throw new IOException("roms");
                for (String name:getAssets().list("bootrom")) {
                    File file=new File(bios,name);
                    if (!file.isFile()) try(InputStream in=getAssets().open("bootrom/"+name)){ Files.copy(in,file.toPath()); }
                }
                String nativeDir=getApplicationInfo().nativeLibraryDir;
                List<String> args=new ArrayList<>(Arrays.asList("qemu-system-x86_64","-L",bios.toString(),"-machine","pc,accel=tcg",
                        "-cpu","qemu64","-smp","2","-m","768","-nodefaults","-no-user-config","-display","none",
                        "-monitor","none","-serial","file:"+new File(dir,"serial.log"),"-no-reboot",
                        "-kernel",new File(dir,"kernel").toString(),"-initrd",new File(dir,"test-initrd.gz").toString(),
                        "-append","console=ttyS0,115200 earlyprintk=serial rdinit=/cage-check androidboot.hardware=android_x86_64 panic=-1"));
                int fd=FrameBackend.start(new File(dir,"backend.yaml").toString());
                args.addAll(Arrays.asList("-netdev","socket,id=cage,fd="+fd,"-device","e1000,mac=52:54:00:23:35:02,netdev=cage"));
                String r=new VMExecutor().start(dir.toString(),dir.toString(),"libqemu-system-x86_64.so",
                        nativeDir+"/libqemu-system-x86_64.so",0,args.toArray(new String[0]));
                Log.i("CageGuestBoot","VM returned: "+r);
            } catch (Exception|LinkageError ex) { Log.e("CageGuestBoot","VM startup failed",ex); }
        },"Cage-guest-vcpu").start();
    }
}

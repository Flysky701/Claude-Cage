package io.github.leexeo.cage.fullguest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;
import android.view.WindowManager;
import android.widget.*;
import com.max2idea.android.limbo.jni.VMExecutor;
import java.io.*;
import java.nio.file.Files;
import java.util.*;

public final class GuestActivity extends Activity {
    private static volatile boolean launched;
    private static final String RELAY="io.github.leexeo.cage.microcore";
    private TextView status;
    private boolean desktop;
    private void installRoms(String asset,File directory) throws IOException {
        if(!directory.isDirectory() && !directory.mkdirs()) throw new IOException("ROM directory");
        for(String name:getAssets().list(asset)){
            String child=asset+"/"+name;
            File target=new File(directory,name);
            if(getAssets().list(child).length>0) installRoms(child,target);
            else if(!target.isFile()) try(InputStream in=getAssets().open(child)){Files.copy(in,target.toPath());}
        }
    }
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        status = new TextView(this);
        File dir=getFilesDir();
        desktop=new File(dir,"system.iso").isFile();
        if(desktop && !launched){
            status.setText("正在准备空间网关…");
            setContentView(status);
            if(state!=null && state.getBoolean("waiting")) return;
            try {
                if(getPackageManager().checkSignatures(getPackageName(),RELAY)!=PackageManager.SIGNATURE_MATCH)
                    throw new IllegalStateException("matching gateway helper missing");
                startActivityForResult(new Intent("io.github.leexeo.cage.fullguest.PREPARE_NETWORK")
                        .setClassName(RELAY,"io.github.leexeo.cage.localcore.CoreActivity"),1);
            } catch(RuntimeException missing){
                status.setText("请先安装配套的 Cage microG 代理助手，然后重新打开空间。");
            }
            return;
        }
        startGuest();
    }
    @Override protected void onSaveInstanceState(Bundle state) {
        super.onSaveInstanceState(state);
        state.putBoolean("waiting",desktop && !launched);
    }
    @Override protected void onActivityResult(int request,int result,Intent data){
        super.onActivityResult(request,result,data);
        if(request!=1)return;
        String password=data==null ? null : data.getStringExtra("loopbackPassword");
        if(result!=RESULT_OK || password==null || !password.matches("[a-f0-9-]{36}")) {
            status.setText("空间网关尚未就绪。启动配套代理助手后可重新打开空间。");
            return;
        }
        try {
            String config="tunnel:\n  mtu: 1500\nsocks5:\n  address: 127.0.0.1\n  port: 29462\n"
                    +"  username: cage\n  password: '"+password+"'\n  udp: 'udp'\nmapdns:\n"
                    +"  address: 10.73.0.53\n  port: 53\n  network: 198.18.0.0\n  netmask: 255.254.0.0\n  cache-size: 1024\n"
                    +"misc:\n  log-level: error\n  connect-timeout: 4000\n";
            File file=new File(getFilesDir(),"backend.yaml");
            Files.write(file.toPath(),config.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        } catch(IOException failure){status.setText("无法保存来宾网关配置。");return;}
        startGuest();
    }
    private void startGuest(){
        File dir=getFilesDir();
        if(desktop) {
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            LinearLayout screen=new LinearLayout(this);
            screen.setOrientation(LinearLayout.VERTICAL);
            GuestDisplay viewer=new GuestDisplay(this,new File(dir,"display.sock"));
            screen.addView(viewer,new LinearLayout.LayoutParams(-1,0,1));
            LinearLayout tools=new LinearLayout(this);
            Button back=new Button(this);back.setText("来宾返回");tools.addView(back);
            back.setOnClickListener(v->{viewer.key(0xff1b,true);viewer.key(0xff1b,false);});
            Button keyboard=new Button(this);keyboard.setText("键盘");tools.addView(keyboard);
            keyboard.setOnClickListener(v->viewer.keyboard());
            screen.addView(tools);
            setContentView(screen);
        } else {
            status.setText("正在启动隔离的 Android-x86 内核。");
            setContentView(status);
        }
        if (launched) return;
        launched=true;
        new Thread(() -> {
            try {
                File bios = new File(dir, "roms");
                installRoms("bootrom",bios);
                String nativeDir=getApplicationInfo().nativeLibraryDir;
                List<String> args=new ArrayList<>(Arrays.asList("qemu-system-x86_64","-L",bios.toString(),
                        "-machine","pc,accel=tcg","-cpu",desktop ? "max" : "qemu64","-smp",desktop ? "4" : "2","-m",desktop ? "2560" : "768",
                        "-nodefaults","-no-user-config","-display","none","-monitor","none",
                        "-serial","file:"+new File(dir,desktop ? "android-boot.log" : "serial.log"),"-no-reboot"));
                if(desktop) {
                    // The VNC console is a filesystem socket inside this app's private directory.
                    File display=new File(dir,"display.sock");
                    if(display.exists() && !display.delete())throw new IOException("display socket");
                    args.addAll(Arrays.asList("-rtc","base=utc","-device","virtio-vga","-device","virtio-rng-pci","-device","ich9-intel-hda",
                            "-audiodev","none,id=guest-audio","-device","hda-duplex,audiodev=guest-audio","-vnc","unix:"+display,
                            "-device","usb-ehci,id=usb","-device","usb-tablet,bus=usb.0",
                            "-drive","file="+new File(dir,"system.iso")+",format=raw,media=cdrom,readonly=on,if=ide,index=2",
                            "-drive","file="+new File(dir,"userdata.img")+",format=raw,if=ide,index=0",
                            "-kernel",new File(dir,"android-kernel").toString(),"-initrd",new File(dir,"android-initrd.img").toString(),
                            "-append","root=/dev/ram0 console=tty0 console=ttyS0,115200 SRC= DATA=sda ROOT=/dev/sr0 "
                                    +"HWC=drm_minigbm GRALLOC=minigbm_arcvm video=Virtual-1:1024x768 DPI=160 SETUPWIZARD=0"));
                } else {
                    args.addAll(Arrays.asList("-kernel",new File(dir,"kernel").toString(),"-initrd",new File(dir,"test-initrd.gz").toString(),
                            "-append","console=ttyS0,115200 earlyprintk=serial rdinit=/cage-check androidboot.hardware=android_x86_64 panic=-1"));
                }
                String config=new File(dir,"backend.yaml").toString();
                if(desktop) {
                    File link=new File(dir,"ethernet.sock");
                    FrameBackend.listen(config,link);
                    args.addAll(Arrays.asList("-netdev","stream,id=cage,server=off,addr.type=unix,addr.path="+link,
                            "-device","e1000,mac=52:54:00:23:35:02,netdev=cage"));
                    args.set(0,nativeDir+"/libcage_qemu.so");
                    File firmware=new File(dir,"android-roms");
                    if(firmware.isDirectory())args.set(2,firmware.toString());
                    ProcessBuilder process=new ProcessBuilder(args);
                    process.directory(dir);
                    process.environment().put("LD_LIBRARY_PATH",new File(dir,"engine-lib").toString()+":"+nativeDir);
                    process.redirectErrorStream(true).redirectOutput(new File(dir,"engine.log"));
                    int code=process.start().waitFor();
                    if(code!=0)throw new IOException("QEMU exit "+code);
                    launched=false;
                } else {
                    int fd=FrameBackend.start(config);
                    args.addAll(Arrays.asList("-netdev","socket,id=cage,fd="+fd,"-device","e1000,mac=52:54:00:23:35:02,netdev=cage"));
                    String r=new VMExecutor().start(dir.toString(),dir.toString(),"libqemu-system-x86_64.so",
                            nativeDir+"/libqemu-system-x86_64.so",0,args.toArray(new String[0]));
                    Log.i("CageGuestBoot","VM returned: "+r);
                }
            } catch (Exception|LinkageError ex) {
                Log.e("CageGuestBoot","VM startup failed",ex);
                launched=false;
                runOnUiThread(()->{status.setText("来宾启动失败，请检查系统镜像和本地网关配置。");setContentView(status);});
            }
        },"Cage-guest-vcpu").start();
    }
}

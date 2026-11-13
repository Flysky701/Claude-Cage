package io.github.leexeo.cage.fullguest;

import android.os.ParcelFileDescriptor;
import android.system.Os;
import android.system.OsConstants;
import android.util.Log;
import hev.htproxy.TProxyService;
import java.io.*;
import java.util.Arrays;

/** Single QEMU Ethernet port. Static IPv4 guest; DNS is answered by HEV's mapped resolver. */
final class FrameBackend {
    private static final byte[] GUEST={0x52,0x54,0,0x23,0x35,2};
    private static final byte[] ROUTER={0x52,0x54,0,0x23,0x35,1};
    private final FileDescriptor packets=new FileDescriptor();
    private final DataInputStream ethernetIn;
    private final DataOutputStream ethernetOut;
    private final int qemuFd;
    private FrameBackend(String config) throws Exception {
        ParcelFileDescriptor[] ethernet=ParcelFileDescriptor.createSocketPair();
        qemuFd=ethernet[0].detachFd();
        ethernetIn=new DataInputStream(new ParcelFileDescriptor.AutoCloseInputStream(ethernet[1].dup()));
        ethernetOut=new DataOutputStream(new ParcelFileDescriptor.AutoCloseOutputStream(ethernet[1]));
        FileDescriptor peer=new FileDescriptor();
        Os.socketpair(OsConstants.AF_UNIX,OsConstants.SOCK_DGRAM,0,packets,peer);
        int backendFd=ParcelFileDescriptor.dup(peer).detachFd();
        Os.close(peer);
        if(!TProxyService.TProxyStartService(config,backendFd))throw new IOException("HEV initialization failed");
    }
    static int start(String config) throws Exception {
        FrameBackend b=new FrameBackend(config);
        new Thread(b::fromGuest,"Cage-ethernet-in").start();
        new Thread(b::toGuest,"Cage-ethernet-out").start();
        return b.qemuFd;
    }
    private synchronized void frame(byte[] bytes,int size) throws IOException {
        ethernetOut.writeInt(size);
        ethernetOut.write(bytes,0,size);
        ethernetOut.flush();
    }
    private static boolean addr(byte[] b,int off,int last) {
        return b[off]==10 && b[off+1]==73 && b[off+2]==0 && (b[off+3]&255)==last;
    }
    private void arp(byte[] f) throws IOException {
        if(f.length<42 || f[14]!=0 || f[15]!=1 || f[16]!=8 || f[17]!=0 || f[18]!=6 || f[19]!=4
                || f[20]!=0 || f[21]!=1 || !(addr(f,38,1)||addr(f,38,53)))return;
        byte[] r=Arrays.copyOf(f,42);
        System.arraycopy(GUEST,0,r,0,6); System.arraycopy(ROUTER,0,r,6,6); r[21]=2;
        System.arraycopy(ROUTER,0,r,22,6); System.arraycopy(f,38,r,28,4);
        System.arraycopy(GUEST,0,r,32,6); System.arraycopy(f,28,r,38,4);
        frame(r,r.length);
    }
    private void fromGuest(){
        try {
            long tcp=0,dns=0;
            for(;;){
                int len=ethernetIn.readInt();
                if(len<14 || len>65550)throw new IOException("invalid Ethernet length");
                byte[] f=new byte[len]; ethernetIn.readFully(f);
                if(f[12]==8 && f[13]==6){arp(f);continue;}
                if(f[12]!=8 || f[13]!=0 || len<34 || (f[14]&0xf0)!=0x40 || !addr(f,26,2))continue;
                int end=14+((f[16]&255)<<8)+(f[17]&255);
                int l4=14+4*(f[14]&15);
                if(l4<34 || end<l4+4 || end>len || (f[20]&0x3f)!=0 || f[21]!=0)continue;
                if(f[23]==6){if(++tcp==1)Log.i("CageGuestNet","first guest TCP");}
                else if(f[23]==17 && addr(f,30,53) && f[l4+2]==0 && f[l4+3]==53){
                    if(++dns==1)Log.i("CageGuestNet","first mapped DNS");
                } else continue;
                Os.write(packets,f,14,end-14);
            }
        } catch(Exception end){Log.i("CageGuestNet","Ethernet input stopped: "+end.getClass().getSimpleName());}
    }
    private void toGuest(){
        try {
            byte[] f=new byte[65550];
            System.arraycopy(GUEST,0,f,0,6); System.arraycopy(ROUTER,0,f,6,6); f[12]=8;
            for(;;){
                int n=Os.read(packets,f,14,f.length-14);
                if(n<=0)break;
                if((f[14]&0xf0)==0x40)frame(f,n+14);
            }
        } catch(Exception end){Log.i("CageGuestNet","Ethernet output stopped: "+end.getClass().getSimpleName());}
    }
}

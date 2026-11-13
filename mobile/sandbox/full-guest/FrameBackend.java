package io.github.leexeo.cage.fullguest;

import android.os.ParcelFileDescriptor;
import android.net.LocalServerSocket;
import android.net.LocalSocket;
import android.net.LocalSocketAddress;
import android.system.Os;
import android.system.OsConstants;
import android.util.Log;
import hev.htproxy.TProxyService;
import java.io.*;
import java.util.Arrays;

/** The guest has one Ethernet port. Android learns its route and mapped DNS via DHCP. */
final class FrameBackend {
    private static final byte[] GUEST={0x52,0x54,0,0x23,0x35,2};
    private static final byte[] ROUTER={0x52,0x54,0,0x23,0x35,1};
    private final FileDescriptor packets;
    private final boolean allowUdp;
    private final DataInputStream ethernetIn;
    private final DataOutputStream ethernetOut;
    private static FileDescriptor startTunnel(String config) throws Exception {
        FileDescriptor packets=new FileDescriptor();
        FileDescriptor peer=new FileDescriptor();
        Os.socketpair(OsConstants.AF_UNIX,OsConstants.SOCK_DGRAM,0,packets,peer);
        int backendFd=ParcelFileDescriptor.dup(peer).detachFd();
        Os.close(peer);
        if(!TProxyService.TProxyStartService(config,backendFd))throw new IOException("HEV initialization failed");
        return packets;
    }
    private FrameBackend(FileDescriptor packets,InputStream in,OutputStream out,boolean allowUdp) {
        this.packets=packets;
        this.allowUdp=allowUdp;
        ethernetIn=new DataInputStream(in);
        ethernetOut=new DataOutputStream(out);
    }
    private void pump() {
        new Thread(this::fromGuest,"Cage-ethernet-in").start();
        new Thread(this::toGuest,"Cage-ethernet-out").start();
    }
    static int start(String config) throws Exception {
        FileDescriptor tunnel=startTunnel(config);
        ParcelFileDescriptor[] ethernet=ParcelFileDescriptor.createSocketPair();
        new FrameBackend(tunnel,new ParcelFileDescriptor.AutoCloseInputStream(ethernet[1].dup()),
                new ParcelFileDescriptor.AutoCloseOutputStream(ethernet[1]),false).pump();
        return ethernet[0].detachFd();
    }
    static void listen(String config,File path) throws Exception {
        FileDescriptor tunnel=startTunnel(config);
        if(path.exists() && !path.delete())throw new IOException("stale Ethernet socket");
        LocalSocket owner=new LocalSocket();
        owner.bind(new LocalSocketAddress(path.toString(),LocalSocketAddress.Namespace.FILESYSTEM));
        LocalServerSocket server=new LocalServerSocket(owner.getFileDescriptor());
        Os.chmod(path.toString(),0600);
        new Thread(()->{
            try {
                for(;;) {
                    LocalSocket client=server.accept();
                    if(client.getPeerCredentials().getUid()!=android.os.Process.myUid()){client.close();continue;}
                    new FrameBackend(tunnel,client.getInputStream(),client.getOutputStream(),true).pump();
                    break;
                }
            } catch(IOException end){Log.w("CageGuestNet","Ethernet connection failed",end);}
            finally {try{owner.close();}catch(IOException ignored){}}
        },"Cage-ethernet-accept").start();
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
    private static int u16(byte[] packet, int offset) {
        return (packet[offset] & 255) << 8 | (packet[offset + 1] & 255);
    }
    private static void put16(byte[] packet, int offset, int value) {
        packet[offset] = (byte)(value >>> 8);
        packet[offset + 1] = (byte)value;
    }
    private static void address(byte[] packet, int offset, int last) {
        packet[offset] = 10; packet[offset + 1] = 73; packet[offset + 2] = 0; packet[offset + 3] = (byte)last;
    }
    private void dhcp(byte[] request, int udp, int end) throws IOException {
        int boot = udp + 8;
        if (end < boot + 240 || u16(request, udp + 4) != end - udp
                || request[boot] != 1 || request[boot + 1] != 1 || request[boot + 2] != 6
                || request[boot+236] != 99 || request[boot+237] != (byte)130
                || request[boot+238] != 83 || request[boot+239] != 99) return;
        for (int i=0;i<GUEST.length;i++) if(request[boot+28+i]!=GUEST[i]) return;
        int message = 0;
        boolean requestedLease = true;
        for (int pos=boot+240; pos<end;) {
            int option=request[pos++] & 255;
            if (option==255) break;
            if (option==0) continue;
            if (pos>=end) return;
            int length=request[pos++] & 255;
            if (pos+length>end) return;
            if (option==53 && length==1) message=request[pos] & 255;
            if (option==54 && (length!=4 || !addr(request,pos,1))) return;
            if (option==50) requestedLease = length==4 && addr(request,pos,2);
            pos+=length;
        }
        if (message!=1 && message!=3) return;
        boolean nak = message==3 && !requestedLease;
        if(message==3 && !addr(request,boot+12,2) && u16(request,boot+12)+u16(request,boot+14)!=0) nak=true;
        byte[] reply=new byte[342];
        Arrays.fill(reply,0,6,(byte)255);
        System.arraycopy(ROUTER,0,reply,6,6);
        reply[12]=8;
        int ip=14, datagram=34, data=42;
        reply[ip]=0x45; put16(reply,ip+2,reply.length-ip); reply[ip+8]=64; reply[ip+9]=17;
        address(reply,ip+12,1); Arrays.fill(reply,ip+16,ip+20,(byte)255);
        int sum=0;
        for(int i=ip;i<datagram;i+=2) sum+=u16(reply,i);
        while ((sum >>> 16)!=0) sum=(sum & 65535)+(sum >>> 16);
        put16(reply,ip+10,~sum);
        put16(reply,datagram,67); put16(reply,datagram+2,68); put16(reply,datagram+4,reply.length-datagram);
        reply[data]=2; reply[data+1]=1; reply[data+2]=6;
        System.arraycopy(request,boot+4,reply,data+4,4);
        System.arraycopy(request,boot+10,reply,data+10,2);
        if(!nak) address(reply,data+16,2);
        address(reply,data+20,1);
        System.arraycopy(GUEST,0,reply,data+28,6);
        System.arraycopy(request,boot+236,reply,data+236,4);
        byte[] options={53,1,(byte)(nak?6:message==1?2:5),54,4,10,73,0,1,
                1,4,(byte)255,(byte)255,(byte)255,0,3,4,10,73,0,1,6,4,10,73,0,53,
                51,4,0,1,81,(byte)128,(byte)255};
        if(nak) options=Arrays.copyOf(options,10);
        options[options.length-1]=(byte)255;
        System.arraycopy(options,0,reply,data+240,options.length);
        frame(reply,reply.length);
        if(message==3 && !nak)Log.i("CageGuestNet","guest DHCP lease acknowledged");
    }
    private static boolean localDestination(byte[] packet) {
        int first=packet[30]&255,second=packet[31]&255,third=packet[32]&255;
        return first==0 || first==10 || first==127 || first>=224
                || (first==169 && second==254) || (first==172 && second>=16 && second<32)
                || (first==192 && second==168) || (first==100 && second>=64 && second<128)
                || (first==192 && second==0 && third==0);
    }
    private void fromGuest(){
        try {
            long tcp=0,dns=0;
            for(;;){
                int len=ethernetIn.readInt();
                if(len<14 || len>65550)throw new IOException("invalid Ethernet length");
                byte[] f=new byte[len]; ethernetIn.readFully(f);
                if(f[12]==8 && f[13]==6){arp(f);continue;}
                if(f[12]!=8 || f[13]!=0 || len<34 || (f[14]&0xf0)!=0x40)continue;
                int end=14+((f[16]&255)<<8)+(f[17]&255);
                int l4=14+4*(f[14]&15);
                if(l4<34 || end<l4+4 || end>len || (f[20]&0x3f)!=0 || f[21]!=0)continue;
                if(f[23]==17 && (end<l4+8 || u16(f,l4+4)!=end-l4))continue;
                if(f[23]==6 && end<l4+20)continue;
                if(f[23]==17 && u16(f,l4)==68 && u16(f,l4+2)==67){dhcp(f,l4,end);continue;}
                if(!addr(f,26,2))continue;
                boolean mappedDns=f[23]==17 && addr(f,30,53) && u16(f,l4+2)==53;
                if(!mappedDns && localDestination(f))continue;
                if(f[23]==6){if(++tcp==1)Log.i("CageGuestNet","first guest TCP");}
                else if(mappedDns){
                    if(++dns==1)Log.i("CageGuestNet","first mapped DNS");
                } else if(f[23]!=17 || !allowUdp)continue;
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

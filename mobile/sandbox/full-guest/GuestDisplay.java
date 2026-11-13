package io.github.leexeo.cage.fullguest;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.net.LocalSocket;
import android.net.LocalSocketAddress;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputMethodManager;
import java.io.*;
import java.util.Arrays;

/** RFB viewer for the single guest's private Unix socket. No TCP listener or host networking here. */
final class GuestDisplay extends View {
    private final File path;
    private final Paint paint=new Paint(Paint.FILTER_BITMAP_FLAG | Paint.ANTI_ALIAS_FLAG);
    private final RectF viewport=new RectF();
    private final Object pixels=new Object();
    private volatile LocalSocket connection;
    private volatile boolean attached;
    private DataOutputStream output;
    private Bitmap image;
    private int width,height;
    private String status="正在启动独立 Android 空间…";

    GuestDisplay(Context context, File path) {
        super(context);
        this.path=path;
        setFocusableInTouchMode(true);
        setContentDescription("独立 Android 空间");
    }
    @Override protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        attached=true;
        new Thread(this::connect,"Cage-display").start();
    }
    @Override protected void onDetachedFromWindow() {
        attached=false;
        LocalSocket s=connection;
        if(s!=null) try{s.close();}catch(IOException ignored){}
        super.onDetachedFromWindow();
    }
    private void connect() {
        while(attached) {
            try(LocalSocket s=new LocalSocket()) {
                connection=s;
                s.connect(new LocalSocketAddress(path.toString(),LocalSocketAddress.Namespace.FILESYSTEM));
                if(s.getPeerCredentials().getUid()!=android.os.Process.myUid())throw new IOException("unexpected display owner");
                receive(new DataInputStream(new BufferedInputStream(s.getInputStream(),65536)),new DataOutputStream(s.getOutputStream()));
            } catch(IOException ex) {
                post(()->{status="正在连接来宾显示…";invalidate();});
            } finally {
                connection=null;
                synchronized(this){output=null;}
            }
            if(attached) try{Thread.sleep(650);}catch(InterruptedException stop){return;}
        }
    }
    private void size(int w,int h) throws IOException {
        if(w<1 || h<1 || w>4096 || h>4096 || (long)w*h>8_000_000)throw new IOException("display size");
        synchronized(pixels){width=w;height=h;image=Bitmap.createBitmap(w,h,Bitmap.Config.RGB_565);}
    }
    private void receive(DataInputStream in,DataOutputStream out) throws IOException {
        byte[] version=new byte[12]; in.readFully(version);
        if(!Arrays.equals(version,"RFB 003.008\n".getBytes("US-ASCII")))throw new IOException("RFB version");
        out.write(version);
        int types=in.readUnsignedByte();boolean local=false;
        for(int i=0;i<types;i++) if(in.readUnsignedByte()==1)local=true;
        if(!local)throw new IOException("local display unavailable");
        out.writeByte(1);if(in.readInt()!=0)throw new IOException("RFB security");
        out.writeByte(1);
        size(in.readUnsignedShort(),in.readUnsignedShort());
        byte[] format=new byte[16];in.readFully(format);
        int name=in.readInt();if(name<0||name>4096)throw new IOException("display name");in.readFully(new byte[name]);
        // SetPixelFormat, 32-bit little-endian true colour (B, G, R, padding).
        out.write(new byte[]{0,0,0,0,32,24,0,1,0,(byte)255,0,(byte)255,0,(byte)255,16,8,0,0,0,0});
        out.write(new byte[]{2,0,0,2});out.writeInt(0);out.writeInt(-223);
        synchronized(this){output=out;request(false);}
        while(attached) {
            int message=in.readUnsignedByte();
            if(message==2)continue;
            if(message==3){
                in.readFully(new byte[3]);int count=in.readInt();
                if(count<0 || count>1024*1024)throw new IOException("clipboard size");
                while(count>0){int n=in.skipBytes(count);if(n==0){in.readByte();n=1;}count-=n;}
                continue;
            }
            if(message!=0)throw new IOException("display message");
            in.readByte();int rectangles=in.readUnsignedShort();boolean resized=false;
            for(int i=0;i<rectangles;i++) {
                int x=in.readUnsignedShort(),y=in.readUnsignedShort(),w=in.readUnsignedShort(),h=in.readUnsignedShort();
                int encoding=in.readInt();
                if(encoding==-223){size(w,h);resized=true;continue;}
                if(encoding!=0 || x+w>width || y+h>height)throw new IOException("display rectangle");
                if(w==0||h==0)continue;
                byte[] row=new byte[w*4];int[] colors=new int[w];
                for(int j=0;j<h;j++){
                    in.readFully(row);
                    for(int k=0;k<w;k++)colors[k]=Color.rgb(row[k*4+2]&255,row[k*4+1]&255,row[k*4]&255);
                    synchronized(pixels){image.setPixels(colors,0,w,x,y+j,w,1);}
                }
            }
            postInvalidateOnAnimation();request(!resized);
        }
    }
    private synchronized void request(boolean incremental) throws IOException {
        if(output==null)return;
        output.writeByte(3);output.writeByte(incremental?1:0);output.writeShort(0);output.writeShort(0);
        output.writeShort(width);output.writeShort(height);
    }
    @Override protected void onDraw(Canvas c) {
        c.drawColor(Color.BLACK);
        synchronized(pixels){
            if(image!=null){
                float scale=Math.min((float)getWidth()/width,(float)getHeight()/height);
                float w=scale*width,h=scale*height;
                viewport.set((getWidth()-w)/2,(getHeight()-h)/2,(getWidth()+w)/2,(getHeight()+h)/2);
                c.drawBitmap(image,null,viewport,paint);return;
            }
        }
        paint.setColor(Color.WHITE);paint.setTextSize(17*getResources().getDisplayMetrics().scaledDensity);
        c.drawText(status,24,getHeight()/2f,paint);
    }
    @Override public synchronized boolean onTouchEvent(MotionEvent event) {
        if(output==null || viewport.width()==0)return true;
        int action=event.getActionMasked();
        if(action==MotionEvent.ACTION_DOWN && !viewport.contains(event.getX(),event.getY()))return false;
        int x=Math.max(0,Math.min(width-1,(int)((event.getX()-viewport.left)*width/viewport.width())));
        int y=Math.max(0,Math.min(height-1,(int)((event.getY()-viewport.top)*height/viewport.height())));
        try {
            output.writeByte(5);output.writeByte(action==MotionEvent.ACTION_UP || action==MotionEvent.ACTION_CANCEL?0:1);
            output.writeShort(x);output.writeShort(y);
        } catch(IOException ignored){}
        if(action==MotionEvent.ACTION_UP)performClick();
        return true;
    }
    @Override public boolean performClick(){super.performClick();requestFocus();return true;}
    synchronized void key(int code,boolean down) {
        if(output==null)return;
        try {output.writeByte(4);output.writeByte(down?1:0);output.writeShort(0);output.writeInt(code);}
        catch(IOException ignored){}
    }
    private void stroke(int code){key(code,true);key(code,false);}
    void keyboard(){
        requestFocus();((InputMethodManager)getContext().getSystemService(Context.INPUT_METHOD_SERVICE)).showSoftInput(this,InputMethodManager.SHOW_IMPLICIT);
    }
    @Override public boolean onCheckIsTextEditor(){return true;}
    @Override public InputConnection onCreateInputConnection(EditorInfo info){
        info.inputType=android.text.InputType.TYPE_CLASS_TEXT | android.text.InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS;
        info.imeOptions=EditorInfo.IME_ACTION_DONE|EditorInfo.IME_FLAG_NO_EXTRACT_UI|EditorInfo.IME_FLAG_NO_PERSONALIZED_LEARNING;
        return new BaseInputConnection(this,false){
            @Override public boolean commitText(CharSequence text,int cursor){
                for(int i=0;i<text.length();){int c=Character.codePointAt(text,i);stroke(c<256?c:0x01000000|c);i+=Character.charCount(c);}return true;
            }
            @Override public boolean deleteSurroundingText(int before,int after){
                for(int i=0;i<before;i++)stroke(0xff08);for(int i=0;i<after;i++)stroke(0xffff);return true;
            }
            @Override public boolean performEditorAction(int action){stroke(0xff0d);return true;}
            @Override public boolean sendKeyEvent(KeyEvent event){
                int k=event.getKeyCode(),symbol=k==KeyEvent.KEYCODE_DEL?0xff08:k==KeyEvent.KEYCODE_ENTER?0xff0d:event.getUnicodeChar();
                if(symbol!=0)key(symbol,event.getAction()==KeyEvent.ACTION_DOWN);return symbol!=0;
            }
        };
    }
}

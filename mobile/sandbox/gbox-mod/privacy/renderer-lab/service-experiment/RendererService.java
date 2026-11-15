package io.github.leexeo.cage.timezonelab;
import android.app.Service;
import android.content.*;
import android.os.IBinder;
import android.webkit.WebView;
import java.lang.reflect.*;
import java.util.TimeZone;

public final class RendererService extends Service {
 private Service delegate;
 private static native int initNative();
 @Override public void onCreate(){
  super.onCreate();
  try {
   if(android.os.Process.myUid()%100000 < 90000)throw new IllegalStateException("Isolated process required");
   android.util.Log.i("CageRendererLab","SERVICE_ISOLATED");
   TimeZone.setDefault(TimeZone.getTimeZone("Asia/Tokyo"));
   android.system.Os.setenv("TZ","Asia/Tokyo",true);
   System.loadLibrary("renderer_timezone");
   int nativeResult=initNative();
   android.util.Log.i("CageRendererLab","NATIVE_RESULT="+nativeResult);
   if(nativeResult!=1)throw new IllegalStateException("Native initialization failed");
   Class.forName("org.lsposed.hiddenapibypass.HiddenApiBypass")
     .getMethod("addHiddenApiExemptions",String[].class)
     .invoke(null,(Object)new String[]{"Landroid/app/Service;","Landroid/content/ContextWrapper;","Landroid/webkit/WebViewFactory;"});
   android.util.Log.i("CageRendererLab","BEFORE_PROVIDER");
   Method providerClass=Class.forName("android.webkit.WebViewFactory").getDeclaredMethod("getProviderClass");
   providerClass.setAccessible(true);
   ClassLoader loader=((Class<?>)providerClass.invoke(null)).getClassLoader();
   android.util.Log.i("CageRendererLab","PROVIDER_LOADED");
   delegate=(Service)Class.forName("org.chromium.content.app.SandboxedProcessService",true,loader)
     .getDeclaredConstructor().newInstance();
   for(Field field:Service.class.getDeclaredFields())if(!Modifier.isStatic(field.getModifiers())){
     field.setAccessible(true);field.set(delegate,field.get(this));
   }
   Field base=ContextWrapper.class.getDeclaredField("mBase");base.setAccessible(true);
   base.set(delegate,getBaseContext());
   delegate.onCreate();
   android.util.Log.i("CageRendererLab","DELEGATE_CREATED");
  }catch(Throwable e){
   android.util.Log.e("CageRendererLab","SERVICE_FAILED "+e.getClass().getSimpleName(),e);
   stopSelf();
  }
 }
 @Override public IBinder onBind(Intent intent){return delegate==null?null:delegate.onBind(intent);}
 @Override public void onDestroy(){if(delegate!=null)delegate.onDestroy();super.onDestroy();}
}

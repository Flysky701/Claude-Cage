package io.github.leexeo.cage.timezonelab;
import android.content.*;
import java.lang.reflect.*;
import java.util.concurrent.Executor;
import java.util.concurrent.atomic.AtomicInteger;

final class RendererRedirect extends ContextWrapper {
 static final AtomicInteger redirected=new AtomicInteger();
 RendererRedirect(Context base){super(base);}
 static void install(Object monitor) throws Exception {
  Class.forName("org.lsposed.hiddenapibypass.HiddenApiBypass")
    .getMethod("addHiddenApiExemptions",String[].class)
    .invoke(null,(Object)new String[]{"Landroid/content/ContextWrapper;"});
  Field base=ContextWrapper.class.getDeclaredField("mBase");base.setAccessible(true);
  base.set(monitor,new RendererRedirect((Context)base.get(monitor)));
 }
 @Override public boolean bindIsolatedService(Intent service,int flags,String instanceName,
     Executor executor,ServiceConnection connection){
  ComponentName target=service.getComponent();
  if(target==null || !"com.google.android.webview".equals(target.getPackageName())
       || !target.getClassName().startsWith("org.chromium.content.app.SandboxedProcessService"))
    return super.bindIsolatedService(service,flags,instanceName,executor,connection);
  redirected.incrementAndGet();
  android.util.Log.i("CageRendererLab","REDIRECT");
  Intent scoped=new Intent(service).setComponent(new ComponentName(getPackageName(),RendererService.class.getName()));
  return super.bindIsolatedService(scoped,flags,instanceName,executor,connection);
 }
}

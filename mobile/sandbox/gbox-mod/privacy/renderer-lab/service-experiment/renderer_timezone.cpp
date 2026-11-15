#include <jni.h>
#include <dlfcn.h>
#include <sys/system_properties.h>
#include <unistd.h>
#include <cstring>
#include <android/log.h>

using Callback = void(*)(void*,const char*,const char*,uint32_t);
static int (*original_get)(const char*,char*);
static int (*original_read)(const prop_info*,char*,char*);
static void (*original_callback)(const prop_info*,Callback,void*);
static bool ready;
static const char* zone="Asia/Tokyo";
static bool matches(const char* name){return ready && name && strcmp(name,"persist.sys.timezone")==0;}
static int replacement_get(const char* name,char* value){
 if(matches(name)){strcpy(value,zone);return 10;}
 return original_get(name,value);
}
static int replacement_read(const prop_info* info,char* name,char* value){
 int result=original_read(info,name,value);
 if(matches(name)){strcpy(value,zone);return 10;}
 return result;
}
struct State{Callback callback;void* opaque;};
static void callback(void* ptr,const char* name,const char* value,uint32_t serial){
 auto* state=static_cast<State*>(ptr);
 state->callback(state->opaque,name,matches(name)?zone:value,serial);
}
static void replacement_callback(const prop_info* info,Callback fn,void* opaque){
 State state{fn,opaque};original_callback(info,callback,&state);
}
extern "C" JNIEXPORT jint JNICALL
Java_io_github_leexeo_cage_timezonelab_RendererService_initNative(JNIEnv*,jclass){
 if(getuid()%100000<90000)return -1;
 char sdk[PROP_VALUE_MAX]{};__system_property_get("ro.build.version.sdk",sdk);
 if(strcmp(sdk,"36"))return -2;
 void* library=dlopen("libshadowhook.so",RTLD_NOW|RTLD_LOCAL);if(!library)return -3;
 auto init=reinterpret_cast<int(*)(int,bool)>(dlsym(library,"shadowhook_init"));
 auto version=reinterpret_cast<const char*(*)()>(dlsym(library,"shadowhook_get_version"));
 auto hook=reinterpret_cast<void*(*)(const char*,const char*,void*,void**)>(dlsym(library,"shadowhook_hook_sym_name"));
 if(!init||!version||!hook||strcmp(version(),"shadowhook version 2.0.1"))return -4;
 if(init(1,false))return -5;
 if(!hook("libc.so","__system_property_get",reinterpret_cast<void*>(replacement_get),reinterpret_cast<void**>(&original_get)))return -6;
 if(!hook("libc.so","__system_property_read",reinterpret_cast<void*>(replacement_read),reinterpret_cast<void**>(&original_read)))return -7;
 if(!hook("libc.so","__system_property_read_callback",reinterpret_cast<void*>(replacement_callback),reinterpret_cast<void**>(&original_callback)))return -8;
 ready=true;
 char value[PROP_VALUE_MAX]{};__system_property_get("persist.sys.timezone",value);
 return strcmp(value,zone)==0?1:-9;
}

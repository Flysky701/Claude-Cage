import com.sun.jdi.*;
import com.sun.jdi.connect.*;
import java.util.*;
public class FlagState {
 static final Set<String> KEYS=Set.of("claudeai_google_sign_in_credential_attestation","claudeai_sign_in_refusal_remedy","claudeai_sign_in_link_try_again","android_sign_in_resubmit_asks_play");
 static final Set<String> VALUES=Set.of("HOLDING_CONTROL","HOLDING_CONTROL_UNDER_MEASUREMENT","SERVER_MAY_REFUSE","DEFAULT","none","open_google_play","open_claude_ai","");
 static Value f(Value v,String n){if(!(v instanceof ObjectReference))return null;var o=(ObjectReference)v;var q=o.referenceType().fieldByName(n);return q==null?null:o.getValue(q);}
 static String s(Value v){return v instanceof StringReference?((StringReference)v).value():null;}
 static String safe(Value v){if(v==null)return "null";if(v instanceof BooleanValue)return Boolean.toString(((BooleanValue)v).value());String s=s(v);if(s!=null)return VALUES.contains(s)?s:"<other string>";if(v instanceof ObjectReference)return "<"+((ObjectReference)v).referenceType().name()+">";return "<other>";}
 public static void main(String[] args)throws Exception{
 var c=Bootstrap.virtualMachineManager().attachingConnectors().stream().filter(x->x.name().endsWith("SocketAttach")).findFirst().orElseThrow();var a=c.defaultArguments();a.get("hostname").setValue("127.0.0.1");a.get("port").setValue(args[0]);var vm=c.attach(a);
 try{ for(var t:vm.classesByName("k1m"))for(var o:t.instances(2)){var features=f(f(f(f(o,"f"),"value"),"a"),"a");System.out.println("FEATURES mapType="+safe(features)+" size="+(f(features,"size") instanceof IntegerValue?((IntegerValue)f(features,"size")).value():-1));}
  for(var t:vm.classesByName("f1m"))for(var o:t.instances(1000)){String key=s(f(o,"a"));if(!KEYS.contains(key==null?"":key))continue;var st=f(f(o,"f"),"value");System.out.println("FLAG "+key+" blocked="+safe(f(o,"c"))+" evaluatedBoolean="+safe(f(st,"e"))+" parsed="+safe(f(st,"g"))+" serverRecord="+(f(st,"c")!=null)+" override="+(f(st,"d")!=null));for(String n:List.of("c","d")){var v=f(f(st,n),"a");if(v instanceof ObjectReference && !(v instanceof StringReference)){for(var q:((ObjectReference)v).referenceType().fields())if(!q.isStatic()&&(q.typeName().equals("java.lang.String")||q.typeName().equals("boolean")))System.out.println("  source="+n+" jsonField="+q.name()+" value="+safe(((ObjectReference)v).getValue(q)));}}}
  for(var t:vm.classesByName("uny"))for(var o:t.instances(2)){var size=f(f(o,"c"),"c");System.out.println("LIMIT count="+(size instanceof IntegerValue?((IntegerValue)size).value():-1)+" blockedUntilPresent="+(f(o,"d")!=null));}
 }finally{vm.dispose();}
 }
}

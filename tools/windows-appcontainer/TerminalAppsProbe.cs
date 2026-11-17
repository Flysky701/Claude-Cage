// Independent executable entry for local development-terminal compatibility.
// Compile alongside Boundary* partials with /main:TerminalAppsEntry.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;

internal static class TerminalAppsEntry {
    static int Main(string[] args) {return BoundaryProbe.TerminalAppsMain(args);}
}
internal static partial class BoundaryProbe {
    static string PsQuote(string value) {return "'"+value.Replace("'","''")+"'";}
    static string[] TerminalAppsPowerShellArguments(string tools) {
        string bootstrap="$ErrorActionPreference='Stop'; New-PSDrive -Name Cage -PSProvider FileSystem -Root $env:HOME | Out-Null; New-PSDrive -Name CageTools -PSProvider FileSystem -Root "+PsQuote(tools)+" | Out-Null; Set-Location Cage:\\";
        return new[]{"-NoLogo","-NoProfile","-NoExit","-Command",bootstrap};
    }
    static Dictionary<string,string> TerminalAppsEnvironment(string app,string work) {
        var env=new Dictionary<string,string>();
        if(app=="ClaudeCode") {
            env["CLAUDE_CONFIG_DIR"]=Path.Combine(work,"claude-config");
            env["CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"]="1";
            env["DISABLE_TELEMETRY"]="1";env["DISABLE_ERROR_REPORTING"]="1";env["DISABLE_AUTOUPDATER"]="1";
        }
        if(app=="Git") {
            env["GIT_CONFIG_NOSYSTEM"]="1";env["GIT_CONFIG_GLOBAL"]=Path.Combine(work,"empty.gitconfig");
            env["GIT_TERMINAL_PROMPT"]="0";env["GIT_PAGER"]="cat";
        }
        return env;
    }
    static Dictionary<string,object> TerminalAppsSuite(string app,string fixture) {
        fixture=Path.GetFullPath(fixture);ValidateFixture(fixture);
        string tools=Path.Combine(fixture,"tools"),work=Path.Combine(fixture,"work");
        var result=new Dictionary<string,object>{{"app",app},{"mode","ac"},{"scope","offline local development terminal candidate"}};
        Session session=null;CandidateTerminal terminal=null;TerminalCapture capture=null;
        try {
            session=new Session("ac",fixture);
            string exe=Path.Combine(Environment.SystemDirectory,"cmd.exe");string[] args=new[]{"/d","/q"};
            if(app=="PowerShell") {
                exe=Path.Combine(Environment.SystemDirectory,"WindowsPowerShell","v1.0","powershell.exe");
                args=TerminalAppsPowerShellArguments(tools);
                result["powershellBootstrap"]="mount only granted work/tools PSDrives; no volume-root ACL change";
            }
            else if(app=="ClaudeCode") {exe=Path.Combine(tools,"claude.exe");args=new[]{"--setting-sources","user"};}
            else if(app=="Node") {
                exe=Path.Combine(tools,"node.exe");
                bool normalEntry=File.Exists(Path.Combine(work,"node-default-entry.fixture"));
                args=(normalEntry?new string[0]:new[]{"--preserve-symlinks-main","--preserve-symlinks"}).Concat(new[]{Path.Combine(work,"node-project","main.cjs"),tools}).ToArray();
                result["nodeEntry"]=normalEntry?"default file entry":"preserve-symlinks file entry";
            }
            else if(app!="Git")throw new InvalidDataException("terminal_app_invalid");
            terminal=new CandidateTerminal(session,exe,args,120,35,TerminalAppsEnvironment(app,work));
            foreach(var item in terminal.Receipt)result[item.Key]=item.Value;
            capture=new TerminalCapture(terminal,Path.Combine(fixture,"out","terminal-app.txt"));
            if(app=="PowerShell") {
                TerminalInput(terminal,"Write-Output ('CAGE_PS_' + 'READY')\r");
                TerminalRequire(result,"interactiveReady",capture.Contains("CAGE_PS_READY",12000));
                TerminalInput(terminal,"Write-Output ('CAGE_ZH:' + '中文输入回显')\r");
                TerminalRequire(result,"chineseInputOutputPassed",capture.Contains("CAGE_ZH:中文输入回显",6000));
                TerminalInput(terminal,"& 'CageTools:\\CompatibilityHelper.exe' token ac\r");
                TerminalRequire(result,"childSamePackagePassed",capture.Contains("CAGE_TOKEN_VERIFIED:ac:"+session.Sid,6000));
                TerminalInput(terminal,"& 'CageTools:\\TerminalWorker.exe' size\r");
                TerminalRequire(result,"initialSizePassed",capture.Contains("CAGE_CONSOLE_SIZE:120x35",6000));
                terminal.Resize(108,39);
                TerminalInput(terminal,"& 'CageTools:\\TerminalWorker.exe' size\r");
                TerminalRequire(result,"resizePassed",capture.Contains("CAGE_CONSOLE_SIZE:108x39",6000));
                TerminalInput(terminal,"& 'CageTools:\\TerminalWorker.exe' interrupt\r");
                TerminalRequire(result,"interruptWorkerReady",capture.Contains("CAGE_INTERRUPT_READY",6000));
                TerminalInput(terminal,"\x03");
                TerminalRequire(result,"ctrlCPassed",capture.Contains("CAGE_CTRL_C_RECEIVED",6000));
                TerminalInput(terminal,"Write-Output ('CAGE_PS_' + 'AFTER_INTERRUPT')\r");
                TerminalRequire(result,"inputAfterInterruptPassed",capture.Contains("CAGE_PS_AFTER_INTERRUPT",6000));
                TerminalInput(terminal,"exit 0\r");
            } else if(app=="ClaudeCode") {
                // No prompt is sent and the onboarding login step is never entered.
                bool rendered=capture.Contains("Welcome to Claude Code",10000) || capture.Contains("Choose the text style",2000) || capture.Contains("Select the text style",2000);
                TerminalRequire(result,"welcomeRendered",rendered);
                result["offlineGatewayFixture"]=File.Exists(Path.Combine(work,"claude-config","settings.json"));
                bool prompt=capture.Contains("Choose the text style",5000) || capture.Contains("Select the text style",1000) || capture.Contains("Choose a theme",1000);
                result["onboardingPromptRendered"]=prompt;
                result["connectivityFailureObserved"]=capture.Contains("Unable to connect to Anthropic services",200);
                if(!prompt)throw new InvalidDataException("claude_offline_onboarding_not_ready");
                terminal.Resize(108,39);result["resizeCallSucceeded"]=true;
                TerminalInput(terminal,"\x03");
                if(!terminal.Wait(1500))TerminalInput(terminal,"\x03");
                bool interrupted=terminal.Wait(1500);result["ctrlCExited"]=interrupted;
                if(!interrupted) {
                    // First-run theme selection does not honor Ctrl+C on this
                    // version. Closing the terminal must still reap its Job.
                    terminal.Stop();
                    TerminalRequire(result,"controlledClosePassed",terminal.Wait(5000));
                    result["exitPath"]="controller closed the terminal Job";
                } else result["exitPath"]="Ctrl+C";
                result["authenticationAttempted"]=false;result["modelRequestSent"]=false;
            } else if(app=="Node") {
                TerminalRequire(result,"localProjectPassed",capture.Contains("CAGE_NODE_LOCAL_PASS",12000));
                TerminalRequire(result,"childSamePackagePassed",capture.Contains("CAGE_TOKEN_VERIFIED:ac:"+session.Sid,3000));
            } else {
                string git=Quote(Path.Combine(tools,"git","git.exe"));
                TerminalInput(terminal,Quote(Path.Combine(tools,"TerminalAppsWorker.exe"))+"\r");
                TerminalRequire(result,"pathDiagnosticCompleted",capture.Contains("CAGE_PATH_DIAGNOSTIC_DONE",6000));
                // Configuration only refers to the disposable work tree. No
                // template hook, editor, pager or credential helper is invoked.
                string baseGit=git+" --no-pager -c core.autocrlf=false -c init.templateDir="+Quote(Path.Combine(work,"empty-templates"))+" -C "+Quote(Path.Combine(work,"git-project"));
                TerminalInput(terminal,baseGit+" init\r");
                TerminalRequire(result,"gitInitPassed",capture.Contains("Initialized empty Git repository",6000));
                TerminalInput(terminal,baseGit+" add sample.txt\r");
                TerminalInput(terminal,baseGit+" diff --cached --numstat\r");
                TerminalRequire(result,"gitAddDiffPassed",capture.Contains("1\t0\tsample.txt",6000));
                TerminalInput(terminal,baseGit+" status --porcelain\r");
                TerminalRequire(result,"gitStatusPassed",capture.Contains("A  sample.txt",6000));
                TerminalInput(terminal,Quote(Path.Combine(tools,"CompatibilityHelper.exe"))+" token ac\r");
                TerminalRequire(result,"shellChildSamePackagePassed",capture.Contains("CAGE_TOKEN_VERIFIED:ac:"+session.Sid,6000));
                TerminalInput(terminal,"exit 0\r");
            }
            TerminalRequire(result,"processExited",terminal.Wait(6000));result["exitCode"]=terminal.Wait();
            result["exitedWithoutForcedKill"]=!result.ContainsKey("controlledClosePassed");
        }catch(Exception ex){result["error"]=ex.GetType().Name+": "+ex.Message;}
        finally {
            if(terminal!=null){terminal.Stop();if(capture!=null){result["outputDrained"]=capture.Join(5000);if(capture.Error!=null)result["outputError"]=capture.Error;}terminal.Dispose();}
            if(session!=null){session.Dispose();result["profileDeleteResult"]=session.DeleteResult;}
        }
        result["passed"]=!result.ContainsKey("error") && !result.ContainsKey("outputError") && result.ContainsKey("outputDrained") && (bool)result["outputDrained"] && result.ContainsKey("exitCode") && (app=="ClaudeCode" || Convert.ToInt32(result["exitCode"])==0) && Convert.ToInt32(result["profileDeleteResult"])==0;
        Directory.CreateDirectory(fixture);Save(Path.Combine(fixture,"terminal-app-result.json"),result);return result;
    }
    internal static int TerminalAppsMain(string[] args) {
        try {
            if(args.Length==3 && args[0]=="app-suite") {var result=TerminalAppsSuite(args[1],args[2]);Console.WriteLine(new JavaScriptSerializer().Serialize(result));return (bool)result["passed"]?0:1;}
            if(args.Length==2 && args[0]=="path-diagnostic") {
                var result=new Dictionary<string,object>();Session session=null;
                try {
                    session=new Session("ac",args[1]);string exe=Path.Combine(session.Fixture,"tools","TerminalAppsWorker.exe");
                    File.Copy(Path.Combine(BuildRoot,"TerminalAppsWorker.exe"),exe);
                    result=Launch(session,exe,new string[0],8,"path-diagnostic");
                }finally {if(session!=null){session.Dispose();result["profileDeleteResult"]=session.DeleteResult;Save(Path.Combine(session.Fixture,"path-result.json"),result);}}
                Console.WriteLine(new JavaScriptSerializer().Serialize(result));return result.ContainsKey("error")?1:0;
            }
            if(args.Length==3 && args[0]=="app-rpc" && args[1]=="PowerShell")return TerminalRpc("ac",args[2],Path.Combine(Environment.SystemDirectory,"WindowsPowerShell","v1.0","powershell.exe"),TerminalAppsPowerShellArguments(Path.Combine(Path.GetFullPath(args[2]),"tools")));
            if(args.Length>=4 && args[0]=="terminal-rpc")return TerminalRpc(args[1],args[2],args[3],args.Skip(4).ToArray());
            if(args.Length>=5 && args[0]=="terminal-rpc-owned")return TerminalRpc(args[1],args[2],args[3],args.Skip(5).ToArray(),args[4]);
            Console.Error.WriteLine("app-suite PowerShell|ClaudeCode|Node|Git <prepared fixture> | terminal-rpc ac|lpac <fixture> <shell-exe> [args...]");return 2;
        }catch(Exception ex){Console.Error.WriteLine(ex.GetType().Name+": "+ex.Message);return 1;}
    }
}

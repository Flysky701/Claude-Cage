package io.github.leexeo.cage.shell;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.res.ColorStateList;
import android.graphics.BitmapFactory;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.RippleDrawable;
import android.os.Bundle;
import android.os.SystemClock;
import android.view.ContextThemeWrapper;
import android.view.Gravity;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import org.json.JSONArray;
import org.json.JSONObject;

/** Cage's desktop visual language, adapted to native Android touch controls. */
public final class HomeActivity extends Activity {
    private CageTheme theme;
    private LinearLayout root, content, navigation, actionBar;
    private ScrollView scroll;
    private String tab="space", renderedTab, pendingTarget, approvedRequest, approvedFingerprint;
    private final HashMap<String,Integer> scrollPositions=new HashMap<>();
    private final HashSet<String> expanded=new HashSet<>();
    private long approvedAt;
    private boolean entered, running, historical;
    private CheckReport report;
    private PreflightRunner runner;
    private List<ContainerBridge.App> apps=new ArrayList<>();
    private boolean appsLoaded;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);setTitle("Cage");
        // Restore only a visible report, never a launch authorization.
        restoreReport();refreshApps();render();
    }
    @Override protected void onResume(){
        super.onResume();
        if(!running&&entered&&!admitted()){entered=false;invalidateConsent();}
        if(root!=null&&!running){refreshApps();render();}
    }
    @Override protected void onDestroy(){if(runner!=null)runner.cancel();super.onDestroy();}
    private void refreshApps(){
        try{
            apps=new ContainerBridge(this).applications();
            // These exact packages are built-in container companions, not daily apps.
            apps.removeIf(app->"com.gbox.android.helper".equals(app.pkg)||"com.android.vending.mgc".equals(app.pkg));
            appsLoaded=true;
        }catch(Exception e){appsLoaded=false;}
    }
    private int dp(float n){return (int)(n*getResources().getDisplayMetrics().density+.5f);}
    private LinearLayout column(){LinearLayout v=new LinearLayout(this);v.setOrientation(LinearLayout.VERTICAL);return v;}
    private LinearLayout row(){LinearLayout v=new LinearLayout(this);v.setGravity(Gravity.CENTER_VERTICAL);return v;}
    private GradientDrawable shape(int color,int radius,boolean stroke){GradientDrawable d=new GradientDrawable();d.setColor(color);d.setCornerRadius(dp(radius));if(stroke)d.setStroke(dp(1),theme.line);return d;}
    private void touch(View v,int color,int radius,boolean stroke){v.setBackground(new RippleDrawable(ColorStateList.valueOf(theme.dark?0x22FFFFFF:0x15000000),shape(color,radius,stroke),null));v.setFocusable(true);}
    private TextView text(String value,int size,int color,boolean bold){TextView v=new TextView(this);v.setText(value);v.setTextSize(size);v.setTextColor(color);v.setLineSpacing(dp(2),1);v.setIncludeFontPadding(false);if(bold)v.setTypeface(Typeface.create("sans-serif-medium",Typeface.NORMAL));return v;}
    private void label(LinearLayout parent,String value,int size,int color,boolean bold){parent.addView(text(value,size,color,bold));}
    private void gap(LinearLayout parent,int n){parent.addView(new View(this),new LinearLayout.LayoutParams(1,dp(n)));}
    private void divider(LinearLayout parent,int inset){View v=new View(this);v.setBackgroundColor(theme.line);LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,dp(1));p.setMargins(dp(inset),0,dp(inset),0);parent.addView(v,p);}
    private View icon(String name,int size,int color){LineIcon v=new LineIcon(this,name,color);v.setLayoutParams(new LinearLayout.LayoutParams(dp(size),dp(size)));return v;}
    private View logo(int size){ImageView v=new ImageView(this);try(java.io.InputStream in=getAssets().open("cage-android/logo.png")){v.setImageBitmap(BitmapFactory.decodeStream(in));}catch(Exception ignored){}v.setContentDescription("Cage");v.setScaleType(ImageView.ScaleType.FIT_CENTER);v.setBackground(shape(0xFFFAF9F6,Math.max(6,size/5),false));v.setClipToOutline(true);v.setLayoutParams(new LinearLayout.LayoutParams(dp(size),dp(size)));return v;}
    private View iconButton(String name,String description,Runnable action){FrameLayout wrap=new FrameLayout(this);wrap.setMinimumWidth(dp(44));wrap.setMinimumHeight(dp(44));View i=new LineIcon(this,name,theme.ink);wrap.addView(i,new FrameLayout.LayoutParams(dp(21),dp(21),Gravity.CENTER));touch(wrap,theme.paper,9,false);wrap.setContentDescription(description);wrap.setOnClickListener(v->action.run());return wrap;}
    private TextView pill(String value,int color){TextView v=text(value,11,color,true);v.setPadding(dp(8),dp(5),dp(8),dp(5));v.setBackground(shape(theme.chrome,6,false));return v;}
    private View button(String title,String symbol,boolean primary,Runnable action){
        LinearLayout b=row();b.setGravity(Gravity.CENTER);b.setMinimumHeight(dp(48));b.setPadding(dp(14),dp(12),dp(14),dp(12));
        touch(b,primary?theme.button:theme.paper,9,!primary);int color=primary?theme.buttonInk:theme.ink;
        if(symbol!=null){b.addView(icon(symbol,18,color));View spacer=new View(this);b.addView(spacer,new LinearLayout.LayoutParams(dp(8),1));}
        b.addView(text(title,14,color,true));b.setContentDescription(title);b.setOnClickListener(v->action.run());b.setAccessibilityDelegate(new View.AccessibilityDelegate(){@Override public void onInitializeAccessibilityNodeInfo(View host,android.view.accessibility.AccessibilityNodeInfo info){super.onInitializeAccessibilityNodeInfo(host,info);info.setClassName("android.widget.Button");}});return b;
    }
    private LinearLayout panel(){LinearLayout box=column();box.setPadding(dp(1),dp(1),dp(1),dp(1));box.setBackground(shape(theme.paper,12,true));box.setClipToOutline(true);content.addView(box,new LinearLayout.LayoutParams(-1,-2));return box;}
    private void heading(String title,String detail){label(content,title,25,theme.ink,true);gap(content,9);label(content,detail,13,theme.muted,false);gap(content,24);}
    private void section(String title,String note){LinearLayout line=row();line.setPadding(0,dp(4),0,dp(12));line.addView(text(title,13,theme.ink,true),new LinearLayout.LayoutParams(0,-2,1));if(note!=null)line.addView(text(note,11,theme.muted,false));content.addView(line);}
    private void go(String key){tab=key;render();}
    private void render(){
        if(scroll!=null&&renderedTab!=null)scrollPositions.put(renderedTab,scroll.getScrollY());
        theme=new CageTheme(this);getWindow().setStatusBarColor(theme.paper);getWindow().setNavigationBarColor(theme.paper);
        getWindow().getDecorView().setSystemUiVisibility(theme.dark?0:View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR|View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR);
        root=column();root.setBackgroundColor(theme.paper);setContentView(root);
        LinearLayout top=row();top.setPadding(dp(20),dp(6),dp(12),dp(6));top.setMinimumHeight(dp(56));top.addView(logo(30));
        LinearLayout wordmark=row();wordmark.setPadding(dp(9),0,0,0);wordmark.addView(text("Cage",18,theme.ink,true));TextView android=text("ANDROID",9,theme.muted,true);android.setLetterSpacing(.1f);LinearLayout.LayoutParams ap=new LinearLayout.LayoutParams(-2,-2);ap.setMargins(dp(9),dp(3),0,0);wordmark.addView(android,ap);top.addView(wordmark,new LinearLayout.LayoutParams(0,-2,1));top.addView(pill("预览版",theme.muted));root.addView(top);divider(root,0);
        scroll=new ScrollView(this);scroll.setFillViewport(true);scroll.setClipToPadding(false);scroll.setVerticalScrollBarEnabled(false);
        FrameLayout center=new FrameLayout(this);content=column();content.setPadding(dp(20),dp(24),dp(20),dp(24));
        int width=Math.min(getResources().getDisplayMetrics().widthPixels,dp(600));center.addView(content,new FrameLayout.LayoutParams(width,-2,Gravity.TOP|Gravity.CENTER_HORIZONTAL));scroll.addView(center);
        root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));actionBar=column();root.addView(actionBar);
        if("checks".equals(tab))checks();else if("settings".equals(tab))settings();else space();
        divider(root,0);navigation=row();navigation.setPadding(dp(12),dp(5),dp(12),dp(5));nav("space","空间","space");nav("checks","启动检查","shield");nav("settings","设置","settings");root.addView(navigation);
        renderedTab=tab;final int position=scrollPositions.containsKey(tab)?scrollPositions.get(tab):0;scroll.post(()->scroll.scrollTo(0,position));
    }
    private void nav(String key,String title,String symbol){boolean selected=key.equals(tab);LinearLayout cell=column();cell.setGravity(Gravity.CENTER);cell.setPadding(0,dp(9),0,dp(8));cell.setMinimumHeight(dp(56));touch(cell,theme.paper,10,false);cell.addView(icon(symbol,21,selected?theme.accent:theme.muted));gap(cell,5);TextView caption=text(title,11,selected?theme.ink:theme.muted,selected);caption.setGravity(Gravity.CENTER);cell.addView(caption);cell.setSelected(selected);cell.setContentDescription(title+(selected?"，当前页面":""));cell.setOnClickListener(v->go(key));navigation.addView(cell,new LinearLayout.LayoutParams(0,-2,1));}
    private void space(){
        LinearLayout hero=column();hero.setGravity(Gravity.CENTER);hero.setPadding(dp(8),dp(5),dp(8),0);hero.addView(logo(64));gap(hero,20);
        TextView title=text(entered?"Cage 空间已就绪":"为 Claude 准备独立空间",24,theme.ink,true);title.setGravity(Gravity.CENTER);hero.addView(title);gap(hero,10);
        TextView sub=text(entered?"打开应用，继续你的工作。":"保留账户与应用数据，完成环境检查后开始。",13,theme.muted,false);sub.setGravity(Gravity.CENTER);hero.addView(sub);content.addView(hero);gap(content,26);
        LinearLayout box=panel();LinearLayout head=row();head.setPadding(dp(16),dp(18),dp(16),dp(16));head.addView(icon("space",26,theme.ink));
        LinearLayout names=column();names.setPadding(dp(12),0,dp(8),0);label(names,"默认空间",16,theme.ink,true);gap(names,5);label(names,"当前设备 · 独立应用数据",11,theme.muted,false);head.addView(names,new LinearLayout.LayoutParams(0,-2,1));head.addView(pill(entered?"已确认":running?"检查中":"待检查",entered?theme.success:theme.muted));box.addView(head);divider(box,16);
        LinearLayout environment=row();environment.setPadding(dp(16),dp(16),dp(16),dp(16));mini(environment,"clock","时区","东京 · UTC+9");mini(environment,"globe","网络","手机代理");mini(environment,"sim","SIM 屏蔽","已配置");box.addView(environment);
        LinearLayout control=column();control.setPadding(dp(16),0,dp(16),dp(16));
        control.addView(button(entered?"结束本次放行":running?"查看检查进度":"启动并检查",entered?"pause":running?"shield":"arrow",!entered,()->{if(entered){entered=false;invalidateConsent();render();}else if(running)go("checks");else startCheck(null);}));box.addView(control);gap(content,24);
        LinearLayout appTitle=row();appTitle.addView(text("空间内应用",13,theme.ink,true),new LinearLayout.LayoutParams(0,-2,1));appTitle.addView(iconButton("plus","添加应用",()->legacy("com.gbox.android.activities.CloneActivity")));content.addView(appTitle);gap(content,3);
        applications();gap(content,20);
        LinearLayout check=row();check.setPadding(dp(12),dp(12),dp(12),dp(12));touch(check,theme.chrome,9,false);check.addView(icon("shield",20,theme.muted));
        LinearLayout description=column();description.setPadding(dp(10),0,dp(8),0);label(description,report==null?"启动前检查":historical?"上次检查记录":"本次检查结果",12,theme.ink,true);gap(description,4);label(description,report==null?"网络、时区、VPN 与 SIM":summary(),11,theme.muted,false);check.addView(description,new LinearLayout.LayoutParams(0,-2,1));check.addView(icon("chevron",15,theme.muted));check.setOnClickListener(v->go("checks"));content.addView(check);gap(content,16);
        TextView note=text("测试模式 · 未解决项由你确认后继续",11,theme.muted,false);note.setGravity(Gravity.CENTER);content.addView(note);
    }
    private void mini(LinearLayout parent,String symbol,String title,String value){LinearLayout item=column();LinearLayout label=row();label.addView(icon(symbol,13,theme.muted));TextView t=text(title,10,theme.muted,false);t.setPadding(dp(5),0,0,0);label.addView(t);item.addView(label);gap(item,7);label(item,value,12,theme.ink,true);parent.addView(item,new LinearLayout.LayoutParams(0,-2,1));}
    private void applications(){
        LinearLayout group=panel();
        if(!appsLoaded||apps.isEmpty()){LinearLayout empty=column();empty.setPadding(dp(16),dp(20),dp(16),dp(20));label(empty,appsLoaded?"空间内还没有应用":"应用列表暂时不可用",13,theme.muted,false);gap(empty,12);empty.addView(button(appsLoaded?"添加手机中的应用":"刷新列表",appsLoaded?"plus":"refresh",false,()->{if(appsLoaded)legacy("com.gbox.android.activities.CloneActivity");else{refreshApps();render();}}));group.addView(empty);return;}
        for(int i=0;i<apps.size();i++){
            ContainerBridge.App app=apps.get(i);if(i>0)divider(group,58);LinearLayout row=row();row.setPadding(dp(14),dp(13),dp(14),dp(13));touch(row,theme.paper,12,false);
            ImageView appIcon=new ImageView(this);boolean loaded=false;try{if(app.info!=null){appIcon.setImageDrawable(app.info.loadIcon(getPackageManager()));loaded=appIcon.getDrawable()!=null;}}catch(Exception ignored){}
            if(loaded)row.addView(appIcon,new LinearLayout.LayoutParams(dp(34),dp(34)));else{FrameLayout tile=new FrameLayout(this);tile.setBackground(shape(theme.chrome,8,false));tile.addView(new LineIcon(this,"app",theme.ink),new FrameLayout.LayoutParams(dp(21),dp(21),Gravity.CENTER));row.addView(tile,new LinearLayout.LayoutParams(dp(34),dp(34)));}
            LinearLayout names=column();names.setPadding(dp(12),0,dp(10),0);label(names,app.label,15,theme.ink,true);gap(names,5);label(names,CheckPolicy.selected(app.pkg)?"空间内已安装":"屏蔽适配待确认",11,theme.muted,false);row.addView(names,new LinearLayout.LayoutParams(0,-2,1));row.addView(icon("chevron",16,theme.muted));row.setContentDescription("打开 "+app.label);row.setOnClickListener(v->open(app.pkg));group.addView(row);
        }
    }
    private String summary(){return "通过 "+report.count(CheckPolicy.State.PASSED)+" · 未通过 "+report.count(CheckPolicy.State.FAILED)+" · 未确认 "+report.count(CheckPolicy.State.UNKNOWN);}
    private void checks(){
        heading("启动前检查","核对网络与隔离状态，再进入空间。");
        if(running){
            LinearLayout box=panel();box.setPadding(dp(20),dp(22),dp(20),dp(22));LinearLayout line=row();ProgressBar progress=new ProgressBar(this);progress.setIndeterminateTintList(ColorStateList.valueOf(theme.ink));line.addView(progress,new LinearLayout.LayoutParams(dp(23),dp(23)));TextView title=text("正在检查环境",16,theme.ink,true);title.setPadding(dp(12),0,0,0);line.addView(title);box.addView(line);gap(box,14);label(box,"检测组件可能短暂打开，完成后返回这里。",13,theme.muted,false);gap(box,18);box.addView(button("取消检查",null,false,()->{runner.cancel();running=false;pendingTarget=null;render();}));return;
        }
        if(report==null){
            LinearLayout sum=panel();sum.setPadding(dp(16),dp(18),dp(16),dp(18));sum.addView(icon("shield",26,theme.ink));gap(sum,12);label(sum,"尚未检查",17,theme.ink,true);gap(sum,7);label(sum,"每次进入前重新读取结果，缺少证据的项目会显示为未能确认。",13,theme.muted,false);gap(content,24);
            section("关键检查","本轮待检查");LinearLayout group=panel();String[] titles={"网络连接与出口","系统与网页时区","VPN 状态屏蔽","SIM 屏蔽"};for(int i=0;i<titles.length;i++){if(i>0)divider(group,16);simpleRow(group,new String[]{"globe","clock","shield","sim"}[i],titles[i],"待检查",null);}
            gap(content,22);section("其他边界",null);LinearLayout other=panel();simpleRow(other,"info","断线保护、DNS 与数据边界","查看",()->message("其他检查边界","代理断线保护、DNS、UDP / IPv6，以及跨应用文件边界会单独列出，未验证的能力不会标为通过。"));
            sticky("启动并检查","shield",()->startCheck(null),"测试模式 · 不自动放行未解决项");return;
        }
        LinearLayout sum=panel();sum.setPadding(dp(16),dp(17),dp(16),dp(17));LinearLayout top=row();top.addView(icon("shield",25,theme.ink));TextView title=text(historical?"上次检查记录":report.error!=null?"检查未完成":report.allPassed()?"检查已通过":"有项目需要确认",17,theme.ink,true);title.setPadding(dp(11),0,0,0);top.addView(title);sum.addView(top);gap(sum,16);
        LinearLayout counts=row();count(counts,"通过",report.count(CheckPolicy.State.PASSED),theme.success);count(counts,"未通过",report.count(CheckPolicy.State.FAILED),theme.danger);count(counts,"未能确认",report.count(CheckPolicy.State.UNKNOWN),theme.warning);sum.addView(counts);gap(sum,14);
        label(sum,new SimpleDateFormat("MM-dd HH:mm",Locale.getDefault()).format(new Date(report.createdWall))+" · "+report.location,11,theme.muted,false);gap(sum,7);label(sum,historical?"历史结果仅供查看，进入前需要重新检查。":"手动继续不会把未解决项改成通过。",11,theme.muted,false);gap(content,23);
        section("关键检查","点击查看详情");LinearLayout main=panel();int n=0;for(CheckReport.Item item:report.items)if(!item.advanced){if(n++>0)divider(main,44);checkRow(main,item);}
        int extra=0;for(CheckReport.Item item:report.items)if(item.advanced)extra++;
        if(extra>0){gap(content,23);section("其他边界",extra+" 项");LinearLayout more=panel();n=0;for(CheckReport.Item item:report.items)if(item.advanced){if(n++>0)divider(more,44);checkRow(more,item);}}
        gap(content,15);content.addView(button("复制检查摘要","copy",false,this::copyReport));
        if(historical||report.error!=null)sticky("重新检查","refresh",()->startCheck(pendingTarget),historical?"历史结果不会授权启动":"本轮未取得完整结果");
        else {
            LinearLayout actions=row();View retry=button("重检","refresh",false,()->startCheck(pendingTarget));actions.addView(retry,new LinearLayout.LayoutParams(0,-2,1));View spacer=new View(this);actions.addView(spacer,new LinearLayout.LayoutParams(dp(10),1));actions.addView(button(report.allPassed()?"进入空间":"确认后继续","arrow",true,this::confirm),new LinearLayout.LayoutParams(0,-2,2));stickyContent(actions,"检查有效期 5 分钟 · 环境变化后需重检");
        }
    }
    private void count(LinearLayout row,String name,int number,int color){LinearLayout c=column();label(c,String.valueOf(number),25,color,true);gap(c,5);label(c,name,11,theme.muted,false);row.addView(c,new LinearLayout.LayoutParams(0,-2,1));}
    private void checkRow(LinearLayout group,CheckReport.Item item){
        LinearLayout shell=column();LinearLayout line=row();line.setMinimumHeight(dp(52));line.setPadding(dp(13),dp(12),dp(13),dp(12));touch(line,theme.paper,10,false);
        int color=item.state==CheckPolicy.State.PASSED?theme.success:item.state==CheckPolicy.State.FAILED?theme.danger:theme.warning;
        line.addView(icon(item.state==CheckPolicy.State.PASSED?"check":item.state==CheckPolicy.State.FAILED?"close":"help",17,color));TextView title=text(item.title,13,theme.ink,true);title.setPadding(dp(10),0,dp(8),0);line.addView(title,new LinearLayout.LayoutParams(0,-2,1));line.addView(text(item.state==CheckPolicy.State.PASSED?"通过":item.state==CheckPolicy.State.FAILED?"未通过":"未能确认",11,color,false));
        FrameLayout arrow=new FrameLayout(this);LineIcon arrowIcon=new LineIcon(this,"down",theme.muted);arrow.addView(arrowIcon,new FrameLayout.LayoutParams(dp(13),dp(13),Gravity.RIGHT|Gravity.CENTER_VERTICAL));line.addView(arrow,new LinearLayout.LayoutParams(dp(23),dp(22)));shell.addView(line);
        TextView detail=text(item.detail,12,theme.muted,false);detail.setPadding(dp(40),0,dp(16),dp(16));detail.setTextIsSelectable(true);boolean opened=expanded.contains(item.id);detail.setVisibility(opened?View.VISIBLE:View.GONE);arrowIcon.setRotation(opened?180:0);shell.addView(detail);line.setContentDescription(item.title+"，"+(opened?"收起":"展开")+"详情");
        line.setOnClickListener(v->{boolean open=detail.getVisibility()!=View.VISIBLE;detail.setVisibility(open?View.VISIBLE:View.GONE);arrowIcon.setRotation(open?180:0);if(open)expanded.add(item.id);else expanded.remove(item.id);line.setContentDescription(item.title+"，"+(open?"收起":"展开")+"详情");});group.addView(shell);
    }
    private void sticky(String title,String symbol,Runnable action,String note){stickyContent(button(title,symbol,true,action),note);}
    private void stickyContent(View view,String note){divider(actionBar,0);LinearLayout pad=column();pad.setPadding(dp(20),dp(12),dp(20),dp(12));pad.addView(view);gap(pad,8);TextView t=text(note,10,theme.muted,false);t.setGravity(Gravity.CENTER);pad.addView(t);actionBar.addView(pad);}
    private void simpleRow(LinearLayout group,String symbol,String title,String value,Runnable action){LinearLayout row=row();row.setMinimumHeight(dp(57));row.setPadding(dp(14),dp(13),dp(14),dp(13));row.addView(icon(symbol,19,theme.muted));TextView name=text(title,13,theme.ink,false);name.setPadding(dp(11),0,dp(8),0);row.addView(name,new LinearLayout.LayoutParams(0,-2,1));if(value!=null)row.addView(text(value,11,theme.muted,false));if(action!=null){FrameLayout wrap=new FrameLayout(this);wrap.addView(new LineIcon(this,"chevron",theme.muted),new FrameLayout.LayoutParams(dp(14),dp(14),Gravity.RIGHT|Gravity.CENTER_VERTICAL));row.addView(wrap,new LinearLayout.LayoutParams(dp(22),dp(18)));touch(row,theme.paper,12,false);row.setOnClickListener(v->action.run());}group.addView(row);}
    private void settings(){
        heading("设置","空间、外观与使用偏好。");
        section("空间",null);LinearLayout manage=panel();simpleRow(manage,"space","默认空间","当前",null);divider(manage,44);simpleRow(manage,"plus","添加手机中的应用",null,()->legacy("com.gbox.android.activities.CloneActivity"));divider(manage,44);simpleRow(manage,"user","Google 账户",null,()->legacy("com.gbox.android.activities.GoogleAccountManagerActivity"));gap(content,23);
        section("外观",null);LinearLayout appearance=panel();String current=getSharedPreferences("cage-android-ui",0).getString("appearance","system");simpleRow(appearance,"theme","主题",modeName(current),this::appearance);gap(content,23);
        section("环境与启动",null);LinearLayout environment=panel();simpleRow(environment,"clock","空间时区","东京 · UTC+9",null);divider(environment,44);simpleRow(environment,"sim","SIM 屏蔽","已配置",null);divider(environment,44);simpleRow(environment,"shield","VPN 状态屏蔽","已配置",null);divider(environment,44);simpleRow(environment,"globe","网络连接","手机当前代理",null);divider(environment,44);simpleRow(environment,"check","启动方式","测试模式",()->message("测试模式","每次先检查，再由你确认未通过或未能确认的项目。放行只在本次会话有效，不会永久记住。"));gap(content,8);label(content,"已配置表示当前策略，实际生效情况以检查结果为准。",10,theme.muted,false);gap(content,23);
        section("关于",null);LinearLayout about=panel();simpleRow(about,"info","关于 Cage","安卓预览版",this::about);divider(about,44);simpleRow(about,"shield","适配范围与检查边界",null,()->message("当前适配范围","当前支持一个现有空间，屏蔽适配覆盖 Claude 与检测组件。其他应用需独立验证。\n\n新首页入口执行启动检查；外部通知、快捷方式和原管理页尚未统一接入。具体未解决项以当前版本验证记录为准。"));divider(about,44);simpleRow(about,"globe","检查使用的服务",null,()->message("检查使用的服务","检查会访问固定的公网 IP 和地区查询服务：icanhazip.com、ipify.org 与 ipwho.is。服务可见本次出口 IP，不发送账户或聊天内容。"));gap(content,24);
        TextView foot=text("Cage · Android Preview",11,theme.muted,false);foot.setGravity(Gravity.CENTER);content.addView(foot);
    }
    private String modeName(String mode){return "dark".equals(mode)?"深色":"light".equals(mode)?"浅色":"跟随系统";}
    private AlertDialog.Builder dialog(){return new AlertDialog.Builder(new ContextThemeWrapper(this,theme.dark?android.R.style.Theme_Material_Dialog_Alert:android.R.style.Theme_Material_Light_Dialog_Alert));}
    private void appearance(){String mode=getSharedPreferences("cage-android-ui",0).getString("appearance","system");int selected="light".equals(mode)?1:"dark".equals(mode)?2:0;dialog().setTitle("外观").setSingleChoiceItems(new String[]{"跟随系统","浅色","深色"},selected,(d,w)->{getSharedPreferences("cage-android-ui",0).edit().putString("appearance",new String[]{"system","light","dark"}[w]).apply();d.dismiss();render();}).setNegativeButton("取消",null).show();}
    private void about(){dialog().setTitle("Cage 安卓预览版").setMessage("沿用 Cage 的桌面设计与现有容器能力。\n\n账户、应用与登录数据保留在当前空间。此版本用于本地预览，尚未发布。\n\n应用版本：1.8.4.02\n界面：Android Preview").setPositiveButton("完成",null).show();}
    private void startCheck(String target){if(running)return;entered=false;invalidateConsent();pendingTarget=target;report=null;historical=false;running=true;expanded.clear();scrollPositions.put("checks",0);tab="checks";render();runner=new PreflightRunner();runner.run(this,target,value->{if(isFinishing()||isDestroyed())return;running=false;report=value;historical=false;tab="checks";saveReport(value);render();});}
    private void saveReport(CheckReport value){try(FileOutputStream out=new FileOutputStream(new File(getFilesDir(),"cage-startup-check.json"))){out.write(value.json().toString(2).getBytes(StandardCharsets.UTF_8));}catch(Exception ignored){}}
    private void restoreReport(){
        File file=new File(getFilesDir(),"cage-startup-check.json");long size=file.length();if(size<2||size>65536)return;
        try(FileInputStream in=new FileInputStream(file)){byte[] data=new byte[(int)size];int at=0;while(at<data.length){int n=in.read(data,at,data.length-at);if(n<0)return;at+=n;}JSONObject stored=new JSONObject(new String(data,StandardCharsets.UTF_8));if(stored.optInt("schema")!=1)return;CheckReport value=new CheckReport(null,null,0,stored.getLong("createdAt"));value.location=stored.optString("location","尚未确认出口");JSONArray rows=stored.getJSONArray("checks");if(rows.length()>40)return;for(int i=0;i<rows.length();i++){JSONObject c=rows.getJSONObject(i);value.add(c.getString("id"),c.getString("title"),CheckPolicy.State.valueOf(c.getString("state")),c.getString("detail"),c.optBoolean("advanced"));}report=value;historical=true;}catch(Exception ignored){}
    }
    private void copyReport(){if(report==null)return;try{JSONObject safe=report.json();safe.remove("request");((ClipboardManager)getSystemService(Context.CLIPBOARD_SERVICE)).setPrimaryClip(ClipData.newPlainText("Cage 检查摘要",safe.toString(2)));Toast.makeText(this,"已复制，不含账户、IP 与本机路径",Toast.LENGTH_SHORT).show();}catch(Exception e){Toast.makeText(this,"暂时无法复制",Toast.LENGTH_SHORT).show();}}
    private boolean currentReport(){return report!=null&&!historical&&report.error==null&&SystemClock.elapsedRealtime()-report.createdElapsed<CheckPolicy.LIFETIME_MS&&report.fingerprint.equals(Checks.fingerprint(this));}
    private void confirm(){if(!currentReport()){dialog().setTitle("需要重新检查").setMessage("本轮检查未完成、已过期或环境已变化。").setNegativeButton("返回",null).setPositiveButton("重新检查",(d,w)->startCheck(pendingTarget)).show();return;}if(report.allPassed()){enter();return;}dialog().setTitle("确认后继续？").setMessage(summary()+"\n\n仍有未通过或未能确认的项目。继续仅放行本次测试，不代表检查通过。请先阅读各项详情。").setNegativeButton("返回检查",null).setPositiveButton("了解并继续",(d,w)->{if(currentReport())enter();else startCheck(pendingTarget);}).show();}
    private void enter(){approvedRequest=report.request;approvedFingerprint=report.fingerprint;approvedAt=SystemClock.elapsedRealtime();entered=true;String target=pendingTarget;pendingTarget=null;tab="space";scrollPositions.put("space",0);render();if(target!=null)open(target);}
    private void invalidateConsent(){approvedRequest=null;approvedFingerprint=null;approvedAt=0;}
    private boolean admitted(){return report!=null&&!historical&&CheckPolicy.admitted(approvedRequest,report.request,approvedFingerprint,Checks.fingerprint(this),approvedAt,SystemClock.elapsedRealtime());}
    private void open(String pkg){if(!admitted()){startCheck(pkg);return;}if(!CheckPolicy.selected(pkg)){dialog().setTitle("此应用尚未适配").setMessage("所选应用可能读取手机真实环境，需要独立验证屏蔽效果。").setNegativeButton("返回",null).setPositiveButton("仍然打开",(d,w)->launch(pkg)).show();}else launch(pkg);}
    private void launch(String pkg){try{if(!admitted()){startCheck(pkg);return;}new ContainerBridge(this).launch(pkg,null);}catch(Exception e){message("应用暂时无法打开","空间与原有数据保留，请稍后重试。");}}
    private void legacy(String name){try{startActivity(new Intent().setClassName(getPackageName(),name));}catch(Exception e){message("入口暂时不可用","原数据保留，请返回后重试。");}}
    private void message(String title,String body){dialog().setTitle(title).setMessage(body).setPositiveButton("知道了",null).show();}
    @Override public void onBackPressed(){if(!"space".equals(tab))go("space");else super.onBackPressed();}
}

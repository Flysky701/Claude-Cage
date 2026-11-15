.class public final Lio/github/leexeo/cage/space/LoginCheck;
.super Ljava/lang/Object;
.source "LoginCheck.java"

# interfaces
.implements Ljava/lang/Runnable;


# instance fields
.field private attempts:I

.field private final main:Landroid/os/Handler;

.field private settingsLogged:Z


# direct methods
.method public constructor <init>()V
    .locals 2

    .line 12
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 13
    new-instance v0, Landroid/os/Handler;

    invoke-static {}, Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;

    move-result-object v1

    invoke-direct {v0, v1}, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V

    iput-object v0, p0, Lio/github/leexeo/cage/space/LoginCheck;->main:Landroid/os/Handler;

    return-void
.end method

.method private find(Landroid/view/View;)Landroid/webkit/WebView;
    .locals 2

    .line 18
    instance-of v0, p1, Landroid/webkit/WebView;

    if-eqz v0, :cond_0

    check-cast p1, Landroid/webkit/WebView;

    return-object p1

    .line 19
    :cond_0
    instance-of v0, p1, Landroid/view/ViewGroup;

    if-eqz v0, :cond_2

    .line 20
    check-cast p1, Landroid/view/ViewGroup;

    .line 21
    const/4 v0, 0x0

    :goto_0
    invoke-virtual {p1}, Landroid/view/ViewGroup;->getChildCount()I

    move-result v1

    if-ge v0, v1, :cond_2

    .line 22
    invoke-virtual {p1, v0}, Landroid/view/ViewGroup;->getChildAt(I)Landroid/view/View;

    move-result-object v1

    invoke-direct {p0, v1}, Lio/github/leexeo/cage/space/LoginCheck;->find(Landroid/view/View;)Landroid/webkit/WebView;

    move-result-object v1

    .line 23
    if-eqz v1, :cond_1

    return-object v1

    .line 21
    :cond_1
    add-int/lit8 v0, v0, 0x1

    goto :goto_0

    .line 26
    :cond_2
    const/4 p1, 0x0

    return-object p1
.end method

.method static synthetic lambda$run$0(Ljava/lang/String;)V
    .locals 2

    .line 52
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "login_page_shape="

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    const-string v0, "CageDemo"

    invoke-static {v0, p0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    return-void
.end method

.method static synthetic lambda$run$1(Landroid/webkit/WebView;)V
    .locals 2

    .line 51
    new-instance v0, Lio/github/leexeo/cage/space/LoginCheck$$ExternalSyntheticLambda0;

    invoke-direct {v0}, Lio/github/leexeo/cage/space/LoginCheck$$ExternalSyntheticLambda0;-><init>()V

    const-string v1, "JSON.stringify({protocol:location.protocol,host:location.hostname,forms:document.forms.length,inputs:document.querySelectorAll(\'input\').length,error:(document.querySelector(\'.error-code\')||{}).textContent||\'\'})"

    invoke-virtual {p0, v1, v0}, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String;Landroid/webkit/ValueCallback;)V

    return-void
.end method

.method public static start()V
    .locals 4

    .line 16
    new-instance v0, Lio/github/leexeo/cage/space/LoginCheck;

    invoke-direct {v0}, Lio/github/leexeo/cage/space/LoginCheck;-><init>()V

    iget-object v1, v0, Lio/github/leexeo/cage/space/LoginCheck;->main:Landroid/os/Handler;

    const-wide/16 v2, 0x3e8

    invoke-virtual {v1, v0, v2, v3}, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable;J)Z

    return-void
.end method


# virtual methods
.method public run()V
    .locals 12

    .line 30
    const-string v0, "CageDemo"

    :try_start_0
    const-string v1, "android.app.ActivityThread"

    invoke-static {v1}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v1

    .line 31
    const-string v2, "currentActivityThread"

    const/4 v3, 0x0

    new-array v4, v3, [Ljava/lang/Class;

    invoke-virtual {v1, v2, v4}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v2

    new-array v4, v3, [Ljava/lang/Object;

    const/4 v5, 0x0

    invoke-virtual {v2, v5, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    .line 32
    const-string v4, "mActivities"

    invoke-virtual {v1, v4}, Ljava/lang/Class;->getDeclaredField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v1

    const/4 v4, 0x1

    invoke-virtual {v1, v4}, Ljava/lang/reflect/Field;->setAccessible(Z)V

    .line 33
    invoke-virtual {v1, v2}, Ljava/lang/reflect/Field;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Ljava/util/Map;

    invoke-interface {v1}, Ljava/util/Map;->values()Ljava/util/Collection;

    move-result-object v1

    invoke-interface {v1}, Ljava/util/Collection;->iterator()Ljava/util/Iterator;

    move-result-object v1

    :cond_0
    :goto_0
    invoke-interface {v1}, Ljava/util/Iterator;->hasNext()Z

    move-result v2

    if-eqz v2, :cond_8

    invoke-interface {v1}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v2

    .line 34
    invoke-virtual {v2}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v5

    const-string v6, "activity"

    invoke-virtual {v5, v6}, Ljava/lang/Class;->getDeclaredField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v5

    invoke-virtual {v5, v4}, Ljava/lang/reflect/Field;->setAccessible(Z)V

    .line 35
    invoke-virtual {v5, v2}, Ljava/lang/reflect/Field;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Landroid/app/Activity;

    .line 36
    if-eqz v2, :cond_0

    invoke-virtual {v2}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v5

    invoke-virtual {v5}, Ljava/lang/Class;->getName()Ljava/lang/String;

    move-result-object v5

    const-string v6, "org.microg.gms.auth.login.LoginActivity"

    invoke-virtual {v5, v6}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v5

    if-nez v5, :cond_1

    goto :goto_0

    .line 37
    :cond_1
    invoke-virtual {v2}, Landroid/app/Activity;->getWindow()Landroid/view/Window;

    move-result-object v5

    invoke-virtual {v5}, Landroid/view/Window;->getDecorView()Landroid/view/View;

    move-result-object v5

    invoke-direct {p0, v5}, Lio/github/leexeo/cage/space/LoginCheck;->find(Landroid/view/View;)Landroid/webkit/WebView;

    move-result-object v5

    .line 38
    if-nez v5, :cond_4

    invoke-virtual {v2}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v6

    invoke-virtual {v6}, Ljava/lang/Class;->getDeclaredFields()[Ljava/lang/reflect/Field;

    move-result-object v6

    array-length v7, v6

    move v8, v3

    :goto_1
    if-ge v8, v7, :cond_4

    aget-object v9, v6, v8

    .line 39
    const-class v10, Landroid/webkit/WebView;

    invoke-virtual {v9}, Ljava/lang/reflect/Field;->getType()Ljava/lang/Class;

    move-result-object v11

    invoke-virtual {v10, v11}, Ljava/lang/Class;->isAssignableFrom(Ljava/lang/Class;)Z

    move-result v10

    if-nez v10, :cond_2

    goto :goto_2

    .line 40
    :cond_2
    invoke-virtual {v9, v4}, Ljava/lang/reflect/Field;->setAccessible(Z)V

    invoke-virtual {v9, v2}, Ljava/lang/reflect/Field;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v5

    check-cast v5, Landroid/webkit/WebView;

    .line 41
    if-eqz v5, :cond_3

    goto :goto_3

    .line 38
    :cond_3
    :goto_2
    add-int/lit8 v8, v8, 0x1

    goto :goto_1

    .line 43
    :cond_4
    :goto_3
    if-nez v5, :cond_5

    goto :goto_0

    .line 44
    :cond_5
    iget-boolean v2, p0, Lio/github/leexeo/cage/space/LoginCheck;->settingsLogged:Z

    if-nez v2, :cond_6

    .line 45
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v6, "login_webview blocked="

    invoke-virtual {v2, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v5}, Landroid/webkit/WebView;->getSettings()Landroid/webkit/WebSettings;

    move-result-object v6

    invoke-virtual {v6}, Landroid/webkit/WebSettings;->getBlockNetworkLoads()Z

    move-result v6

    invoke-virtual {v2, v6}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    move-result-object v2

    const-string v6, " js="

    invoke-virtual {v2, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    .line 46
    invoke-virtual {v5}, Landroid/webkit/WebView;->getSettings()Landroid/webkit/WebSettings;

    move-result-object v6

    invoke-virtual {v6}, Landroid/webkit/WebSettings;->getJavaScriptEnabled()Z

    move-result v6

    invoke-virtual {v2, v6}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    move-result-object v2

    const-string v6, " visibility="

    invoke-virtual {v2, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v5}, Landroid/webkit/WebView;->getVisibility()I

    move-result v6

    invoke-virtual {v2, v6}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    .line 45
    invoke-static {v0, v2}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 47
    iput-boolean v4, p0, Lio/github/leexeo/cage/space/LoginCheck;->settingsLogged:Z

    .line 49
    :cond_6
    invoke-virtual {v5}, Landroid/webkit/WebView;->getUrl()Ljava/lang/String;

    move-result-object v2

    if-eqz v2, :cond_0

    invoke-virtual {v5}, Landroid/webkit/WebView;->getUrl()Ljava/lang/String;

    move-result-object v2

    const-string v6, "about:"

    invoke-virtual {v2, v6}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_7

    goto/16 :goto_0

    .line 50
    :cond_7
    nop

    .line 51
    iget-object v1, p0, Lio/github/leexeo/cage/space/LoginCheck;->main:Landroid/os/Handler;

    new-instance v2, Lio/github/leexeo/cage/space/LoginCheck$$ExternalSyntheticLambda1;

    invoke-direct {v2, v5}, Lio/github/leexeo/cage/space/LoginCheck$$ExternalSyntheticLambda1;-><init>(Landroid/webkit/WebView;)V

    const-wide/16 v3, 0x1388

    invoke-virtual {v1, v2, v3, v4}, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable;J)Z
    :try_end_0
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_0 .. :try_end_0} :catch_0
    .catch Ljava/lang/RuntimeException; {:try_start_0 .. :try_end_0} :catch_0

    .line 53
    return-void

    .line 57
    :cond_8
    nop

    .line 58
    iget v0, p0, Lio/github/leexeo/cage/space/LoginCheck;->attempts:I

    add-int/2addr v0, v4

    iput v0, p0, Lio/github/leexeo/cage/space/LoginCheck;->attempts:I

    const/16 v1, 0x78

    if-ge v0, v1, :cond_9

    iget-object v0, p0, Lio/github/leexeo/cage/space/LoginCheck;->main:Landroid/os/Handler;

    const-wide/16 v1, 0x3e8

    invoke-virtual {v0, p0, v1, v2}, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable;J)Z

    .line 59
    :cond_9
    return-void

    .line 55
    :catch_0
    move-exception v1

    .line 56
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "login_shape_unavailable="

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v1}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    return-void
.end method

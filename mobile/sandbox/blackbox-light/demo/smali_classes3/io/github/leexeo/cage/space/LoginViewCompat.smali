.class public final Lio/github/leexeo/cage/space/LoginViewCompat;
.super Ljava/lang/Object;
.source "LoginViewCompat.java"

# interfaces
.implements Ljava/lang/Runnable;


# instance fields
.field private final activity:Landroid/app/Activity;

.field private attempts:I

.field private final main:Landroid/os/Handler;


# direct methods
.method private constructor <init>(Landroid/app/Activity;)V
    .locals 2

    .line 16
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 14
    new-instance v0, Landroid/os/Handler;

    invoke-static {}, Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;

    move-result-object v1

    invoke-direct {v0, v1}, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V

    iput-object v0, p0, Lio/github/leexeo/cage/space/LoginViewCompat;->main:Landroid/os/Handler;

    .line 16
    iput-object p1, p0, Lio/github/leexeo/cage/space/LoginViewCompat;->activity:Landroid/app/Activity;

    return-void
.end method

.method public static resume(Landroid/app/Activity;)V
    .locals 3

    .line 18
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/Class;->getName()Ljava/lang/String;

    move-result-object v0

    const-string v1, "org.microg.gms.auth.login.LoginActivity"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_0

    return-void

    .line 19
    :cond_0
    new-instance v0, Lio/github/leexeo/cage/space/LoginViewCompat;

    invoke-direct {v0, p0}, Lio/github/leexeo/cage/space/LoginViewCompat;-><init>(Landroid/app/Activity;)V

    .line 20
    iget-object p0, v0, Lio/github/leexeo/cage/space/LoginViewCompat;->main:Landroid/os/Handler;

    const-wide/16 v1, 0x1f4

    invoke-virtual {p0, v0, v1, v2}, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable;J)Z

    .line 21
    return-void
.end method


# virtual methods
.method public run()V
    .locals 5

    .line 23
    iget-object v0, p0, Lio/github/leexeo/cage/space/LoginViewCompat;->activity:Landroid/app/Activity;

    invoke-virtual {v0}, Landroid/app/Activity;->isFinishing()Z

    move-result v0

    if-nez v0, :cond_3

    iget-object v0, p0, Lio/github/leexeo/cage/space/LoginViewCompat;->activity:Landroid/app/Activity;

    invoke-virtual {v0}, Landroid/app/Activity;->isDestroyed()Z

    move-result v0

    if-eqz v0, :cond_0

    goto/16 :goto_0

    .line 25
    :cond_0
    :try_start_0
    iget-object v0, p0, Lio/github/leexeo/cage/space/LoginViewCompat;->activity:Landroid/app/Activity;

    invoke-virtual {v0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v0

    const-string v1, "webView"

    invoke-virtual {v0, v1}, Ljava/lang/Class;->getDeclaredField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v0

    const/4 v1, 0x1

    invoke-virtual {v0, v1}, Ljava/lang/reflect/Field;->setAccessible(Z)V

    .line 26
    iget-object v2, p0, Lio/github/leexeo/cage/space/LoginViewCompat;->activity:Landroid/app/Activity;

    invoke-virtual {v0, v2}, Ljava/lang/reflect/Field;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/webkit/WebView;

    .line 27
    if-eqz v0, :cond_1

    invoke-virtual {v0}, Landroid/webkit/WebView;->getUrl()Ljava/lang/String;

    move-result-object v2

    if-eqz v2, :cond_1

    invoke-virtual {v0}, Landroid/webkit/WebView;->getProgress()I

    move-result v2

    const/16 v3, 0x64

    if-ne v2, v3, :cond_1

    .line 28
    invoke-virtual {v0}, Landroid/webkit/WebView;->getUrl()Ljava/lang/String;

    move-result-object v2

    invoke-static {v2}, Landroid/net/Uri;->parse(Ljava/lang/String;)Landroid/net/Uri;

    move-result-object v2

    .line 29
    const-string v3, "https"

    invoke-virtual {v2}, Landroid/net/Uri;->getScheme()Ljava/lang/String;

    move-result-object v4

    invoke-virtual {v3, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-eqz v3, :cond_1

    const-string v3, "accounts.google.com"

    invoke-virtual {v2}, Landroid/net/Uri;->getHost()Ljava/lang/String;

    move-result-object v4

    invoke-virtual {v3, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-eqz v3, :cond_1

    .line 30
    invoke-virtual {v2}, Landroid/net/Uri;->getPath()Ljava/lang/String;

    move-result-object v3

    if-eqz v3, :cond_1

    invoke-virtual {v2}, Landroid/net/Uri;->getPath()Ljava/lang/String;

    move-result-object v2

    const-string v3, "/identifier"

    invoke-virtual {v2, v3}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_1

    .line 31
    const/4 v1, 0x0

    invoke-virtual {v0, v1}, Landroid/webkit/WebView;->setVisibility(I)V

    .line 32
    invoke-virtual {v0}, Landroid/webkit/WebView;->bringToFront()V

    .line 33
    const-string v0, "CageDemo"

    const-string v1, "Loaded Google identifier page shown"

    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_0 .. :try_end_0} :catch_0
    .catch Ljava/lang/RuntimeException; {:try_start_0 .. :try_end_0} :catch_0

    .line 34
    return-void

    .line 37
    :cond_1
    nop

    .line 38
    iget v0, p0, Lio/github/leexeo/cage/space/LoginViewCompat;->attempts:I

    add-int/2addr v0, v1

    iput v0, p0, Lio/github/leexeo/cage/space/LoginViewCompat;->attempts:I

    const/16 v1, 0xf0

    if-ge v0, v1, :cond_2

    iget-object v0, p0, Lio/github/leexeo/cage/space/LoginViewCompat;->main:Landroid/os/Handler;

    const-wide/16 v1, 0x1f4

    invoke-virtual {v0, p0, v1, v2}, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable;J)Z

    .line 39
    :cond_2
    return-void

    .line 37
    :catch_0
    move-exception v0

    return-void

    .line 23
    :cond_3
    :goto_0
    return-void
.end method

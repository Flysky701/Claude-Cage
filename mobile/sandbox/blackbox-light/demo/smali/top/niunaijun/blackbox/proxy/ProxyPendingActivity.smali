.class public Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity;
.super Landroid/app/Activity;
.source "r8-map-id-b030d4079bf46d1be0bde84446c3eaf9c7aec13dc1c4fe379a76cc83ba4f4ecf"


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P49;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P48;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P47;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P46;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P45;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P44;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P43;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P42;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P41;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P40;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P39;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P38;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P37;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P36;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P35;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P34;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P33;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P32;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P31;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P30;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P29;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P28;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P27;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P26;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P25;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P24;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P23;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P22;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P21;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P20;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P19;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P18;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P17;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P16;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P15;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P14;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P13;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P12;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P11;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P10;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P9;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P8;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P7;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P6;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P5;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P4;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P3;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P2;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P1;,
        Ltop/niunaijun/blackbox/proxy/ProxyPendingActivity$P0;
    }
.end annotation


# static fields
.field public static final TAG:Ljava/lang/String; = "ProxyPendingActivity"


# direct methods
.method public constructor <init>()V
    .locals 0

    .line 1
    invoke-direct {p0}, Landroid/app/Activity;-><init>()V

    .line 2
    .line 3
    .line 4
    return-void
.end method


# virtual methods
.method public onCreate(Landroid/os/Bundle;)V
    .locals 2

    .line 1
    invoke-super {p0, p1}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V

    invoke-static {p0}, Lio/github/leexeo/cage/space/GuestPendingActivity;->finishProxy(Landroid/app/Activity;)Z

    move-result v0

    if-eqz v0, :cond_0

    return-void

    .line 2
    .line 3
    .line 4
    :cond_0
    invoke-virtual {p0}, Landroid/app/Activity;->finish()V

    .line 5
    .line 6
    .line 7
    invoke-virtual {p0}, Landroid/app/Activity;->getIntent()Landroid/content/Intent;

    .line 8
    .line 9
    .line 10
    move-result-object p1

    .line 11
    invoke-static {p1}, Ltop/niunaijun/blackbox/proxy/record/ProxyPendingRecord;->create(Landroid/content/Intent;)Ltop/niunaijun/blackbox/proxy/record/ProxyPendingRecord;

    .line 12
    .line 13
    .line 14
    move-result-object p1

    .line 15
    new-instance v0, Ljava/lang/StringBuilder;

    .line 16
    .line 17
    const-string v1, "ProxyPendingActivity: "

    .line 18
    .line 19
    invoke-direct {v0, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 20
    .line 21
    .line 22
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    .line 23
    .line 24
    .line 25
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 26
    .line 27
    .line 28
    move-result-object v0

    .line 29
    const-string v1, "ProxyPendingActivity"

    .line 30
    .line 31
    invoke-static {v1, v0}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 32
    .line 33
    .line 34
    iget-object v0, p1, Ltop/niunaijun/blackbox/proxy/record/ProxyPendingRecord;->mTarget:Landroid/content/Intent;

    .line 35
    .line 36
    if-nez v0, :cond_1

    .line 37
    .line 38
    return-void

    .line 39
    :cond_1
    const/high16 v1, 0x10000000

    .line 40
    .line 41
    invoke-virtual {v0, v1}, Landroid/content/Intent;->addFlags(I)Landroid/content/Intent;

    .line 42
    .line 43
    .line 44
    iget-object v0, p1, Ltop/niunaijun/blackbox/proxy/record/ProxyPendingRecord;->mTarget:Landroid/content/Intent;

    .line 45
    .line 46
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getApplication()Landroid/app/Application;

    .line 47
    .line 48
    .line 49
    move-result-object v1

    .line 50
    invoke-virtual {v1}, Landroid/content/Context;->getClassLoader()Ljava/lang/ClassLoader;

    .line 51
    .line 52
    .line 53
    move-result-object v1

    .line 54
    invoke-virtual {v0, v1}, Landroid/content/Intent;->setExtrasClassLoader(Ljava/lang/ClassLoader;)V

    .line 55
    .line 56
    .line 57
    iget-object p1, p1, Ltop/niunaijun/blackbox/proxy/record/ProxyPendingRecord;->mTarget:Landroid/content/Intent;

    .line 58
    .line 59
    invoke-virtual {p0, p1}, Landroid/content/Context;->startActivity(Landroid/content/Intent;)V

    .line 60
    .line 61
    .line 62
    return-void
.end method

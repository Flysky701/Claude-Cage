.class public Ltop/niunaijun/blackbox/fake/service/IJobServiceProxy$Cancel;
.super Ltop/niunaijun/blackbox/fake/hook/MethodHook;
.source "r8-map-id-b030d4079bf46d1be0bde84446c3eaf9c7aec13dc1c4fe379a76cc83ba4f4ecf"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Ltop/niunaijun/blackbox/fake/service/IJobServiceProxy;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x9
    name = "Cancel"
.end annotation

.annotation runtime Ltop/niunaijun/blackbox/fake/hook/ProxyMethod;
    value = "cancel"
.end annotation


# direct methods
.method public constructor <init>()V
    .locals 0

    .line 1
    invoke-direct {p0}, Ltop/niunaijun/blackbox/fake/hook/MethodHook;-><init>()V

    .line 2
    .line 3
    .line 4
    return-void
.end method


# virtual methods
.method public hook(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 5

    .line 1
    const-string v0, "JobServiceStub"

    .line 2
    .line 3
    const/4 v1, 0x0

    sget-object v2, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    invoke-static {p2, v2}, Lio/github/leexeo/cage/space/GuestJobArguments;->index(Ljava/lang/reflect/Method;Ljava/lang/Class;)I

    move-result v1

    .line 4
    :try_start_0
    aget-object v2, p3, v1

    .line 5
    .line 6
    check-cast v2, Ljava/lang/Integer;

    .line 7
    .line 8
    if-nez v2, :cond_0

    .line 9
    .line 10
    const-string v1, "Cancel: JobId is null"

    .line 11
    .line 12
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 13
    .line 14
    .line 15
    invoke-virtual {p2, p1, p3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 16
    .line 17
    .line 18
    move-result-object p1

    .line 19
    return-object p1

    .line 20
    :catch_0
    move-exception v1

    .line 21
    goto :goto_0

    .line 22
    :cond_0
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getBJobManager()Ltop/niunaijun/blackbox/fake/frameworks/BJobManager;

    .line 23
    .line 24
    .line 25
    move-result-object v3

    .line 26
    invoke-static {}, Ltop/niunaijun/blackbox/app/BActivityThread;->getAppConfig()Ltop/niunaijun/blackbox/entity/AppConfig;

    .line 27
    .line 28
    .line 29
    move-result-object v4

    .line 30
    iget-object v4, v4, Ltop/niunaijun/blackbox/entity/AppConfig;->processName:Ljava/lang/String;

    .line 31
    .line 32
    invoke-virtual {v2}, Ljava/lang/Integer;->intValue()I

    .line 33
    .line 34
    .line 35
    move-result v2

    .line 36
    invoke-virtual {v3, v4, v2}, Ltop/niunaijun/blackbox/fake/frameworks/BJobManager;->cancel(Ljava/lang/String;I)I

    .line 37
    .line 38
    .line 39
    move-result v2

    .line 40
    invoke-static {v2}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 41
    .line 42
    .line 43
    move-result-object v2

    .line 44
    aput-object v2, p3, v1

    .line 45
    .line 46
    invoke-virtual {p2, p1, p3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 47
    .line 48
    .line 49
    move-result-object p1
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 50
    return-object p1

    .line 51
    :goto_0
    const-string v2, "Cancel: Error canceling job"

    .line 52
    .line 53
    invoke-static {v0, v2, v1}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 54
    .line 55
    .line 56
    invoke-virtual {p2, p1, p3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 57
    .line 58
    .line 59
    move-result-object p1

    .line 60
    return-object p1
.end method

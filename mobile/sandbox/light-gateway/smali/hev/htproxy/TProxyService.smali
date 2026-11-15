.class public final Lhev/htproxy/TProxyService;
.super Ljava/lang/Object;
.source "TProxyService.java"


# direct methods
.method static constructor <clinit>()V
    .locals 1

    .line 17
    const-string v0, "hev-socks5-tunnel"

    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

    .line 18
    return-void
.end method

.method private constructor <init>()V
    .locals 0

    .line 13
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 14
    return-void
.end method

.method public static native TProxyGetStats()[J
.end method

.method public static native TProxyIsRunning()Z
.end method

.method public static native TProxyStartService(Ljava/lang/String;I)Z
.end method

.method public static native TProxyStopService()Z
.end method

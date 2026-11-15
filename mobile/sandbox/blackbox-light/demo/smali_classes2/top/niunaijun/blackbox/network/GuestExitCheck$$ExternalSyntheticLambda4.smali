.class public final synthetic Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda4;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Ljava/net/URLStreamHandlerFactory;


# instance fields
.field public final synthetic f$0:Ljava/net/URLStreamHandler;


# direct methods
.method public synthetic constructor <init>(Ljava/net/URLStreamHandler;)V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda4;->f$0:Ljava/net/URLStreamHandler;

    return-void
.end method


# virtual methods
.method public final createURLStreamHandler(Ljava/lang/String;)Ljava/net/URLStreamHandler;
    .locals 1

    .line 0
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda4;->f$0:Ljava/net/URLStreamHandler;

    invoke-static {v0, p1}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->lambda$configureJavaProxy$3(Ljava/net/URLStreamHandler;Ljava/lang/String;)Ljava/net/URLStreamHandler;

    move-result-object p1

    return-object p1
.end method

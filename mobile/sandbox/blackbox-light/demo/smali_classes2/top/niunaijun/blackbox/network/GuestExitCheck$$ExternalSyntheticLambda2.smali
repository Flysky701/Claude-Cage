.class public final synthetic Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda2;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Landroid/os/Handler$Callback;


# instance fields
.field public final synthetic f$0:Z

.field public final synthetic f$1:Ljava/lang/String;

.field public final synthetic f$2:Ljava/util/concurrent/CompletableFuture;


# direct methods
.method public synthetic constructor <init>(ZLjava/lang/String;Ljava/util/concurrent/CompletableFuture;)V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-boolean p1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda2;->f$0:Z

    iput-object p2, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda2;->f$1:Ljava/lang/String;

    iput-object p3, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda2;->f$2:Ljava/util/concurrent/CompletableFuture;

    return-void
.end method


# virtual methods
.method public final handleMessage(Landroid/os/Message;)Z
    .locals 3

    .line 0
    iget-boolean v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda2;->f$0:Z

    iget-object v1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda2;->f$1:Ljava/lang/String;

    iget-object v2, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda2;->f$2:Ljava/util/concurrent/CompletableFuture;

    invoke-static {v0, v1, v2, p1}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->lambda$requestStream$5(ZLjava/lang/String;Ljava/util/concurrent/CompletableFuture;Landroid/os/Message;)Z

    move-result p1

    return p1
.end method

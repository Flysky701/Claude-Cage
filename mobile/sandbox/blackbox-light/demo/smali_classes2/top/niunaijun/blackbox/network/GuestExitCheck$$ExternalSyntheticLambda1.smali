.class public final synthetic Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda1;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Ljava/net/SocketImplFactory;


# instance fields
.field public final synthetic f$0:Ltop/niunaijun/blackbox/network/GuestExitCheck;

.field public final synthetic f$1:Ljava/io/File;


# direct methods
.method public synthetic constructor <init>(Ltop/niunaijun/blackbox/network/GuestExitCheck;Ljava/io/File;)V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda1;->f$0:Ltop/niunaijun/blackbox/network/GuestExitCheck;

    iput-object p2, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda1;->f$1:Ljava/io/File;

    return-void
.end method


# virtual methods
.method public final createSocketImpl()Ljava/net/SocketImpl;
    .locals 2

    .line 0
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda1;->f$0:Ltop/niunaijun/blackbox/network/GuestExitCheck;

    iget-object v1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda1;->f$1:Ljava/io/File;

    invoke-virtual {v0, v1}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->lambda$install$2$top-niunaijun-blackbox-network-GuestExitCheck(Ljava/io/File;)Ljava/net/SocketImpl;

    move-result-object v0

    return-object v0
.end method

.class public final synthetic Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda6;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Ljava/lang/Runnable;


# instance fields
.field public final synthetic f$0:Ltop/niunaijun/blackbox/network/GuestExitCheck;

.field public final synthetic f$1:Landroid/net/LocalSocket;


# direct methods
.method public synthetic constructor <init>(Ltop/niunaijun/blackbox/network/GuestExitCheck;Landroid/net/LocalSocket;)V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda6;->f$0:Ltop/niunaijun/blackbox/network/GuestExitCheck;

    iput-object p2, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda6;->f$1:Landroid/net/LocalSocket;

    return-void
.end method


# virtual methods
.method public final run()V
    .locals 2

    .line 0
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda6;->f$0:Ltop/niunaijun/blackbox/network/GuestExitCheck;

    iget-object v1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda6;->f$1:Landroid/net/LocalSocket;

    invoke-virtual {v0, v1}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->lambda$install$0$top-niunaijun-blackbox-network-GuestExitCheck(Landroid/net/LocalSocket;)V

    return-void
.end method

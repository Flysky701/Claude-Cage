.class public final synthetic Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda0;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Ljava/lang/Runnable;


# instance fields
.field public final synthetic f$0:Ltop/niunaijun/blackbox/network/GuestExitCheck;

.field public final synthetic f$1:Landroid/net/LocalServerSocket;

.field public final synthetic f$2:I

.field public final synthetic f$3:Landroid/net/LocalSocket;

.field public final synthetic f$4:Ljava/io/File;


# direct methods
.method public synthetic constructor <init>(Ltop/niunaijun/blackbox/network/GuestExitCheck;Landroid/net/LocalServerSocket;ILandroid/net/LocalSocket;Ljava/io/File;)V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda0;->f$0:Ltop/niunaijun/blackbox/network/GuestExitCheck;

    iput-object p2, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda0;->f$1:Landroid/net/LocalServerSocket;

    iput p3, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda0;->f$2:I

    iput-object p4, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda0;->f$3:Landroid/net/LocalSocket;

    iput-object p5, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda0;->f$4:Ljava/io/File;

    return-void
.end method


# virtual methods
.method public final run()V
    .locals 5

    .line 0
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda0;->f$0:Ltop/niunaijun/blackbox/network/GuestExitCheck;

    iget-object v1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda0;->f$1:Landroid/net/LocalServerSocket;

    iget v2, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda0;->f$2:I

    iget-object v3, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda0;->f$3:Landroid/net/LocalSocket;

    iget-object v4, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda0;->f$4:Ljava/io/File;

    invoke-virtual {v0, v1, v2, v3, v4}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->lambda$install$1$top-niunaijun-blackbox-network-GuestExitCheck(Landroid/net/LocalServerSocket;ILandroid/net/LocalSocket;Ljava/io/File;)V

    return-void
.end method

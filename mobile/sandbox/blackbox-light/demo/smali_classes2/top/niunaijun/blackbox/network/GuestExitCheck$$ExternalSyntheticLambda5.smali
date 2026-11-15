.class public final synthetic Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda5;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Ljava/lang/Runnable;


# instance fields
.field public final synthetic f$0:Ljava/io/DataInputStream;

.field public final synthetic f$1:Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;


# direct methods
.method public synthetic constructor <init>(Ljava/io/DataInputStream;Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;)V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda5;->f$0:Ljava/io/DataInputStream;

    iput-object p2, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda5;->f$1:Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;

    return-void
.end method


# virtual methods
.method public final run()V
    .locals 2

    .line 0
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda5;->f$0:Ljava/io/DataInputStream;

    iget-object v1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda5;->f$1:Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;

    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->lambda$forward$4(Ljava/io/DataInputStream;Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;)V

    return-void
.end method

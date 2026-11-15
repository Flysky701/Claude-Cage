.class public final synthetic Ltop/niunaijun/blackbox/network/GuestExitCheck$$ExternalSyntheticLambda3;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Ljava/util/function/BiConsumer;


# direct methods
.method public synthetic constructor <init>()V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method public final accept(Ljava/lang/Object;Ljava/lang/Object;)V
    .locals 0

    .line 0
    check-cast p1, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;

    check-cast p2, Ljava/lang/Throwable;

    invoke-static {p1, p2}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->lambda$requestStream$6(Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;Ljava/lang/Throwable;)V

    return-void
.end method

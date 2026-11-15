.class public final synthetic Lio/github/leexeo/cage/space/GuestNetwork$$ExternalSyntheticLambda2;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Ljava/util/function/Function;


# instance fields
.field public final synthetic f$0:Landroid/os/Messenger;


# direct methods
.method public synthetic constructor <init>(Landroid/os/Messenger;)V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lio/github/leexeo/cage/space/GuestNetwork$$ExternalSyntheticLambda2;->f$0:Landroid/os/Messenger;

    return-void
.end method


# virtual methods
.method public final apply(Ljava/lang/Object;)Ljava/lang/Object;
    .locals 1

    .line 0
    iget-object v0, p0, Lio/github/leexeo/cage/space/GuestNetwork$$ExternalSyntheticLambda2;->f$0:Landroid/os/Messenger;

    check-cast p1, Landroid/os/IBinder;

    invoke-static {v0, p1}, Lio/github/leexeo/cage/space/GuestNetwork;->lambda$relay$2(Landroid/os/Messenger;Landroid/os/IBinder;)Landroid/os/Messenger;

    move-result-object p1

    return-object p1
.end method

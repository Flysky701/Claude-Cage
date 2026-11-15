.class public final synthetic Lio/github/leexeo/cage/space/GuestNetwork$$ExternalSyntheticLambda0;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Landroid/os/Handler$Callback;


# instance fields
.field public final synthetic f$0:Landroid/os/Messenger;

.field public final synthetic f$1:Landroid/os/IBinder;


# direct methods
.method public synthetic constructor <init>(Landroid/os/Messenger;Landroid/os/IBinder;)V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lio/github/leexeo/cage/space/GuestNetwork$$ExternalSyntheticLambda0;->f$0:Landroid/os/Messenger;

    iput-object p2, p0, Lio/github/leexeo/cage/space/GuestNetwork$$ExternalSyntheticLambda0;->f$1:Landroid/os/IBinder;

    return-void
.end method


# virtual methods
.method public final handleMessage(Landroid/os/Message;)Z
    .locals 2

    .line 0
    iget-object v0, p0, Lio/github/leexeo/cage/space/GuestNetwork$$ExternalSyntheticLambda0;->f$0:Landroid/os/Messenger;

    iget-object v1, p0, Lio/github/leexeo/cage/space/GuestNetwork$$ExternalSyntheticLambda0;->f$1:Landroid/os/IBinder;

    invoke-static {v0, v1, p1}, Lio/github/leexeo/cage/space/GuestNetwork;->lambda$relay$0(Landroid/os/Messenger;Landroid/os/IBinder;Landroid/os/Message;)Z

    move-result p1

    return p1
.end method

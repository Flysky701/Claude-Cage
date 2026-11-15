.class final Lio/github/leexeo/cage/space/GuestAccounts$Peer;
.super Ljava/lang/Object;
.source "GuestAccounts.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/GuestAccounts;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "Peer"
.end annotation


# instance fields
.field final pid:I

.field final service:Landroid/os/IBinder;

.field final uid:I


# direct methods
.method constructor <init>(IILandroid/os/IBinder;)V
    .locals 0

    .line 29
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput p1, p0, Lio/github/leexeo/cage/space/GuestAccounts$Peer;->pid:I

    iput p2, p0, Lio/github/leexeo/cage/space/GuestAccounts$Peer;->uid:I

    iput-object p3, p0, Lio/github/leexeo/cage/space/GuestAccounts$Peer;->service:Landroid/os/IBinder;

    return-void
.end method

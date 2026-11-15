.class final Lio/github/leexeo/cage/space/GuestPendingActivity$Route;
.super Ljava/lang/Object;
.source "GuestPendingActivity.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/GuestPendingActivity;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "Route"
.end annotation


# instance fields
.field final created:J

.field final creator:Ljava/lang/Object;

.field final target:Landroid/content/Intent;


# direct methods
.method constructor <init>(Landroid/content/Intent;Ljava/lang/Object;)V
    .locals 2

    .line 64
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 63
    invoke-static {}, Landroid/os/SystemClock;->elapsedRealtime()J

    move-result-wide v0

    iput-wide v0, p0, Lio/github/leexeo/cage/space/GuestPendingActivity$Route;->created:J

    .line 64
    new-instance v0, Landroid/content/Intent;

    invoke-direct {v0, p1}, Landroid/content/Intent;-><init>(Landroid/content/Intent;)V

    iput-object v0, p0, Lio/github/leexeo/cage/space/GuestPendingActivity$Route;->target:Landroid/content/Intent;

    iput-object p2, p0, Lio/github/leexeo/cage/space/GuestPendingActivity$Route;->creator:Ljava/lang/Object;

    return-void
.end method

.class Lio/github/leexeo/cage/localcore/CoreActivity$1;
.super Ljava/lang/Object;
.source "CoreActivity.java"

# interfaces
.implements Ljava/lang/Runnable;


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/localcore/CoreActivity;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x0
    name = null
.end annotation


# instance fields
.field final synthetic this$0:Lio/github/leexeo/cage/localcore/CoreActivity;


# direct methods
.method constructor <init>(Lio/github/leexeo/cage/localcore/CoreActivity;)V
    .locals 0

    .line 19
    iput-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity$1;->this$0:Lio/github/leexeo/cage/localcore/CoreActivity;

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method public run()V
    .locals 3

    .line 20
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity$1;->this$0:Lio/github/leexeo/cage/localcore/CoreActivity;

    invoke-static {v0}, Lio/github/leexeo/cage/localcore/CoreActivity;->access$000(Lio/github/leexeo/cage/localcore/CoreActivity;)V

    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity$1;->this$0:Lio/github/leexeo/cage/localcore/CoreActivity;

    invoke-static {v0}, Lio/github/leexeo/cage/localcore/CoreActivity;->access$100(Lio/github/leexeo/cage/localcore/CoreActivity;)Landroid/os/Handler;

    move-result-object v0

    const-wide/16 v1, 0x190

    invoke-virtual {v0, p0, v1, v2}, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable;J)Z

    return-void
.end method

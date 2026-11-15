.class public final synthetic Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda0;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Ljava/lang/Runnable;


# instance fields
.field public final synthetic f$0:Landroid/app/Activity;

.field public final synthetic f$1:Landroid/widget/TextView;

.field public final synthetic f$2:Ljava/lang/Runnable;


# direct methods
.method public synthetic constructor <init>(Landroid/app/Activity;Landroid/widget/TextView;Ljava/lang/Runnable;)V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda0;->f$0:Landroid/app/Activity;

    iput-object p2, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda0;->f$1:Landroid/widget/TextView;

    iput-object p3, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda0;->f$2:Ljava/lang/Runnable;

    return-void
.end method


# virtual methods
.method public final run()V
    .locals 3

    .line 0
    iget-object v0, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda0;->f$0:Landroid/app/Activity;

    iget-object v1, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda0;->f$1:Landroid/widget/TextView;

    iget-object v2, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda0;->f$2:Ljava/lang/Runnable;

    invoke-static {v0, v1, v2}, Lio/github/leexeo/cage/space/DemoNetworkCheck;->lambda$start$1(Landroid/app/Activity;Landroid/widget/TextView;Ljava/lang/Runnable;)V

    return-void
.end method

.class public final synthetic Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda1;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Ljava/lang/Runnable;


# instance fields
.field public final synthetic f$0:Landroid/app/Activity;

.field public final synthetic f$1:Landroid/widget/TextView;

.field public final synthetic f$2:Z

.field public final synthetic f$3:Z

.field public final synthetic f$4:Ljava/lang/Boolean;

.field public final synthetic f$5:Ljava/lang/Runnable;


# direct methods
.method public synthetic constructor <init>(Landroid/app/Activity;Landroid/widget/TextView;ZZLjava/lang/Boolean;Ljava/lang/Runnable;)V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda1;->f$0:Landroid/app/Activity;

    iput-object p2, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda1;->f$1:Landroid/widget/TextView;

    iput-boolean p3, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda1;->f$2:Z

    iput-boolean p4, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda1;->f$3:Z

    iput-object p5, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda1;->f$4:Ljava/lang/Boolean;

    iput-object p6, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda1;->f$5:Ljava/lang/Runnable;

    return-void
.end method


# virtual methods
.method public final run()V
    .locals 6

    .line 0
    iget-object v0, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda1;->f$0:Landroid/app/Activity;

    iget-object v1, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda1;->f$1:Landroid/widget/TextView;

    iget-boolean v2, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda1;->f$2:Z

    iget-boolean v3, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda1;->f$3:Z

    iget-object v4, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda1;->f$4:Ljava/lang/Boolean;

    iget-object v5, p0, Lio/github/leexeo/cage/space/DemoNetworkCheck$$ExternalSyntheticLambda1;->f$5:Ljava/lang/Runnable;

    invoke-static/range {v0 .. v5}, Lio/github/leexeo/cage/space/DemoNetworkCheck;->lambda$start$0(Landroid/app/Activity;Landroid/widget/TextView;ZZLjava/lang/Boolean;Ljava/lang/Runnable;)V

    return-void
.end method

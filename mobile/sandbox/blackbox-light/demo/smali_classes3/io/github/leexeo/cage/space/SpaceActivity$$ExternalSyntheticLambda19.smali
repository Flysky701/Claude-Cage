.class public final synthetic Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda19;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Ljava/lang/Runnable;


# instance fields
.field public final synthetic f$0:Lio/github/leexeo/cage/space/SpaceActivity;


# direct methods
.method public synthetic constructor <init>(Lio/github/leexeo/cage/space/SpaceActivity;)V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda19;->f$0:Lio/github/leexeo/cage/space/SpaceActivity;

    return-void
.end method


# virtual methods
.method public final run()V
    .locals 1

    .line 0
    iget-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda19;->f$0:Lio/github/leexeo/cage/space/SpaceActivity;

    invoke-virtual {v0}, Landroid/app/Activity;->finish()V

    return-void
.end method

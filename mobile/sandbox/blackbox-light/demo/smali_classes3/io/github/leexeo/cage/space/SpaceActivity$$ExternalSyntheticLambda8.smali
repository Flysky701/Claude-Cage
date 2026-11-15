.class public final synthetic Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda8;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Ljava/lang/Runnable;


# instance fields
.field public final synthetic f$0:Lio/github/leexeo/cage/space/SpaceActivity;

.field public final synthetic f$1:Ljava/lang/String;

.field public final synthetic f$2:Z


# direct methods
.method public synthetic constructor <init>(Lio/github/leexeo/cage/space/SpaceActivity;Ljava/lang/String;Z)V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda8;->f$0:Lio/github/leexeo/cage/space/SpaceActivity;

    iput-object p2, p0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda8;->f$1:Ljava/lang/String;

    iput-boolean p3, p0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda8;->f$2:Z

    return-void
.end method


# virtual methods
.method public final run()V
    .locals 3

    .line 0
    iget-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda8;->f$0:Lio/github/leexeo/cage/space/SpaceActivity;

    iget-object v1, p0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda8;->f$1:Ljava/lang/String;

    iget-boolean v2, p0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda8;->f$2:Z

    invoke-virtual {v0, v1, v2}, Lio/github/leexeo/cage/space/SpaceActivity;->lambda$openReady$10$io-github-leexeo-cage-space-SpaceActivity(Ljava/lang/String;Z)V

    return-void
.end method

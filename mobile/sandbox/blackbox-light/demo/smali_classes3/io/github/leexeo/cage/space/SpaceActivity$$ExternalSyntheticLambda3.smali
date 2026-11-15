.class public final synthetic Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda3;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Ljava/lang/Runnable;


# instance fields
.field public final synthetic f$0:Lio/github/leexeo/cage/space/SpaceActivity;

.field public final synthetic f$1:I


# direct methods
.method public synthetic constructor <init>(Lio/github/leexeo/cage/space/SpaceActivity;I)V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda3;->f$0:Lio/github/leexeo/cage/space/SpaceActivity;

    iput p2, p0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda3;->f$1:I

    return-void
.end method


# virtual methods
.method public final run()V
    .locals 2

    .line 0
    iget-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda3;->f$0:Lio/github/leexeo/cage/space/SpaceActivity;

    iget v1, p0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda3;->f$1:I

    invoke-virtual {v0, v1}, Lio/github/leexeo/cage/space/SpaceActivity;->lambda$refresh$8$io-github-leexeo-cage-space-SpaceActivity(I)V

    return-void
.end method

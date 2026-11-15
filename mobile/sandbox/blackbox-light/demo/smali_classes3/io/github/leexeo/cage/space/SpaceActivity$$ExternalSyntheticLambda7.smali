.class public final synthetic Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda7;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Ljava/lang/Runnable;


# instance fields
.field public final synthetic f$0:Lio/github/leexeo/cage/space/SpaceActivity;

.field public final synthetic f$1:Ljava/util/LinkedHashSet;


# direct methods
.method public synthetic constructor <init>(Lio/github/leexeo/cage/space/SpaceActivity;Ljava/util/LinkedHashSet;)V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda7;->f$0:Lio/github/leexeo/cage/space/SpaceActivity;

    iput-object p2, p0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda7;->f$1:Ljava/util/LinkedHashSet;

    return-void
.end method


# virtual methods
.method public final run()V
    .locals 2

    .line 0
    iget-object v0, p0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda7;->f$0:Lio/github/leexeo/cage/space/SpaceActivity;

    iget-object v1, p0, Lio/github/leexeo/cage/space/SpaceActivity$$ExternalSyntheticLambda7;->f$1:Ljava/util/LinkedHashSet;

    invoke-virtual {v0, v1}, Lio/github/leexeo/cage/space/SpaceActivity;->lambda$onActivityResult$16$io-github-leexeo-cage-space-SpaceActivity(Ljava/util/LinkedHashSet;)V

    return-void
.end method

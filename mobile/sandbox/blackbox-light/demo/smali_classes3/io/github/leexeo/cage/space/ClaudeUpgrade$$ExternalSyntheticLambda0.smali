.class public final synthetic Lio/github/leexeo/cage/space/ClaudeUpgrade$$ExternalSyntheticLambda0;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Ljava/util/Comparator;


# direct methods
.method public synthetic constructor <init>()V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method public final compare(Ljava/lang/Object;Ljava/lang/Object;)I
    .locals 0

    .line 0
    check-cast p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;

    check-cast p2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;

    invoke-static {p1, p2}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->lambda$scan$0(Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;)I

    move-result p1

    return p1
.end method

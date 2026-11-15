.class final Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;
.super Ljava/lang/Object;
.source "ClaudeUpgrade.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/ClaudeUpgrade;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "Entry"
.end annotation


# instance fields
.field directory:Z

.field gid:I

.field hash:Ljava/lang/String;

.field mode:I

.field modified:J

.field path:Ljava/lang/String;

.field size:J


# direct methods
.method private constructor <init>()V
    .locals 0

    .line 669
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method synthetic constructor <init>(Lio/github/leexeo/cage/space/ClaudeUpgrade$1;)V
    .locals 0

    .line 669
    invoke-direct {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;-><init>()V

    return-void
.end method

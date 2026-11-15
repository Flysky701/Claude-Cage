.class final Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;
.super Ljava/lang/Object;
.source "ClaudeUpgrade.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/ClaudeUpgrade;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "Journal"
.end annotation


# instance fields
.field activeHash:Ljava/lang/String;

.field backupHash:Ljava/lang/String;

.field directory:Ljava/io/File;

.field id:Ljava/lang/String;

.field next:Lio/github/leexeo/cage/space/ClaudeBundle$State;

.field old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

.field phase:Ljava/lang/String;

.field uid:I


# direct methods
.method private constructor <init>()V
    .locals 0

    .line 640
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method synthetic constructor <init>(Lio/github/leexeo/cage/space/ClaudeUpgrade$1;)V
    .locals 0

    .line 640
    invoke-direct {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;-><init>()V

    return-void
.end method

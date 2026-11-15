.class final Lio/github/leexeo/cage/space/ClaudeBundle$Record;
.super Ljava/lang/Object;
.source "ClaudeBundle.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/ClaudeBundle;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x18
    name = "Record"
.end annotation


# instance fields
.field name:Ljava/lang/String;

.field sha256:Ljava/lang/String;

.field size:J

.field split:Ljava/lang/String;


# direct methods
.method constructor <init>()V
    .locals 1

    .line 750
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    const-string v0, ""

    iput-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->split:Ljava/lang/String;

    return-void
.end method

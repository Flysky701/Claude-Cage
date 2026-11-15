.class final Lio/github/leexeo/cage/space/ClaudeBundle$State;
.super Ljava/lang/Object;
.source "ClaudeBundle.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/ClaudeBundle;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x18
    name = "State"
.end annotation


# instance fields
.field final apks:Ljava/util/List;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/List<",
            "Lio/github/leexeo/cage/space/ClaudeBundle$Record;",
            ">;"
        }
    .end annotation
.end field

.field directory:Ljava/lang/String;

.field directoryFile:Ljava/io/File;

.field final libraries:Ljava/util/List;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/List<",
            "Lio/github/leexeo/cage/space/ClaudeBundle$Record;",
            ">;"
        }
    .end annotation
.end field

.field signer:Ljava/lang/String;

.field version:J

.field versionName:Ljava/lang/String;


# direct methods
.method constructor <init>()V
    .locals 1

    .line 744
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 748
    new-instance v0, Ljava/util/ArrayList;

    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V

    iput-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->apks:Ljava/util/List;

    new-instance v0, Ljava/util/ArrayList;

    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V

    iput-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->libraries:Ljava/util/List;

    return-void
.end method

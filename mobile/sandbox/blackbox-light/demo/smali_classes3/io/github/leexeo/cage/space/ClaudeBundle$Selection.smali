.class final Lio/github/leexeo/cage/space/ClaudeBundle$Selection;
.super Ljava/lang/Object;
.source "ClaudeBundle.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/ClaudeBundle;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "Selection"
.end annotation


# instance fields
.field final apks:Ljava/util/List;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/List<",
            "Lio/github/leexeo/cage/space/ClaudeBundle$Apk;",
            ">;"
        }
    .end annotation
.end field

.field final libraries:Ljava/util/List;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/List<",
            "Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;",
            ">;"
        }
    .end annotation
.end field

.field signer:Ljava/lang/String;

.field version:J

.field versionName:Ljava/lang/String;


# direct methods
.method private constructor <init>()V
    .locals 1

    .line 761
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 764
    new-instance v0, Ljava/util/ArrayList;

    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V

    iput-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->apks:Ljava/util/List;

    .line 765
    new-instance v0, Ljava/util/ArrayList;

    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V

    iput-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;->libraries:Ljava/util/List;

    return-void
.end method

.method synthetic constructor <init>(Lio/github/leexeo/cage/space/ClaudeBundle$1;)V
    .locals 0

    .line 761
    invoke-direct {p0}, Lio/github/leexeo/cage/space/ClaudeBundle$Selection;-><init>()V

    return-void
.end method

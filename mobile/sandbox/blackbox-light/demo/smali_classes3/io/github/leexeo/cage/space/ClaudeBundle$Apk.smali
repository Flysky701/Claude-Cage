.class final Lio/github/leexeo/cage/space/ClaudeBundle$Apk;
.super Ljava/lang/Object;
.source "ClaudeBundle.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/ClaudeBundle;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "Apk"
.end annotation


# instance fields
.field file:Ljava/io/File;

.field hasCode:Z

.field minSdk:I

.field nativeFiles:Ljava/util/List;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/List<",
            "Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;",
            ">;"
        }
    .end annotation
.end field

.field pkg:Ljava/lang/String;

.field required:Ljava/util/Set;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/Set<",
            "Ljava/lang/String;",
            ">;"
        }
    .end annotation
.end field

.field sha256:Ljava/lang/String;

.field signer:Ljava/lang/String;

.field size:J

.field split:Ljava/lang/String;

.field types:Ljava/util/Set;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/Set<",
            "Ljava/lang/String;",
            ">;"
        }
    .end annotation
.end field

.field version:J

.field versionName:Ljava/lang/String;


# direct methods
.method private constructor <init>()V
    .locals 1

    .line 751
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 753
    const-string v0, ""

    iput-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->split:Ljava/lang/String;

    iput-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->versionName:Ljava/lang/String;

    .line 755
    const/4 v0, 0x1

    iput v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->minSdk:I

    .line 757
    invoke-static {}, Ljava/util/Collections;->emptySet()Ljava/util/Set;

    move-result-object v0

    iput-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->required:Ljava/util/Set;

    invoke-static {}, Ljava/util/Collections;->emptySet()Ljava/util/Set;

    move-result-object v0

    iput-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->types:Ljava/util/Set;

    .line 758
    invoke-static {}, Ljava/util/Collections;->emptyList()Ljava/util/List;

    move-result-object v0

    iput-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;->nativeFiles:Ljava/util/List;

    return-void
.end method

.method synthetic constructor <init>(Lio/github/leexeo/cage/space/ClaudeBundle$1;)V
    .locals 0

    .line 751
    invoke-direct {p0}, Lio/github/leexeo/cage/space/ClaudeBundle$Apk;-><init>()V

    return-void
.end method

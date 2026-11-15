.class final Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;
.super Ljava/lang/Object;
.source "ClaudeBundle.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/ClaudeBundle;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "NativeFile"
.end annotation


# instance fields
.field entry:Ljava/lang/String;

.field name:Ljava/lang/String;

.field owner:Ljava/io/File;

.field sha256:Ljava/lang/String;

.field size:J


# direct methods
.method private constructor <init>()V
    .locals 0

    .line 760
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method synthetic constructor <init>(Lio/github/leexeo/cage/space/ClaudeBundle$1;)V
    .locals 0

    .line 760
    invoke-direct {p0}, Lio/github/leexeo/cage/space/ClaudeBundle$NativeFile;-><init>()V

    return-void
.end method

.class final Lio/github/leexeo/cage/space/ClaudeBundle$CountingInputStream;
.super Ljava/io/FilterInputStream;
.source "ClaudeBundle.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/ClaudeBundle;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "CountingInputStream"
.end annotation


# instance fields
.field count:J


# direct methods
.method constructor <init>(Ljava/io/InputStream;)V
    .locals 0

    .line 769
    invoke-direct {p0, p1}, Ljava/io/FilterInputStream;-><init>(Ljava/io/InputStream;)V

    return-void
.end method


# virtual methods
.method public read([BII)I
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 771
    iget-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$CountingInputStream;->in:Ljava/io/InputStream;

    invoke-virtual {v0, p1, p2, p3}, Ljava/io/InputStream;->read([BII)I

    move-result p1

    .line 772
    if-lez p1, :cond_0

    iget-wide p2, p0, Lio/github/leexeo/cage/space/ClaudeBundle$CountingInputStream;->count:J

    int-to-long v0, p1

    add-long/2addr p2, v0

    iput-wide p2, p0, Lio/github/leexeo/cage/space/ClaudeBundle$CountingInputStream;->count:J

    .line 773
    :cond_0
    return p1
.end method

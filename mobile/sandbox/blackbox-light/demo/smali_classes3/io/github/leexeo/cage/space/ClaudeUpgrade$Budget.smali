.class final Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;
.super Ljava/lang/Object;
.source "ClaudeUpgrade.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/ClaudeUpgrade;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "Budget"
.end annotation


# instance fields
.field bytes:J

.field entries:I


# direct methods
.method private constructor <init>()V
    .locals 0

    .line 647
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method synthetic constructor <init>(Lio/github/leexeo/cage/space/ClaudeUpgrade$1;)V
    .locals 0

    .line 647
    invoke-direct {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;-><init>()V

    return-void
.end method


# virtual methods
.method add(J)V
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 651
    const-wide/16 v0, 0x0

    cmp-long v0, p1, v0

    if-ltz v0, :cond_0

    const-wide v0, 0x80000000L

    cmp-long v2, p1, v0

    if-gtz v2, :cond_0

    iget v2, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;->entries:I

    add-int/lit8 v2, v2, 0x1

    iput v2, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;->entries:I

    const v3, 0xc350

    if-gt v2, v3, :cond_0

    iget-wide v2, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;->bytes:J

    sub-long/2addr v0, p1

    cmp-long v0, v2, v0

    if-gtz v0, :cond_0

    .line 653
    iget-wide v0, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;->bytes:J

    add-long/2addr v0, p1

    iput-wide v0, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;->bytes:J

    .line 654
    return-void

    .line 652
    :cond_0
    new-instance p1, Ljava/io/IOException;

    const-string p2, "Claude \u6570\u636e\u8d85\u51fa\u672c\u6b21\u53ef\u5b89\u5168\u5907\u4efd\u8303\u56f4\uff0c\u672a\u5f00\u59cb\u8986\u76d6\u3002"

    invoke-direct {p1, p2}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1
.end method

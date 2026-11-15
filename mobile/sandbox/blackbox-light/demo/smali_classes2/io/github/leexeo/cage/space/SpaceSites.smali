.class public final Lio/github/leexeo/cage/space/SpaceSites;
.super Ljava/lang/Object;
.source "SpaceSites.java"


# static fields
.field private static final DOMAINS:[Ljava/lang/String;


# direct methods
.method static constructor <clinit>()V
    .locals 10

    .line 7
    const-string v8, "claude.com"

    const-string v9, "claudeusercontent.com"

    const-string v0, "google.com"

    const-string v1, "googleapis.com"

    const-string v2, "gstatic.com"

    const-string v3, "googleusercontent.com"

    const-string v4, "gvt1.com"

    const-string v5, "ggpht.com"

    const-string v6, "anthropic.com"

    const-string v7, "claude.ai"

    filled-new-array/range {v0 .. v9}, [Ljava/lang/String;

    move-result-object v0

    sput-object v0, Lio/github/leexeo/cage/space/SpaceSites;->DOMAINS:[Ljava/lang/String;

    return-void
.end method

.method public constructor <init>()V
    .locals 0

    .line 6
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static allows(Ljava/lang/String;)Z
    .locals 7

    .line 13
    const/4 v0, 0x0

    if-eqz p0, :cond_5

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v1

    const/16 v2, 0xfd

    if-le v1, v2, :cond_0

    goto :goto_2

    .line 14
    :cond_0
    sget-object v1, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    invoke-virtual {p0, v1}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object p0

    .line 16
    const-string v1, "[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+"

    invoke-virtual {p0, v1}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v1

    if-nez v1, :cond_1

    return v0

    .line 17
    :cond_1
    sget-object v1, Lio/github/leexeo/cage/space/SpaceSites;->DOMAINS:[Ljava/lang/String;

    array-length v2, v1

    move v3, v0

    :goto_0
    if-ge v3, v2, :cond_4

    aget-object v4, v1, v3

    .line 18
    invoke-virtual {p0, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v5

    if-nez v5, :cond_3

    new-instance v5, Ljava/lang/StringBuilder;

    invoke-direct {v5}, Ljava/lang/StringBuilder;-><init>()V

    const-string v6, "."

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    invoke-virtual {v5, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v4

    invoke-virtual {p0, v4}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v4

    if-eqz v4, :cond_2

    goto :goto_1

    .line 17
    :cond_2
    add-int/lit8 v3, v3, 0x1

    goto :goto_0

    .line 18
    :cond_3
    :goto_1
    const/4 p0, 0x1

    return p0

    .line 20
    :cond_4
    return v0

    .line 13
    :cond_5
    :goto_2
    return v0
.end method

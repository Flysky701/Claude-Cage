.class final Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;
.super Ljava/lang/Object;
.source "ClaudeUpgrade.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lio/github/leexeo/cage/space/ClaudeUpgrade;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "Tree"
.end annotation


# instance fields
.field final entries:Ljava/util/List;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/List<",
            "Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;",
            ">;"
        }
    .end annotation
.end field

.field name:Ljava/lang/String;

.field present:Z


# direct methods
.method private constructor <init>()V
    .locals 1

    .line 657
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 660
    new-instance v0, Ljava/util/ArrayList;

    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V

    iput-object v0, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->entries:Ljava/util/List;

    return-void
.end method

.method synthetic constructor <init>(Lio/github/leexeo/cage/space/ClaudeUpgrade$1;)V
    .locals 0

    .line 657
    invoke-direct {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;-><init>()V

    return-void
.end method


# virtual methods
.method json()Lorg/json/JSONObject;
    .locals 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 662
    new-instance v0, Lorg/json/JSONArray;

    invoke-direct {v0}, Lorg/json/JSONArray;-><init>()V

    .line 663
    iget-object v1, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->entries:Ljava/util/List;

    invoke-interface {v1}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v1

    :goto_0
    invoke-interface {v1}, Ljava/util/Iterator;->hasNext()Z

    move-result v2

    if-eqz v2, :cond_0

    invoke-interface {v1}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;

    new-instance v3, Lorg/json/JSONObject;

    invoke-direct {v3}, Lorg/json/JSONObject;-><init>()V

    const-string v4, "path"

    iget-object v5, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    invoke-virtual {v3, v4, v5}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v3

    const-string v4, "directory"

    iget-boolean v5, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->directory:Z

    invoke-virtual {v3, v4, v5}, Lorg/json/JSONObject;->put(Ljava/lang/String;Z)Lorg/json/JSONObject;

    move-result-object v3

    iget v4, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->mode:I

    .line 664
    const-string v5, "mode"

    invoke-virtual {v3, v5, v4}, Lorg/json/JSONObject;->put(Ljava/lang/String;I)Lorg/json/JSONObject;

    move-result-object v3

    const-string v4, "gid"

    iget v5, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->gid:I

    invoke-virtual {v3, v4, v5}, Lorg/json/JSONObject;->put(Ljava/lang/String;I)Lorg/json/JSONObject;

    move-result-object v3

    const-string v4, "modified"

    iget-wide v5, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->modified:J

    invoke-virtual {v3, v4, v5, v6}, Lorg/json/JSONObject;->put(Ljava/lang/String;J)Lorg/json/JSONObject;

    move-result-object v3

    const-string v4, "size"

    iget-wide v5, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->size:J

    invoke-virtual {v3, v4, v5, v6}, Lorg/json/JSONObject;->put(Ljava/lang/String;J)Lorg/json/JSONObject;

    move-result-object v3

    const-string v4, "sha256"

    iget-object v2, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->hash:Ljava/lang/String;

    invoke-virtual {v3, v4, v2}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v2

    .line 663
    invoke-virtual {v0, v2}, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;

    goto :goto_0

    .line 665
    :cond_0
    new-instance v1, Lorg/json/JSONObject;

    invoke-direct {v1}, Lorg/json/JSONObject;-><init>()V

    const-string v2, "name"

    iget-object v3, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    invoke-virtual {v1, v2, v3}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v1

    const-string v2, "present"

    iget-boolean v3, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->present:Z

    invoke-virtual {v1, v2, v3}, Lorg/json/JSONObject;->put(Ljava/lang/String;Z)Lorg/json/JSONObject;

    move-result-object v1

    const-string v2, "entries"

    invoke-virtual {v1, v2, v0}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v0

    return-object v0
.end method

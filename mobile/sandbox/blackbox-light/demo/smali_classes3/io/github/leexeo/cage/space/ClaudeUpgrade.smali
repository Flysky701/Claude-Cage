.class final Lio/github/leexeo/cage/space/ClaudeUpgrade;
.super Ljava/lang/Object;
.source "ClaudeUpgrade.java"


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;,
        Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;,
        Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;,
        Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;
    }
.end annotation


# static fields
.field private static final MAX_BACKUP:J = 0x80000000L

.field private static final MAX_ENTRIES:I = 0xc350

.field private static final MAX_MANIFEST:I = 0x1000000

.field private static final PENDING:Ljava/lang/String; = "pending-upgrade.json"

.field private static final PHASES:Ljava/util/Set;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/Set<",
            "Ljava/lang/String;",
            ">;"
        }
    .end annotation
.end field

.field private static final TREES:[Ljava/lang/String;


# direct methods
.method static constructor <clinit>()V
    .locals 8

    .line 35
    const-string v0, "user"

    const-string v1, "user-de"

    const-string v2, "app"

    filled-new-array {v2, v0, v1}, [Ljava/lang/String;

    move-result-object v0

    sput-object v0, Lio/github/leexeo/cage/space/ClaudeUpgrade;->TREES:[Ljava/lang/String;

    .line 36
    new-instance v0, Ljava/util/HashSet;

    const-string v6, "restored"

    const-string v7, "aborted"

    const-string v1, "prepared"

    const-string v2, "backed-up"

    const-string v3, "installing"

    const-string v4, "restoring"

    const-string v5, "committed"

    filled-new-array/range {v1 .. v7}, [Ljava/lang/String;

    move-result-object v1

    invoke-static {v1}, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;

    move-result-object v1

    invoke-direct {v0, v1}, Ljava/util/HashSet;-><init>(Ljava/util/Collection;)V

    sput-object v0, Lio/github/leexeo/cage/space/ClaudeUpgrade;->PHASES:Ljava/util/Set;

    return-void
.end method

.method private constructor <init>()V
    .locals 0

    .line 39
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method static allowRegistration(Landroid/content/Context;Ljava/io/File;)Z
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 54
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->readJournal(Landroid/content/Context;)Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;

    move-result-object v0

    .line 55
    iget-object v1, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    iget-object v0, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->next:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    .line 56
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->privateBase(Landroid/content/Context;)Ljava/io/File;

    move-result-object p0

    .line 57
    invoke-static {p1, p0, v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->matchesBase(Ljava/io/File;Ljava/io/File;Lio/github/leexeo/cage/space/ClaudeBundle$State;)Z

    move-result v2

    const/4 v3, 0x1

    if-nez v2, :cond_3

    invoke-static {p1, p0, v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->matchesBase(Ljava/io/File;Ljava/io/File;Lio/github/leexeo/cage/space/ClaudeBundle$State;)Z

    move-result p0

    if-eqz p0, :cond_0

    goto :goto_2

    .line 58
    :cond_0
    iget-object p0, v1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directoryFile:Ljava/io/File;

    const-string v2, "base.apk"

    invoke-static {p0, v2}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object p0

    invoke-static {p1, p0, v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->matchesBase(Ljava/io/File;Ljava/io/File;Lio/github/leexeo/cage/space/ClaudeBundle$State;)Z

    move-result p0

    if-nez p0, :cond_2

    iget-object p0, v0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directoryFile:Ljava/io/File;

    .line 59
    invoke-static {p0, v2}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object p0

    invoke-static {p1, p0, v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->matchesBase(Ljava/io/File;Ljava/io/File;Lio/github/leexeo/cage/space/ClaudeBundle$State;)Z

    move-result p0

    if-eqz p0, :cond_1

    goto :goto_0

    :cond_1
    const/4 v3, 0x0

    goto :goto_1

    :cond_2
    :goto_0
    nop

    .line 58
    :goto_1
    return v3

    .line 57
    :cond_3
    :goto_2
    return v3
.end method

.method private static backup(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)Ljava/util/List;
    .locals 8
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Landroid/content/Context;",
            "Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;",
            ")",
            "Ljava/util/List<",
            "Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;",
            ">;"
        }
    .end annotation

    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 335
    new-instance v0, Ljava/util/ArrayList;

    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V

    .line 336
    new-instance v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;

    const/4 v2, 0x0

    invoke-direct {v1, v2}, Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;-><init>(Lio/github/leexeo/cage/space/ClaudeUpgrade$1;)V

    .line 337
    sget-object v2, Lio/github/leexeo/cage/space/ClaudeUpgrade;->TREES:[Ljava/lang/String;

    array-length v3, v2

    const/4 v4, 0x0

    :goto_0
    if-ge v4, v3, :cond_0

    aget-object v5, v2, v4

    invoke-static {p0, v5}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->live(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object v6

    invoke-static {v5, v6, v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->scan(Ljava/lang/String;Ljava/io/File;Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;)Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;

    move-result-object v5

    invoke-interface {v0, v5}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    add-int/lit8 v4, v4, 0x1

    goto :goto_0

    .line 339
    :cond_0
    iget-object v2, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    invoke-virtual {v2}, Ljava/io/File;->getUsableSpace()J

    move-result-wide v2

    iget-wide v4, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;->bytes:J

    const-wide/16 v6, 0x2

    mul-long/2addr v4, v6

    const-wide/32 v6, 0xa000000

    add-long/2addr v4, v6

    const-wide/32 v6, 0x4000000

    add-long/2addr v4, v6

    cmp-long v1, v2, v4

    if-ltz v1, :cond_3

    .line 341
    invoke-interface {v0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v1

    :goto_1
    invoke-interface {v1}, Ljava/util/Iterator;->hasNext()Z

    move-result v2

    if-eqz v2, :cond_1

    invoke-interface {v1}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;

    .line 342
    iget-object v3, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    invoke-static {p0, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->live(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object v3

    iget-object v4, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    invoke-static {p1, v4}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->backupRoot(Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;Ljava/lang/String;)Ljava/io/File;

    move-result-object v4

    invoke-static {v2, v3, v4}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->copyTree(Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;Ljava/io/File;Ljava/io/File;)V

    .line 343
    iget-object v3, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    invoke-static {p0, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->live(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object v3

    invoke-static {v2, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->verifyTree(Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;Ljava/io/File;)V

    .line 344
    iget-object v3, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    invoke-static {p1, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->backupRoot(Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;Ljava/lang/String;)Ljava/io/File;

    move-result-object v3

    invoke-static {v2, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->verifyTree(Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;Ljava/io/File;)V

    .line 345
    goto :goto_1

    .line 346
    :cond_1
    new-instance p0, Lorg/json/JSONArray;

    invoke-direct {p0}, Lorg/json/JSONArray;-><init>()V

    .line 347
    invoke-interface {v0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v1

    :goto_2
    invoke-interface {v1}, Ljava/util/Iterator;->hasNext()Z

    move-result v2

    if-eqz v2, :cond_2

    invoke-interface {v1}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;

    invoke-virtual {v2}, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->json()Lorg/json/JSONObject;

    move-result-object v2

    invoke-virtual {p0, v2}, Lorg/json/JSONArray;->put(Ljava/lang/Object;)Lorg/json/JSONArray;

    goto :goto_2

    .line 348
    :cond_2
    iget-object v1, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    const-string v2, "backup.json"

    invoke-static {v1, v2}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v1

    new-instance v2, Lorg/json/JSONObject;

    invoke-direct {v2}, Lorg/json/JSONObject;-><init>()V

    .line 349
    const-string v3, "schema"

    const/4 v4, 0x2

    invoke-virtual {v2, v3, v4}, Lorg/json/JSONObject;->put(Ljava/lang/String;I)Lorg/json/JSONObject;

    move-result-object v2

    const-string v3, "trees"

    invoke-virtual {v2, v3, p0}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object p0

    invoke-virtual {p0}, Lorg/json/JSONObject;->toString()Ljava/lang/String;

    move-result-object p0

    sget-object v2, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-virtual {p0, v2}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object p0

    .line 348
    invoke-static {v1, p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->writeNew(Ljava/io/File;[B)V

    .line 350
    iget-object p0, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->syncDirectory(Ljava/io/File;)V

    .line 351
    return-object v0

    .line 340
    :cond_3
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u7a7a\u95f4\u4e0d\u8db3\u4ee5\u4fdd\u5b58\u5b8c\u6574\u5907\u4efd\u548c\u6062\u590d\u526f\u672c\uff0c\u672a\u5f00\u59cb\u5347\u7ea7\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static backupRoot(Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;Ljava/lang/String;)Ljava/io/File;
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 330
    sget-object v0, Lio/github/leexeo/cage/space/ClaudeUpgrade;->TREES:[Ljava/lang/String;

    invoke-static {v0}, Ljava/util/Arrays;->asList([Ljava/lang/Object;)Ljava/util/List;

    move-result-object v0

    invoke-interface {v0, p1}, Ljava/util/List;->contains(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_0

    .line 331
    iget-object p0, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "backup-"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-static {p0, p1}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object p0

    return-object p0

    .line 330
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u672a\u77e5 Claude \u5907\u4efd\u8303\u56f4\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static closeJournal(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 585
    const-string v0, "committed"

    iget-object v1, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_1

    const-string v0, "restored"

    iget-object v1, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_1

    const-string v0, "aborted"

    iget-object v1, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_0

    goto :goto_0

    .line 586
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u5347\u7ea7\u5c1a\u672a\u8fbe\u5230\u53ef\u7ed3\u675f\u72b6\u6001\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 587
    :cond_1
    :goto_0
    const/4 v0, 0x0

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->root(Landroid/content/Context;Z)Ljava/io/File;

    move-result-object p0

    .line 588
    const-string v0, "pending-upgrade.json.new"

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v0

    invoke-virtual {v0}, Ljava/io/File;->exists()Z

    move-result v0

    if-nez v0, :cond_3

    const-string v0, "pending-upgrade.json.bak"

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v0

    invoke-virtual {v0}, Ljava/io/File;->exists()Z

    move-result v0

    if-nez v0, :cond_3

    .line 590
    iget-object v0, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "closed-"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    iget-object v2, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v2, "-"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-static {}, Ljava/util/UUID;->randomUUID()Ljava/util/UUID;

    move-result-object v2

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v2, ".json"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v0

    .line 591
    const-string v1, "pending-upgrade.json"

    invoke-static {p0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v1

    invoke-virtual {v1, v0}, Ljava/io/File;->renameTo(Ljava/io/File;)Z

    move-result v0

    if-eqz v0, :cond_2

    .line 592
    iget-object p1, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    invoke-static {p1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->syncDirectory(Ljava/io/File;)V

    .line 593
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->syncDirectory(Ljava/io/File;)V

    .line 594
    return-void

    .line 591
    :cond_2
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u5347\u7ea7\u7ed3\u675f\u8bb0\u5f55\u672a\u5b8c\u6210\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 589
    :cond_3
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u5347\u7ea7\u8bb0\u5f55\u5c1a\u672a\u7a33\u5b9a\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static collect(Ljava/io/File;Ljava/io/File;Ljava/util/List;Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;I)V
    .locals 10
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/io/File;",
            "Ljava/io/File;",
            "Ljava/util/List<",
            "Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;",
            ">;",
            "Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;",
            "I)V"
        }
    .end annotation

    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 417
    const/16 v0, 0x40

    if-gt p4, v0, :cond_f

    .line 418
    invoke-static {p1}, Lio/github/leexeo/cage/space/ClaudeBundle;->exact(Ljava/io/File;)Ljava/io/File;

    .line 419
    invoke-virtual {p1}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object v0

    invoke-static {v0}, Landroid/system/Os;->lstat(Ljava/lang/String;)Landroid/system/StructStat;

    move-result-object v0

    .line 420
    iget v1, v0, Landroid/system/StructStat;->st_mode:I

    invoke-static {v1}, Landroid/system/OsConstants;->S_ISDIR(I)Z

    move-result v1

    .line 421
    iget v2, v0, Landroid/system/StructStat;->st_uid:I

    invoke-static {}, Landroid/os/Process;->myUid()I

    move-result v3

    const-wide/16 v4, 0x1

    const/4 v6, 0x0

    const/4 v7, 0x1

    if-ne v2, v3, :cond_9

    iget v2, v0, Landroid/system/StructStat;->st_mode:I

    and-int/lit16 v2, v2, 0xfff

    invoke-static {v1, v2}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->supportedMode(ZI)Z

    move-result v2

    if-eqz v2, :cond_9

    if-nez v1, :cond_0

    iget v2, v0, Landroid/system/StructStat;->st_mode:I

    .line 422
    invoke-static {v2}, Landroid/system/OsConstants;->S_ISREG(I)Z

    move-result v2

    if-eqz v2, :cond_9

    iget-wide v2, v0, Landroid/system/StructStat;->st_nlink:J

    cmp-long v2, v2, v4

    if-eqz v2, :cond_0

    goto/16 :goto_5

    .line 431
    :cond_0
    invoke-virtual {p1, p0}, Ljava/io/File;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_2

    if-eqz v1, :cond_1

    goto :goto_0

    :cond_1
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u6570\u636e\u6839\u8def\u5f84\u4e0d\u662f\u76ee\u5f55\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 432
    :cond_2
    :goto_0
    new-instance v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;

    const/4 v3, 0x0

    invoke-direct {v2, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;-><init>(Lio/github/leexeo/cage/space/ClaudeUpgrade$1;)V

    .line 433
    invoke-virtual {p1, p0}, Ljava/io/File;->equals(Ljava/lang/Object;)Z

    move-result v3

    const-string v4, ""

    if-eqz v3, :cond_3

    move-object v3, v4

    goto :goto_1

    :cond_3
    invoke-virtual {p1}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {p0}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object v5

    invoke-virtual {v5}, Ljava/lang/String;->length()I

    move-result v5

    add-int/2addr v5, v7

    invoke-virtual {v3, v5}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v3

    sget-char v5, Ljava/io/File;->separatorChar:C

    const/16 v8, 0x2f

    invoke-virtual {v3, v5, v8}, Ljava/lang/String;->replace(CC)Ljava/lang/String;

    move-result-object v3

    :goto_1
    iput-object v3, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    .line 434
    iget-object v3, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    invoke-static {v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->relative(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_8

    .line 435
    iput-boolean v1, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->directory:Z

    .line 436
    iget v3, v0, Landroid/system/StructStat;->st_mode:I

    and-int/lit16 v3, v3, 0xfff

    iput v3, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->mode:I

    .line 437
    iget v0, v0, Landroid/system/StructStat;->st_gid:I

    iput v0, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->gid:I

    .line 438
    invoke-virtual {p1}, Ljava/io/File;->lastModified()J

    move-result-wide v8

    iput-wide v8, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->modified:J

    .line 439
    if-eqz v1, :cond_4

    const-wide/16 v8, 0x0

    goto :goto_2

    :cond_4
    invoke-virtual {p1}, Ljava/io/File;->length()J

    move-result-wide v8

    :goto_2
    iput-wide v8, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->size:J

    .line 440
    iget-wide v8, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->size:J

    invoke-virtual {p3, v8, v9}, Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;->add(J)V

    .line 441
    if-eqz v1, :cond_5

    goto :goto_3

    :cond_5
    const-wide v3, 0x80000000L

    invoke-static {p1, v3, v4}, Lio/github/leexeo/cage/space/ClaudeBundle;->sha(Ljava/io/File;J)Ljava/lang/String;

    move-result-object v4

    :goto_3
    iput-object v4, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->hash:Ljava/lang/String;

    .line 442
    invoke-interface {p2, v2}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 443
    if-eqz v1, :cond_7

    .line 444
    invoke-virtual {p1}, Ljava/io/File;->listFiles()[Ljava/io/File;

    move-result-object p1

    .line 445
    if-eqz p1, :cond_6

    .line 446
    new-instance v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$$ExternalSyntheticLambda1;

    invoke-direct {v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade$$ExternalSyntheticLambda1;-><init>()V

    invoke-static {p1, v0}, Ljava/util/Arrays;->sort([Ljava/lang/Object;Ljava/util/Comparator;)V

    .line 447
    array-length v0, p1

    :goto_4
    if-ge v6, v0, :cond_7

    aget-object v1, p1, v6

    add-int/lit8 v2, p4, 0x1

    invoke-static {p0, v1, p2, p3, v2}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->collect(Ljava/io/File;Ljava/io/File;Ljava/util/List;Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;I)V

    add-int/lit8 v6, v6, 0x1

    goto :goto_4

    .line 445
    :cond_6
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u65e0\u6cd5\u5b8c\u6574\u8bfb\u53d6 Claude \u6570\u636e\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 449
    :cond_7
    return-void

    .line 434
    :cond_8
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u6570\u636e\u8def\u5f84\u65e0\u6548\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 423
    :cond_9
    :goto_5
    if-eqz v1, :cond_a

    const-string p0, "directory"

    goto :goto_6

    :cond_a
    iget p0, v0, Landroid/system/StructStat;->st_mode:I

    invoke-static {p0}, Landroid/system/OsConstants;->S_ISREG(I)Z

    move-result p0

    if-eqz p0, :cond_b

    const-string p0, "regular"

    goto :goto_6

    .line 424
    :cond_b
    iget p0, v0, Landroid/system/StructStat;->st_mode:I

    invoke-static {p0}, Landroid/system/OsConstants;->S_ISLNK(I)Z

    move-result p0

    if-eqz p0, :cond_c

    const-string p0, "link"

    goto :goto_6

    :cond_c
    const-string p0, "special"

    .line 425
    :goto_6
    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    const-string p2, "Claude backup rejected file state: kind="

    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string p1, " specialMask="

    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    iget p1, v0, Landroid/system/StructStat;->st_mode:I

    and-int/lit16 p1, p1, 0xe00

    .line 426
    invoke-static {p1}, Ljava/lang/Integer;->toOctalString(I)Ljava/lang/String;

    move-result-object p1

    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string p1, " multiLink="

    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    iget-wide p1, v0, Landroid/system/StructStat;->st_nlink:J

    cmp-long p1, p1, v4

    if-lez p1, :cond_d

    move p1, v7

    goto :goto_7

    :cond_d
    move p1, v6

    :goto_7
    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string p1, " ownerMatches="

    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    iget p1, v0, Landroid/system/StructStat;->st_uid:I

    .line 428
    invoke-static {}, Landroid/os/Process;->myUid()I

    move-result p2

    if-ne p1, p2, :cond_e

    move v6, v7

    :cond_e
    invoke-virtual {p0, v6}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    .line 425
    const-string p1, "CageDemo"

    invoke-static {p1, p0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 429
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u6570\u636e\u5305\u542b\u94fe\u63a5\u6216\u7279\u6b8a\u6587\u4ef6\uff0c\u5df2\u505c\u6b62\u81ea\u52a8\u5347\u7ea7\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 417
    :cond_f
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u6570\u636e\u76ee\u5f55\u8fc7\u6df1\uff0c\u672a\u5f00\u59cb\u8986\u76d6\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static copyTree(Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;Ljava/io/File;Ljava/io/File;)V
    .locals 11
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 472
    invoke-static {p2}, Lio/github/leexeo/cage/space/ClaudeBundle;->exact(Ljava/io/File;)Ljava/io/File;

    .line 473
    invoke-virtual {p2}, Ljava/io/File;->exists()Z

    move-result v0

    if-nez v0, :cond_c

    .line 474
    iget-boolean v0, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->present:Z

    if-nez v0, :cond_0

    return-void

    .line 475
    :cond_0
    iget-object v0, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->entries:Ljava/util/List;

    invoke-interface {v0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v0

    :goto_0
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z

    move-result v1

    const/4 v2, -0x1

    if-eqz v1, :cond_7

    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;

    .line 476
    iget-object v3, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    invoke-static {p2, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->descendant(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v3

    .line 477
    iget-boolean v4, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->directory:Z

    if-eqz v4, :cond_2

    .line 478
    invoke-virtual {v3}, Ljava/io/File;->mkdir()Z

    move-result v1

    if-eqz v1, :cond_1

    goto :goto_2

    :cond_1
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u65e0\u6cd5\u521b\u5efa Claude \u5907\u4efd\u76ee\u5f55\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 480
    :cond_2
    iget-object v4, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    invoke-static {p1, v4}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->descendant(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v4

    .line 481
    invoke-virtual {v3}, Ljava/io/File;->createNewFile()Z

    move-result v5

    if-eqz v5, :cond_6

    .line 482
    nop

    .line 483
    const/high16 v5, 0x10000

    new-array v5, v5, [B

    .line 484
    new-instance v6, Ljava/io/FileInputStream;

    invoke-direct {v6, v4}, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V

    :try_start_0
    new-instance v4, Ljava/io/FileOutputStream;

    invoke-direct {v4, v3}, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_2

    const-wide/16 v7, 0x0

    .line 485
    :goto_1
    :try_start_1
    invoke-virtual {v6, v5}, Ljava/io/InputStream;->read([B)I

    move-result v3

    if-eq v3, v2, :cond_4

    .line 486
    int-to-long v9, v3

    add-long/2addr v7, v9

    .line 487
    iget-wide v9, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->size:J

    cmp-long v9, v7, v9

    if-gtz v9, :cond_3

    .line 488
    const/4 v9, 0x0

    invoke-virtual {v4, v5, v9, v3}, Ljava/io/FileOutputStream;->write([BII)V

    goto :goto_1

    .line 487
    :cond_3
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u6570\u636e\u5728\u5907\u4efd\u671f\u95f4\u6539\u53d8\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 490
    :cond_4
    iget-wide v1, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->size:J

    cmp-long v1, v7, v1

    if-nez v1, :cond_5

    .line 491
    invoke-virtual {v4}, Ljava/io/FileOutputStream;->getFD()Ljava/io/FileDescriptor;

    move-result-object v1

    invoke-virtual {v1}, Ljava/io/FileDescriptor;->sync()V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 492
    :try_start_2
    invoke-virtual {v4}, Ljava/io/FileOutputStream;->close()V
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_2

    invoke-virtual {v6}, Ljava/io/InputStream;->close()V

    .line 494
    :goto_2
    goto :goto_0

    .line 490
    :cond_5
    :try_start_3
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u6570\u636e\u5907\u4efd\u4e0d\u5b8c\u6574\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_0

    .line 484
    :catchall_0
    move-exception p0

    :try_start_4
    invoke-virtual {v4}, Ljava/io/FileOutputStream;->close()V
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_1

    goto :goto_3

    :catchall_1
    move-exception p1

    :try_start_5
    invoke-virtual {p0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_3
    throw p0
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_2

    :catchall_2
    move-exception p0

    :try_start_6
    invoke-virtual {v6}, Ljava/io/InputStream;->close()V
    :try_end_6
    .catchall {:try_start_6 .. :try_end_6} :catchall_3

    goto :goto_4

    :catchall_3
    move-exception p1

    invoke-virtual {p0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_4
    throw p0

    .line 481
    :cond_6
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u62d2\u7edd\u8986\u76d6\u5df2\u6709 Claude \u5907\u4efd\u6587\u4ef6\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 496
    :cond_7
    iget-object p1, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->entries:Ljava/util/List;

    invoke-interface {p1}, Ljava/util/List;->size()I

    move-result p1

    add-int/lit8 p1, p1, -0x1

    :goto_5
    if-ltz p1, :cond_b

    .line 497
    iget-object v0, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->entries:Ljava/util/List;

    invoke-interface {v0, p1}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;

    .line 498
    iget-object v1, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    invoke-static {p2, v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->descendant(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v1

    .line 499
    invoke-virtual {v1}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object v3

    invoke-static {v3}, Landroid/system/Os;->lstat(Ljava/lang/String;)Landroid/system/StructStat;

    move-result-object v3

    iget v3, v3, Landroid/system/StructStat;->st_gid:I

    iget v4, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->gid:I

    if-eq v3, v4, :cond_8

    .line 500
    invoke-virtual {v1}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object v3

    iget v4, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->gid:I

    invoke-static {v3, v2, v4}, Landroid/system/Os;->chown(Ljava/lang/String;II)V

    .line 501
    :cond_8
    invoke-virtual {v1}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object v3

    iget v4, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->mode:I

    invoke-static {v3, v4}, Landroid/system/Os;->chmod(Ljava/lang/String;I)V

    .line 502
    iget-wide v3, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->modified:J

    invoke-virtual {v1, v3, v4}, Ljava/io/File;->setLastModified(J)Z

    move-result v3

    if-eqz v3, :cond_a

    .line 503
    iget-boolean v0, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->directory:Z

    if-eqz v0, :cond_9

    invoke-static {v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->syncDirectory(Ljava/io/File;)V

    .line 496
    :cond_9
    add-int/lit8 p1, p1, -0x1

    goto :goto_5

    .line 502
    :cond_a
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u65e0\u6cd5\u4fdd\u7559 Claude \u6587\u4ef6\u65f6\u95f4\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 505
    :cond_b
    invoke-virtual {p2}, Ljava/io/File;->getParentFile()Ljava/io/File;

    move-result-object p0

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->syncDirectory(Ljava/io/File;)V

    .line 506
    return-void

    .line 473
    :cond_c
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u62d2\u7edd\u8986\u76d6\u5df2\u6709 Claude \u5907\u4efd\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static descendant(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 464
    invoke-static {p1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->relative(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_3

    .line 465
    invoke-virtual {p1}, Ljava/lang/String;->isEmpty()Z

    move-result v0

    if-eqz v0, :cond_0

    move-object v0, p0

    goto :goto_0

    :cond_0
    new-instance v0, Ljava/io/File;

    invoke-direct {v0, p0, p1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    :goto_0
    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->exact(Ljava/io/File;)Ljava/io/File;

    move-result-object p1

    .line 466
    invoke-virtual {p1, p0}, Ljava/io/File;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_2

    invoke-virtual {p1}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object v0

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {p0}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object p0

    invoke-virtual {v1, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    sget-object v1, Ljava/io/File;->separator:Ljava/lang/String;

    invoke-virtual {p0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    invoke-virtual {v0, p0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result p0

    if-eqz p0, :cond_1

    goto :goto_1

    .line 467
    :cond_1
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u5907\u4efd\u8def\u5f84\u8d85\u51fa\u4e8b\u52a1\u8303\u56f4\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 468
    :cond_2
    :goto_1
    return-object p1

    .line 464
    :cond_3
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u4e0d\u5b89\u5168\u7684 Claude \u5907\u4efd\u8def\u5f84\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static failureCode(Ljava/lang/Throwable;)Ljava/lang/String;
    .locals 3

    .line 145
    const/4 v0, 0x0

    :goto_0
    if-eqz p0, :cond_a

    const/16 v1, 0x8

    if-ge v0, v1, :cond_a

    .line 146
    invoke-virtual {p0}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    move-result-object v1

    .line 147
    const-string v2, "\u79c1\u6709\u5b89\u88c5\u8def\u5f84\u5305\u542b\u94fe\u63a5\u6216\u8def\u5f84\u8df3\u8f6c\u3002"

    invoke-virtual {v2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_0

    const-string p0, "linked_path"

    return-object p0

    .line 148
    :cond_0
    const-string v2, "Claude \u6570\u636e\u5305\u542b\u94fe\u63a5\u6216\u7279\u6b8a\u6587\u4ef6\uff0c\u5df2\u505c\u6b62\u81ea\u52a8\u5347\u7ea7\u3002"

    invoke-virtual {v2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_1

    const-string p0, "unsupported_file_kind"

    return-object p0

    .line 149
    :cond_1
    const-string v2, "\u65e0\u6cd5\u4fdd\u7559 Claude \u6587\u4ef6\u65f6\u95f4\u3002"

    invoke-virtual {v2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_2

    const-string p0, "file_timestamp"

    return-object p0

    .line 150
    :cond_2
    const-string v2, "Claude \u6570\u636e\u76ee\u5f55\u96c6\u5408\u53d1\u751f\u53d8\u5316\u3002"

    invoke-virtual {v2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_3

    const-string p0, "data_paths_changed"

    return-object p0

    .line 151
    :cond_3
    const-string v2, "Claude \u6570\u636e\u5185\u5bb9\u6216\u6587\u4ef6\u5c5e\u6027\u6821\u9a8c\u5931\u8d25\u3002"

    invoke-virtual {v2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_4

    const-string p0, "data_or_metadata_changed"

    return-object p0

    .line 152
    :cond_4
    const-string v2, "Claude \u79c1\u6709\u5b89\u88c5\u7248\u672c\u6216\u539f\u5e94\u7528\u8eab\u4efd\u4e0d\u4e00\u81f4\u3002"

    invoke-virtual {v2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_5

    const-string p0, "package_identity"

    return-object p0

    .line 153
    :cond_5
    const-string v2, "\u7a7a\u95f4\u4e0d\u8db3\u4ee5\u4fdd\u5b58\u5b8c\u6574\u5907\u4efd\u548c\u6062\u590d\u526f\u672c\uff0c\u672a\u5f00\u59cb\u5347\u7ea7\u3002"

    invoke-virtual {v2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_6

    const-string p0, "backup_space"

    return-object p0

    .line 154
    :cond_6
    const-string v2, "Claude \u6765\u5bbe\u8fdb\u7a0b\u5c1a\u672a\u5b8c\u5168\u9000\u51fa\uff0c\u672a\u7ee7\u7eed\u6539\u52a8\u6570\u636e\u3002"

    invoke-virtual {v2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_7

    const-string p0, "guest_still_running"

    return-object p0

    .line 155
    :cond_7
    const-string v2, "Claude \u79c1\u6709\u5b89\u88c5\u672a\u5b8c\u6210\u3002"

    invoke-virtual {v2, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_8

    const-string p0, "private_installer"

    return-object p0

    .line 156
    :cond_8
    instance-of v1, p0, Landroid/system/ErrnoException;

    if-eqz v1, :cond_9

    .line 157
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "filesystem_errno_"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    check-cast p0, Landroid/system/ErrnoException;

    iget p0, p0, Landroid/system/ErrnoException;->errno:I

    invoke-virtual {v0, p0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    return-object p0

    .line 145
    :cond_9
    add-int/lit8 v0, v0, 0x1

    invoke-virtual {p0}, Ljava/lang/Throwable;->getCause()Ljava/lang/Throwable;

    move-result-object p0

    goto/16 :goto_0

    .line 159
    :cond_a
    const-string p0, "unclassified"

    return-object p0
.end method

.method static install(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeBundle$State;Lio/github/leexeo/cage/space/ClaudeBundle$State;I)Ljava/lang/String;
    .locals 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 76
    const-string v0, "committed"

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->requireIdle(Landroid/content/Context;)V

    .line 77
    invoke-static {p1, p2}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->requireUpgrade(Lio/github/leexeo/cage/space/ClaudeBundle$State;Lio/github/leexeo/cage/space/ClaudeBundle$State;)V

    .line 78
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->privateBase(Landroid/content/Context;)Ljava/io/File;

    move-result-object v1

    const/4 v2, 0x1

    invoke-static {p1, v2, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->validateStored(Lio/github/leexeo/cage/space/ClaudeBundle$State;ZLjava/io/File;)V

    .line 79
    const/4 v1, 0x0

    invoke-static {p2, v2, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->validateStored(Lio/github/leexeo/cage/space/ClaudeBundle$State;ZLjava/io/File;)V

    .line 80
    invoke-static {p0, p1, p3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->validateCurrent(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeBundle$State;I)V

    .line 81
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->onlyUserZero(Landroid/content/Context;)V

    .line 82
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->requirePackageRecord(Landroid/content/Context;)V

    .line 84
    new-instance v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;

    invoke-direct {v3, v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;-><init>(Lio/github/leexeo/cage/space/ClaudeUpgrade$1;)V

    .line 85
    invoke-static {}, Ljava/util/UUID;->randomUUID()Ljava/util/UUID;

    move-result-object v1

    invoke-virtual {v1}, Ljava/util/UUID;->toString()Ljava/lang/String;

    move-result-object v1

    iput-object v1, v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->id:Ljava/lang/String;

    .line 86
    const/4 v1, 0x0

    invoke-static {p0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->root(Landroid/content/Context;Z)Ljava/io/File;

    move-result-object v4

    new-instance v5, Ljava/lang/StringBuilder;

    invoke-direct {v5}, Ljava/lang/StringBuilder;-><init>()V

    const-string v6, ".upgrade-"

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    iget-object v6, v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->id:Ljava/lang/String;

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v5

    invoke-static {v4, v5}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v4

    iput-object v4, v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    .line 87
    iget-object v4, v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    invoke-virtual {v4}, Ljava/io/File;->mkdir()Z

    move-result v4

    if-eqz v4, :cond_6

    .line 88
    iput-object p1, v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    .line 89
    iput-object p2, v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->next:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    .line 90
    iput p3, v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->uid:I

    .line 91
    const-string v4, "prepared"

    iput-object v4, v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    .line 92
    iget-object v4, v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    const-string v5, "old-active.json"

    invoke-static {v4, v5}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v4

    .line 94
    invoke-static {p0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->root(Landroid/content/Context;Z)Ljava/io/File;

    move-result-object v5

    invoke-static {v5}, Lio/github/leexeo/cage/space/ClaudeBundle;->active(Ljava/io/File;)Landroid/util/AtomicFile;

    move-result-object v5

    invoke-virtual {v5}, Landroid/util/AtomicFile;->openRead()Ljava/io/FileInputStream;

    move-result-object v5

    .line 95
    const/high16 v6, 0x20000

    :try_start_0
    invoke-static {v5, v6}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->read(Ljava/io/InputStream;I)[B

    move-result-object v6
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 96
    if-eqz v5, :cond_0

    invoke-virtual {v5}, Ljava/io/InputStream;->close()V

    .line 97
    :cond_0
    invoke-static {v4, v6}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->writeNew(Ljava/io/File;[B)V

    .line 98
    const-wide/32 v5, 0x20000

    invoke-static {v4, v5, v6}, Lio/github/leexeo/cage/space/ClaudeBundle;->sha(Ljava/io/File;J)Ljava/lang/String;

    move-result-object v4

    iput-object v4, v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->activeHash:Ljava/lang/String;

    .line 99
    invoke-static {p0, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->saveJournal(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V

    .line 101
    :try_start_1
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->stop(Landroid/content/Context;)V

    .line 102
    invoke-static {p0, p1, p3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->validateCurrent(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeBundle$State;I)V

    .line 103
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->privateBase(Landroid/content/Context;)Ljava/io/File;

    move-result-object v4

    invoke-static {p1, v2, v4}, Lio/github/leexeo/cage/space/ClaudeBundle;->validateStored(Lio/github/leexeo/cage/space/ClaudeBundle$State;ZLjava/io/File;)V

    .line 104
    invoke-static {p0, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->backup(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)Ljava/util/List;

    move-result-object p1

    .line 105
    iget-object v4, v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    const-string v5, "backup.json"

    invoke-static {v4, v5}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v4

    const-wide/32 v5, 0x1000000

    invoke-static {v4, v5, v6}, Lio/github/leexeo/cage/space/ClaudeBundle;->sha(Ljava/io/File;J)Ljava/lang/String;

    move-result-object v4

    iput-object v4, v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->backupHash:Ljava/lang/String;

    .line 106
    const-string v4, "backed-up"

    iput-object v4, v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    .line 107
    invoke-static {p0, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->saveJournal(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V

    .line 108
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->stop(Landroid/content/Context;)V

    .line 109
    invoke-interface {p1}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v4

    :goto_0
    invoke-interface {v4}, Ljava/util/Iterator;->hasNext()Z

    move-result v5

    if-eqz v5, :cond_1

    invoke-interface {v4}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v5

    check-cast v5, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;

    iget-object v6, v5, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    invoke-static {p0, v6}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->live(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object v6

    invoke-static {v5, v6}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->verifyTree(Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;Ljava/io/File;)V

    goto :goto_0

    .line 111
    :cond_1
    const-string v4, "installing"

    iput-object v4, v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    .line 112
    invoke-static {p0, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->saveJournal(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V

    .line 113
    invoke-static {p2}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->installPrivate(Lio/github/leexeo/cage/space/ClaudeBundle$State;)V

    .line 114
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->stop(Landroid/content/Context;)V

    .line 115
    invoke-static {p0, p2, p3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->validateCurrent(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeBundle$State;I)V

    .line 116
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->privateBase(Landroid/content/Context;)Ljava/io/File;

    move-result-object p3

    invoke-static {p2, v2, p3}, Lio/github/leexeo/cage/space/ClaudeBundle;->validateStored(Lio/github/leexeo/cage/space/ClaudeBundle$State;ZLjava/io/File;)V

    .line 118
    invoke-interface {p1}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object p1

    :cond_2
    :goto_1
    invoke-interface {p1}, Ljava/util/Iterator;->hasNext()Z

    move-result p3

    if-eqz p3, :cond_3

    invoke-interface {p1}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object p3

    check-cast p3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;

    const-string v2, "app"

    iget-object v4, p3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    invoke-virtual {v2, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-nez v2, :cond_2

    iget-object v2, p3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    invoke-static {p0, v2}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->live(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object v2

    invoke-static {p3, v2}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->verifyTree(Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;Ljava/io/File;)V

    goto :goto_1

    .line 119
    :cond_3
    invoke-static {p0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->root(Landroid/content/Context;Z)Ljava/io/File;

    move-result-object p1

    invoke-static {p1}, Lio/github/leexeo/cage/space/ClaudeBundle;->active(Ljava/io/File;)Landroid/util/AtomicFile;

    move-result-object p1

    invoke-static {p1, p2}, Lio/github/leexeo/cage/space/ClaudeBundle;->publish(Landroid/util/AtomicFile;Lio/github/leexeo/cage/space/ClaudeBundle$State;)V

    .line 120
    invoke-static {p0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->root(Landroid/content/Context;Z)Ljava/io/File;

    move-result-object p1

    invoke-static {p1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->syncDirectory(Ljava/io/File;)V

    .line 121
    invoke-static {p0, p2}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->validateActive(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeBundle$State;)V

    .line 122
    iput-object v0, v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    .line 123
    invoke-static {p0, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->saveJournal(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V

    .line 124
    invoke-static {p0, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->closeJournal(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V

    .line 125
    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    const-string p3, "Claude \u5df2\u5347\u7ea7\u5230 "

    invoke-virtual {p1, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    iget-object p2, p2, Lio/github/leexeo/cage/space/ClaudeBundle$State;->versionName:Ljava/lang/String;

    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string p2, "\uff1b\u539f\u7248\u7b7e\u540d\u3001\u8d26\u53f7\u548c\u5e94\u7528\u6570\u636e\u5df2\u4fdd\u7559\u3002"

    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_0

    return-object p0

    .line 126
    :catch_0
    move-exception p1

    .line 127
    new-instance p2, Ljava/lang/StringBuilder;

    invoke-direct {p2}, Ljava/lang/StringBuilder;-><init>()V

    const-string p3, "Claude upgrade stopped: phase="

    invoke-virtual {p2, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    iget-object p3, v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    invoke-virtual {p2, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    const-string p3, " reason="

    invoke-virtual {p2, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    .line 128
    invoke-static {p1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->failureCode(Ljava/lang/Throwable;)Ljava/lang/String;

    move-result-object p3

    invoke-virtual {p2, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p2

    .line 127
    const-string p3, "CageDemo"

    invoke-static {p3, p2}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 131
    iget-object p2, v3, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    invoke-virtual {v0, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p2

    if-eqz p2, :cond_4

    .line 132
    new-instance p0, Ljava/io/IOException;

    const-string p2, "Claude \u65b0\u7248\u5df2\u63d0\u4ea4\uff1b\u6536\u5c3e\u8bb0\u5f55\u9700\u6062\u590d\uff0c\u5347\u7ea7\u5907\u4efd\u5df2\u4fdd\u7559\u3002"

    invoke-direct {p0, p2, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw p0

    .line 134
    :cond_4
    :try_start_2
    invoke-static {p0, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->rollback(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V
    :try_end_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_1

    .line 138
    nop

    .line 139
    new-instance p0, Ljava/io/IOException;

    const-string p2, "Claude \u5347\u7ea7\u672a\u5b8c\u6210\uff0c\u5df2\u6062\u590d\u539f\u7248\u4e0e\u539f\u6570\u636e\uff1b\u5907\u4efd\u548c\u5931\u8d25\u73b0\u573a\u5df2\u4fdd\u7559\u3002"

    invoke-direct {p0, p2, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw p0

    .line 135
    :catch_1
    move-exception p0

    .line 136
    invoke-virtual {p1, p0}, Ljava/lang/Exception;->addSuppressed(Ljava/lang/Throwable;)V

    .line 137
    new-instance p0, Ljava/io/IOException;

    const-string p2, "Claude \u5347\u7ea7\u672a\u5b8c\u6210\u4e14\u81ea\u52a8\u6062\u590d\u53d7\u963b\uff1b\u5df2\u6682\u505c\u542f\u52a8\uff0c\u5b8c\u6574\u5907\u4efd\u4e0e\u5931\u8d25\u73b0\u573a\u5747\u4fdd\u7559\u3002"

    invoke-direct {p0, p2, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    throw p0

    .line 94
    :catchall_0
    move-exception p0

    if-eqz v5, :cond_5

    :try_start_3
    invoke-virtual {v5}, Ljava/io/InputStream;->close()V
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_1

    goto :goto_2

    :catchall_1
    move-exception p1

    invoke-virtual {p0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_5
    :goto_2
    throw p0

    .line 87
    :cond_6
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u65e0\u6cd5\u521b\u5efa Claude \u5347\u7ea7\u5907\u4efd\u76ee\u5f55\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static installPrivate(Lio/github/leexeo/cage/space/ClaudeBundle$State;)V
    .locals 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 226
    const-string v0, "top.niunaijun.blackbox.entity.pm.InstallOption"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    .line 227
    const/4 v1, 0x0

    new-array v2, v1, [Ljava/lang/Class;

    const-string v3, "installByStorage"

    invoke-virtual {v0, v3, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v2

    const/4 v3, 0x0

    new-array v4, v1, [Ljava/lang/Object;

    invoke-virtual {v2, v3, v4}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v2

    .line 228
    const-string v3, "top.niunaijun.blackbox.core.system.pm.IBPackageManagerService"

    invoke-static {v3}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v3

    const-class v4, Ljava/lang/String;

    sget-object v5, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v4, v0, v5}, [Ljava/lang/Class;

    move-result-object v0

    .line 229
    const-string v4, "installPackageAsUser"

    invoke-virtual {v3, v4, v0}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    .line 230
    const-string v3, "getBPackageManager"

    invoke-static {v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->service(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v3

    iget-object p0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directoryFile:Ljava/io/File;

    const-string v4, "base.apk"

    invoke-static {p0, v4}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object p0

    invoke-virtual {p0}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object p0

    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    filled-new-array {p0, v2, v1}, [Ljava/lang/Object;

    move-result-object p0

    invoke-virtual {v0, v3, p0}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    .line 231
    if-eqz p0, :cond_0

    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v0

    const-string v1, "success"

    invoke-virtual {v0, v1}, Ljava/lang/Class;->getField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v0

    invoke-virtual {v0, p0}, Ljava/lang/reflect/Field;->getBoolean(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_0

    .line 233
    return-void

    .line 232
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Claude \u79c1\u6709\u5b89\u88c5\u672a\u5b8c\u6210\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method static synthetic lambda$collect$1(Ljava/io/File;Ljava/io/File;)I
    .locals 0

    .line 446
    invoke-virtual {p0}, Ljava/io/File;->getName()Ljava/lang/String;

    move-result-object p0

    invoke-virtual {p1}, Ljava/io/File;->getName()Ljava/lang/String;

    move-result-object p1

    invoke-virtual {p0, p1}, Ljava/lang/String;->compareTo(Ljava/lang/String;)I

    move-result p0

    return p0
.end method

.method static synthetic lambda$scan$0(Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;)I
    .locals 0

    .line 411
    iget-object p0, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    iget-object p1, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    invoke-virtual {p0, p1}, Ljava/lang/String;->compareTo(Ljava/lang/String;)I

    move-result p0

    return p0
.end method

.method private static live(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 322
    const-string v0, "app"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_0

    const-string p1, "app/"

    goto :goto_0

    .line 323
    :cond_0
    const-string v0, "user"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_1

    const-string p1, "user/0/"

    goto :goto_0

    .line 324
    :cond_1
    const-string v0, "user-de"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_2

    const-string p1, "user_de/0/"

    .line 326
    :goto_0
    new-instance v0, Ljava/io/File;

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->data(Landroid/content/Context;)Ljava/io/File;

    move-result-object p0

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "blackbox/data/"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v1, "com.anthropic.claude"

    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-direct {v0, p0, p1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->exact(Ljava/io/File;)Ljava/io/File;

    move-result-object p0

    return-object p0

    .line 325
    :cond_2
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u672a\u77e5 Claude \u5907\u4efd\u8303\u56f4\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static matchesBase(Ljava/io/File;Ljava/io/File;Lio/github/leexeo/cage/space/ClaudeBundle$State;)Z
    .locals 5
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 63
    invoke-virtual {p0, p1}, Ljava/io/File;->equals(Ljava/lang/Object;)Z

    move-result p1

    const/4 v0, 0x0

    if-eqz p1, :cond_2

    invoke-virtual {p0}, Ljava/io/File;->isFile()Z

    move-result p1

    if-nez p1, :cond_0

    goto :goto_0

    .line 64
    :cond_0
    iget-object p1, p2, Lio/github/leexeo/cage/space/ClaudeBundle$State;->apks:Ljava/util/List;

    invoke-interface {p1, v0}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, Lio/github/leexeo/cage/space/ClaudeBundle$Record;

    .line 65
    invoke-virtual {p0}, Ljava/io/File;->length()J

    move-result-wide v1

    iget-wide v3, p1, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->size:J

    cmp-long p2, v1, v3

    if-nez p2, :cond_1

    iget-object p1, p1, Lio/github/leexeo/cage/space/ClaudeBundle$Record;->sha256:Ljava/lang/String;

    const-wide/32 v1, 0xa000000

    invoke-static {p0, v1, v2}, Lio/github/leexeo/cage/space/ClaudeBundle;->sha(Ljava/io/File;J)Ljava/lang/String;

    move-result-object p0

    invoke-virtual {p1, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_1

    const/4 v0, 0x1

    :cond_1
    return v0

    .line 63
    :cond_2
    :goto_0
    return v0
.end method

.method private static onlyUserZero(Landroid/content/Context;)V
    .locals 9
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 301
    const-string v0, "user"

    const-string v1, "user_de"

    filled-new-array {v0, v1}, [Ljava/lang/String;

    move-result-object v0

    const/4 v1, 0x0

    move v2, v1

    :goto_0
    const/4 v3, 0x2

    if-ge v2, v3, :cond_5

    aget-object v3, v0, v2

    .line 302
    new-instance v4, Ljava/io/File;

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->data(Landroid/content/Context;)Ljava/io/File;

    move-result-object v5

    new-instance v6, Ljava/lang/StringBuilder;

    invoke-direct {v6}, Ljava/lang/StringBuilder;-><init>()V

    const-string v7, "blackbox/data/"

    invoke-virtual {v6, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v6

    invoke-virtual {v6, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    invoke-direct {v4, v5, v3}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    invoke-static {v4}, Lio/github/leexeo/cage/space/ClaudeBundle;->exact(Ljava/io/File;)Ljava/io/File;

    move-result-object v3

    .line 303
    invoke-virtual {v3}, Ljava/io/File;->isDirectory()Z

    move-result v4

    if-eqz v4, :cond_4

    .line 304
    invoke-virtual {v3}, Ljava/io/File;->listFiles()[Ljava/io/File;

    move-result-object v3

    .line 305
    if-eqz v3, :cond_3

    .line 306
    array-length v4, v3

    move v5, v1

    :goto_1
    if-ge v5, v4, :cond_2

    aget-object v6, v3, v5

    const-string v7, "0"

    invoke-virtual {v6}, Ljava/io/File;->getName()Ljava/lang/String;

    move-result-object v8

    invoke-virtual {v7, v8}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v7

    if-nez v7, :cond_1

    new-instance v7, Ljava/io/File;

    const-string v8, "com.anthropic.claude"

    invoke-direct {v7, v6, v8}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    .line 307
    invoke-static {v7}, Lio/github/leexeo/cage/space/ClaudeBundle;->exact(Ljava/io/File;)Ljava/io/File;

    move-result-object v6

    invoke-virtual {v6}, Ljava/io/File;->exists()Z

    move-result v6

    if-nez v6, :cond_0

    goto :goto_2

    .line 308
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Claude \u8fd8\u5b58\u5728\u4e8e\u5176\u4ed6\u7a7a\u95f4\u7528\u6237\uff0c\u5f53\u524d\u5347\u7ea7\u5df2\u505c\u6b62\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 306
    :cond_1
    :goto_2
    add-int/lit8 v5, v5, 0x1

    goto :goto_1

    .line 301
    :cond_2
    add-int/lit8 v2, v2, 0x1

    goto :goto_0

    .line 305
    :cond_3
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u65e0\u6cd5\u8bfb\u53d6\u7a7a\u95f4\u7528\u6237\u76ee\u5f55\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 303
    :cond_4
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u65e0\u6cd5\u786e\u8ba4 Claude \u79c1\u6709\u7528\u6237\u76ee\u5f55\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 310
    :cond_5
    return-void
.end method

.method static pending(Landroid/content/Context;)Z
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 42
    const/4 v0, 0x0

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->root(Landroid/content/Context;Z)Ljava/io/File;

    move-result-object p0

    .line 43
    const-string v1, "pending-upgrade.json"

    invoke-static {p0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v1

    invoke-virtual {v1}, Ljava/io/File;->exists()Z

    move-result v1

    if-nez v1, :cond_0

    .line 44
    const-string v1, "pending-upgrade.json.bak"

    invoke-static {p0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v1

    invoke-virtual {v1}, Ljava/io/File;->exists()Z

    move-result v1

    if-nez v1, :cond_0

    .line 45
    const-string v1, "pending-upgrade.json.new"

    invoke-static {p0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object p0

    invoke-virtual {p0}, Ljava/io/File;->exists()Z

    move-result p0

    if-eqz p0, :cond_1

    :cond_0
    const/4 v0, 0x1

    .line 43
    :cond_1
    return v0
.end method

.method private static preserve(Ljava/io/File;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;Ljava/lang/String;)V
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 537
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->exact(Ljava/io/File;)Ljava/io/File;

    .line 538
    invoke-virtual {p0}, Ljava/io/File;->exists()Z

    move-result v0

    if-nez v0, :cond_0

    return-void

    .line 539
    :cond_0
    iget-object v0, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "preserved-"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    const-string v1, "-"

    invoke-virtual {p2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-static {}, Ljava/util/UUID;->randomUUID()Ljava/util/UUID;

    move-result-object v1

    invoke-virtual {p2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p2

    invoke-static {v0, p2}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object p2

    .line 540
    invoke-virtual {p2}, Ljava/io/File;->exists()Z

    move-result v0

    if-nez v0, :cond_1

    invoke-virtual {p0, p2}, Ljava/io/File;->renameTo(Ljava/io/File;)Z

    move-result p2

    if-eqz p2, :cond_1

    .line 541
    invoke-virtual {p0}, Ljava/io/File;->getParentFile()Ljava/io/File;

    move-result-object p0

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->syncDirectory(Ljava/io/File;)V

    .line 542
    iget-object p0, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->syncDirectory(Ljava/io/File;)V

    .line 543
    return-void

    .line 540
    :cond_1
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u65e0\u6cd5\u4fdd\u7559 Claude \u5931\u8d25\u73b0\u573a\uff0c\u672a\u7ee7\u7eed\u8986\u76d6\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static read(Ljava/io/InputStream;I)[B
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 623
    new-instance v0, Ljava/io/ByteArrayOutputStream;

    invoke-direct {v0}, Ljava/io/ByteArrayOutputStream;-><init>()V

    .line 624
    const/16 v1, 0x2000

    new-array v1, v1, [B

    .line 625
    :goto_0
    invoke-virtual {p0, v1}, Ljava/io/InputStream;->read([B)I

    move-result v2

    const/4 v3, -0x1

    if-eq v2, v3, :cond_1

    .line 626
    invoke-virtual {v0}, Ljava/io/ByteArrayOutputStream;->size()I

    move-result v3

    add-int/2addr v3, v2

    if-gt v3, p1, :cond_0

    .line 627
    const/4 v3, 0x0

    invoke-virtual {v0, v1, v3, v2}, Ljava/io/ByteArrayOutputStream;->write([BII)V

    goto :goto_0

    .line 626
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u6062\u590d\u8bb0\u5f55\u8d85\u51fa\u9650\u5236\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 629
    :cond_1
    invoke-virtual {v0}, Ljava/io/ByteArrayOutputStream;->toByteArray()[B

    move-result-object p0

    return-object p0
.end method

.method private static readBackup(Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)Ljava/util/List;
    .locals 14
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;",
            ")",
            "Ljava/util/List<",
            "Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;",
            ">;"
        }
    .end annotation

    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 355
    iget-object v0, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    const-string v1, "backup.json"

    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v0

    .line 356
    iget-object v1, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->backupHash:Ljava/lang/String;

    if-eqz v1, :cond_e

    iget-object p0, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->backupHash:Ljava/lang/String;

    const-wide/32 v1, 0x1000000

    invoke-static {v0, v1, v2}, Lio/github/leexeo/cage/space/ClaudeBundle;->sha(Ljava/io/File;J)Ljava/lang/String;

    move-result-object v1

    invoke-virtual {p0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_e

    .line 358
    new-instance p0, Lorg/json/JSONObject;

    new-instance v1, Ljava/lang/String;

    const/high16 v2, 0x1000000

    invoke-static {v0, v2}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->readFile(Ljava/io/File;I)[B

    move-result-object v0

    sget-object v2, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-direct {v1, v0, v2}, Ljava/lang/String;-><init>([BLjava/nio/charset/Charset;)V

    invoke-direct {p0, v1}, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V

    .line 359
    const-string v0, "trees"

    invoke-virtual {p0, v0}, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;

    move-result-object v0

    .line 360
    const-string v1, "schema"

    invoke-virtual {p0, v1}, Lorg/json/JSONObject;->getInt(Ljava/lang/String;)I

    move-result p0

    const/4 v1, 0x2

    if-ne p0, v1, :cond_d

    invoke-virtual {v0}, Lorg/json/JSONArray;->length()I

    move-result p0

    sget-object v1, Lio/github/leexeo/cage/space/ClaudeUpgrade;->TREES:[Ljava/lang/String;

    array-length v1, v1

    if-ne p0, v1, :cond_d

    .line 362
    new-instance p0, Ljava/util/ArrayList;

    invoke-direct {p0}, Ljava/util/ArrayList;-><init>()V

    .line 363
    new-instance v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;

    const/4 v2, 0x0

    invoke-direct {v1, v2}, Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;-><init>(Lio/github/leexeo/cage/space/ClaudeUpgrade$1;)V

    .line 364
    const/4 v3, 0x0

    move v4, v3

    :goto_0
    sget-object v5, Lio/github/leexeo/cage/space/ClaudeUpgrade;->TREES:[Ljava/lang/String;

    array-length v5, v5

    if-ge v4, v5, :cond_c

    .line 365
    invoke-virtual {v0, v4}, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;

    move-result-object v5

    .line 366
    new-instance v6, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;

    invoke-direct {v6, v2}, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;-><init>(Lio/github/leexeo/cage/space/ClaudeUpgrade$1;)V

    .line 367
    const-string v7, "name"

    invoke-virtual {v5, v7}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v7

    iput-object v7, v6, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    .line 368
    const-string v7, "present"

    invoke-virtual {v5, v7}, Lorg/json/JSONObject;->getBoolean(Ljava/lang/String;)Z

    move-result v7

    iput-boolean v7, v6, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->present:Z

    .line 369
    sget-object v7, Lio/github/leexeo/cage/space/ClaudeUpgrade;->TREES:[Ljava/lang/String;

    aget-object v7, v7, v4

    iget-object v8, v6, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    invoke-virtual {v7, v8}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v7

    if-eqz v7, :cond_b

    .line 370
    const-string v7, "entries"

    invoke-virtual {v5, v7}, Lorg/json/JSONObject;->getJSONArray(Ljava/lang/String;)Lorg/json/JSONArray;

    move-result-object v5

    .line 371
    nop

    .line 372
    new-instance v7, Ljava/util/HashSet;

    invoke-direct {v7}, Ljava/util/HashSet;-><init>()V

    .line 373
    move-object v9, v2

    move v8, v3

    :goto_1
    invoke-virtual {v5}, Lorg/json/JSONArray;->length()I

    move-result v10

    if-ge v8, v10, :cond_9

    .line 374
    invoke-virtual {v5, v8}, Lorg/json/JSONArray;->getJSONObject(I)Lorg/json/JSONObject;

    move-result-object v10

    .line 375
    new-instance v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;

    invoke-direct {v11, v2}, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;-><init>(Lio/github/leexeo/cage/space/ClaudeUpgrade$1;)V

    .line 376
    const-string v12, "path"

    invoke-virtual {v10, v12}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v12

    iput-object v12, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    .line 377
    const-string v12, "directory"

    invoke-virtual {v10, v12}, Lorg/json/JSONObject;->getBoolean(Ljava/lang/String;)Z

    move-result v12

    iput-boolean v12, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->directory:Z

    .line 378
    const-string v12, "mode"

    invoke-virtual {v10, v12}, Lorg/json/JSONObject;->getInt(Ljava/lang/String;)I

    move-result v12

    iput v12, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->mode:I

    .line 379
    const-string v12, "gid"

    invoke-virtual {v10, v12}, Lorg/json/JSONObject;->getInt(Ljava/lang/String;)I

    move-result v12

    iput v12, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->gid:I

    .line 380
    const-string v12, "modified"

    invoke-virtual {v10, v12}, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J

    move-result-wide v12

    iput-wide v12, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->modified:J

    .line 381
    const-string v12, "size"

    invoke-virtual {v10, v12}, Lorg/json/JSONObject;->getLong(Ljava/lang/String;)J

    move-result-wide v12

    iput-wide v12, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->size:J

    .line 382
    const-string v12, "sha256"

    invoke-virtual {v10, v12}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v10

    iput-object v10, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->hash:Ljava/lang/String;

    .line 383
    iget-object v10, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    invoke-static {v10}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->relative(Ljava/lang/String;)Z

    move-result v10

    if-eqz v10, :cond_8

    if-eqz v9, :cond_0

    iget-object v10, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    invoke-virtual {v9, v10}, Ljava/lang/String;->compareTo(Ljava/lang/String;)I

    move-result v9

    if-gez v9, :cond_8

    :cond_0
    iget-boolean v9, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->directory:Z

    iget v10, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->mode:I

    .line 384
    invoke-static {v9, v10}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->supportedMode(ZI)Z

    move-result v9

    if-eqz v9, :cond_8

    iget v9, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->gid:I

    if-ltz v9, :cond_8

    iget-wide v9, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->modified:J

    const-wide/16 v12, 0x0

    cmp-long v9, v9, v12

    if-ltz v9, :cond_8

    iget-wide v9, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->size:J

    cmp-long v9, v9, v12

    if-ltz v9, :cond_8

    iget-boolean v9, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->directory:Z

    if-eqz v9, :cond_1

    iget-wide v9, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->size:J

    cmp-long v9, v9, v12

    if-nez v9, :cond_8

    iget-object v9, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->hash:Ljava/lang/String;

    .line 385
    invoke-virtual {v9}, Ljava/lang/String;->isEmpty()Z

    move-result v9

    if-eqz v9, :cond_8

    goto :goto_2

    :cond_1
    iget-object v9, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->hash:Ljava/lang/String;

    const-string v10, "[0-9a-f]{64}"

    invoke-virtual {v9, v10}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v9

    if-eqz v9, :cond_8

    .line 387
    :goto_2
    if-nez v8, :cond_3

    iget-object v9, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    invoke-virtual {v9}, Ljava/lang/String;->isEmpty()Z

    move-result v9

    if-eqz v9, :cond_2

    iget-boolean v9, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->directory:Z

    if-eqz v9, :cond_2

    goto :goto_3

    :cond_2
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Claude \u5907\u4efd\u6839\u76ee\u5f55\u65e0\u6548\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 388
    :cond_3
    :goto_3
    if-lez v8, :cond_6

    .line 389
    iget-object v9, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    const/16 v10, 0x2f

    invoke-virtual {v9, v10}, Ljava/lang/String;->lastIndexOf(I)I

    move-result v9

    .line 390
    if-gez v9, :cond_4

    const-string v9, ""

    goto :goto_4

    :cond_4
    iget-object v10, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    invoke-virtual {v10, v3, v9}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v9

    :goto_4
    invoke-interface {v7, v9}, Ljava/util/Set;->contains(Ljava/lang/Object;)Z

    move-result v9

    if-eqz v9, :cond_5

    goto :goto_5

    .line 391
    :cond_5
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Claude \u5907\u4efd\u7f3a\u5c11\u7236\u76ee\u5f55\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 393
    :cond_6
    :goto_5
    iget-boolean v9, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->directory:Z

    if-eqz v9, :cond_7

    iget-object v9, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    invoke-interface {v7, v9}, Ljava/util/Set;->add(Ljava/lang/Object;)Z

    .line 394
    :cond_7
    iget-wide v9, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->size:J

    invoke-virtual {v1, v9, v10}, Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;->add(J)V

    .line 395
    iget-object v9, v6, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->entries:Ljava/util/List;

    invoke-interface {v9, v11}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 396
    iget-object v9, v11, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    .line 373
    add-int/lit8 v8, v8, 0x1

    goto/16 :goto_1

    .line 386
    :cond_8
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Claude \u5907\u4efd\u8def\u5f84\u6216\u6570\u636e\u6458\u8981\u65e0\u6548\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 398
    :cond_9
    iget-boolean v5, v6, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->present:Z

    iget-object v7, v6, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->entries:Ljava/util/List;

    invoke-interface {v7}, Ljava/util/List;->isEmpty()Z

    move-result v7

    xor-int/lit8 v7, v7, 0x1

    if-ne v5, v7, :cond_a

    .line 399
    invoke-interface {p0, v6}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 364
    add-int/lit8 v4, v4, 0x1

    goto/16 :goto_0

    .line 398
    :cond_a
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Claude \u5907\u4efd\u5b58\u5728\u72b6\u6001\u4e0d\u4e00\u81f4\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 369
    :cond_b
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Claude \u5907\u4efd\u8303\u56f4\u4e0d\u4e00\u81f4\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 401
    :cond_c
    return-object p0

    .line 361
    :cond_d
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Claude \u5907\u4efd\u7f3a\u5c11\u5b8c\u6574\u6743\u9650\u4fe1\u606f\uff0c\u5df2\u4fdd\u7559\u73b0\u573a\u5e76\u6682\u505c\u81ea\u52a8\u6062\u590d\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 357
    :cond_e
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Claude \u5b8c\u6574\u5907\u4efd\u8bb0\u5f55\u4e0d\u53ef\u7528\uff0c\u5df2\u4fdd\u7559\u73b0\u573a\u5e76\u6682\u505c\u6062\u590d\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static readFile(Ljava/io/File;I)[B
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 619
    new-instance v0, Ljava/io/FileInputStream;

    invoke-direct {v0, p0}, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V

    :try_start_0
    invoke-static {v0, p1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->read(Ljava/io/InputStream;I)[B

    move-result-object p0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    invoke-virtual {v0}, Ljava/io/InputStream;->close()V

    return-object p0

    :catchall_0
    move-exception p0

    :try_start_1
    invoke-virtual {v0}, Ljava/io/InputStream;->close()V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    goto :goto_0

    :catchall_1
    move-exception p1

    invoke-virtual {p0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_0
    throw p0
.end method

.method private static readJournal(Landroid/content/Context;)Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;
    .locals 5
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 546
    const/4 v0, 0x0

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->root(Landroid/content/Context;Z)Ljava/io/File;

    move-result-object v0

    .line 547
    const-string v1, "pending-upgrade.json.bak"

    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v1

    .line 548
    const-string v2, "pending-upgrade.json.new"

    invoke-static {v0, v2}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    .line 552
    invoke-virtual {v1}, Ljava/io/File;->exists()Z

    move-result v2

    if-eqz v2, :cond_0

    goto :goto_0

    :cond_0
    const-string v1, "pending-upgrade.json"

    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v1

    .line 553
    :goto_0
    new-instance v2, Lorg/json/JSONObject;

    new-instance v3, Ljava/lang/String;

    const/high16 v4, 0x40000

    invoke-static {v1, v4}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->readFile(Ljava/io/File;I)[B

    move-result-object v1

    sget-object v4, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-direct {v3, v1, v4}, Ljava/lang/String;-><init>([BLjava/nio/charset/Charset;)V

    invoke-direct {v2, v3}, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V

    .line 554
    const-string v1, "schema"

    invoke-virtual {v2, v1}, Lorg/json/JSONObject;->getInt(Ljava/lang/String;)I

    move-result v1

    const/4 v3, 0x1

    if-ne v1, v3, :cond_4

    const-string v1, "host"

    invoke-virtual {v2, v1}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v1

    const-string v3, "top.niunaijun.microdem"

    invoke-virtual {v3, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_4

    .line 555
    const-string v1, "package"

    invoke-virtual {v2, v1}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v1

    const-string v3, "com.anthropic.claude"

    invoke-virtual {v3, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_4

    .line 556
    new-instance v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;

    const/4 v3, 0x0

    invoke-direct {v1, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;-><init>(Lio/github/leexeo/cage/space/ClaudeUpgrade$1;)V

    .line 557
    const-string v4, "id"

    invoke-virtual {v2, v4}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v4

    iput-object v4, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->id:Ljava/lang/String;

    .line 558
    const-string v4, "phase"

    invoke-virtual {v2, v4}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v4

    iput-object v4, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    .line 559
    const-string v4, "uid"

    invoke-virtual {v2, v4}, Lorg/json/JSONObject;->getInt(Ljava/lang/String;)I

    move-result v4

    iput v4, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->uid:I

    .line 560
    const-string v4, "activeHash"

    invoke-virtual {v2, v4}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v4

    iput-object v4, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->activeHash:Ljava/lang/String;

    .line 561
    const-string v4, "backupHash"

    invoke-virtual {v2, v4, v3}, Lorg/json/JSONObject;->optString(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v3

    iput-object v3, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->backupHash:Ljava/lang/String;

    .line 562
    iget-object v3, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->id:Ljava/lang/String;

    const-string v4, "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"

    invoke-virtual {v3, v4}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_3

    sget-object v3, Lio/github/leexeo/cage/space/ClaudeUpgrade;->PHASES:Ljava/util/Set;

    iget-object v4, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    .line 563
    invoke-interface {v3, v4}, Ljava/util/Set;->contains(Ljava/lang/Object;)Z

    move-result v3

    if-eqz v3, :cond_3

    iget v3, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->uid:I

    if-lez v3, :cond_3

    iget-object v3, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->activeHash:Ljava/lang/String;

    const-string v4, "[0-9a-f]{64}"

    invoke-virtual {v3, v4}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_3

    iget-object v3, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->backupHash:Ljava/lang/String;

    if-eqz v3, :cond_1

    iget-object v3, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->backupHash:Ljava/lang/String;

    .line 564
    invoke-virtual {v3, v4}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_3

    .line 566
    :cond_1
    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    const-string v4, ".upgrade-"

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    iget-object v4, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->id:Ljava/lang/String;

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    invoke-static {v0, v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v0

    iput-object v0, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    .line 567
    iget-object v0, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    invoke-virtual {v0}, Ljava/io/File;->isDirectory()Z

    move-result v0

    if-eqz v0, :cond_2

    .line 568
    const-string v0, "old"

    invoke-virtual {v2, v0}, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;

    move-result-object v0

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->parseState(Landroid/content/Context;Lorg/json/JSONObject;)Lio/github/leexeo/cage/space/ClaudeBundle$State;

    move-result-object v0

    iput-object v0, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    .line 569
    const-string v0, "next"

    invoke-virtual {v2, v0}, Lorg/json/JSONObject;->getJSONObject(Ljava/lang/String;)Lorg/json/JSONObject;

    move-result-object v0

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->parseState(Landroid/content/Context;Lorg/json/JSONObject;)Lio/github/leexeo/cage/space/ClaudeBundle$State;

    move-result-object p0

    iput-object p0, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->next:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    .line 570
    iget-object p0, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    iget-object v0, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->next:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->requireUpgrade(Lio/github/leexeo/cage/space/ClaudeBundle$State;Lio/github/leexeo/cage/space/ClaudeBundle$State;)V

    .line 571
    return-object v1

    .line 567
    :cond_2
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Claude \u5347\u7ea7\u5907\u4efd\u76ee\u5f55\u7f3a\u5931\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 565
    :cond_3
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Claude \u5347\u7ea7\u4e8b\u52a1\u8bb0\u5f55\u635f\u574f\uff0c\u5df2\u4fdd\u7559\u73b0\u573a\u5e76\u6682\u505c\u8986\u76d6\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 555
    :cond_4
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u672a\u77e5\u7684 Claude \u5347\u7ea7\u4e8b\u52a1\uff0c\u5df2\u6682\u505c\u8986\u76d6\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method static recoverIfNeeded(Landroid/content/Context;)Ljava/lang/String;
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 164
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->pending(Landroid/content/Context;)Z

    move-result v0

    if-nez v0, :cond_0

    const/4 p0, 0x0

    return-object p0

    .line 165
    :cond_0
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->readJournal(Landroid/content/Context;)Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;

    move-result-object v0

    .line 166
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->stop(Landroid/content/Context;)V

    .line 167
    const-string v1, "committed"

    iget-object v2, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    const/4 v2, 0x1

    if-eqz v1, :cond_1

    .line 168
    iget-object v1, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->next:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    iget v3, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->uid:I

    invoke-static {p0, v1, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->validateCurrent(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeBundle$State;I)V

    .line 169
    iget-object v1, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->next:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    invoke-static {p0, v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->validateActive(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeBundle$State;)V

    .line 170
    iget-object v1, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->next:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->privateBase(Landroid/content/Context;)Ljava/io/File;

    move-result-object v3

    invoke-static {v1, v2, v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->validateStored(Lio/github/leexeo/cage/space/ClaudeBundle$State;ZLjava/io/File;)V

    .line 171
    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->saveJournal(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V

    .line 172
    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->closeJournal(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V

    .line 173
    new-instance p0, Ljava/lang/StringBuilder;

    invoke-direct {p0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "Claude "

    invoke-virtual {p0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    iget-object v0, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->next:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    iget-object v0, v0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->versionName:Ljava/lang/String;

    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string v0, " \u7684\u5347\u7ea7\u5df2\u5b8c\u6210\u6062\u590d\uff1b\u73b0\u6709\u6570\u636e\u672a\u56de\u9000\u3002"

    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    return-object p0

    .line 175
    :cond_1
    const-string v1, "restored"

    iget-object v3, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    invoke-virtual {v1, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-nez v1, :cond_3

    const-string v1, "aborted"

    iget-object v3, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    invoke-virtual {v1, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_2

    goto :goto_0

    .line 182
    :cond_2
    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->rollback(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V

    goto :goto_1

    .line 176
    :cond_3
    :goto_0
    iget-object v1, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    iget v3, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->uid:I

    invoke-static {p0, v1, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->validateCurrent(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeBundle$State;I)V

    .line 177
    iget-object v1, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    invoke-static {p0, v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->validateActive(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeBundle$State;)V

    .line 178
    iget-object v1, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->privateBase(Landroid/content/Context;)Ljava/io/File;

    move-result-object v3

    invoke-static {v1, v2, v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->validateStored(Lio/github/leexeo/cage/space/ClaudeBundle$State;ZLjava/io/File;)V

    .line 179
    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->saveJournal(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V

    .line 180
    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->closeJournal(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V

    .line 184
    :goto_1
    new-instance p0, Ljava/lang/StringBuilder;

    invoke-direct {p0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "\u5df2\u6062\u590d Claude "

    invoke-virtual {p0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    iget-object v0, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    iget-object v0, v0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->versionName:Ljava/lang/String;

    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string v0, " \u4e0e\u539f\u6570\u636e\uff1b\u8bf7\u91cd\u65b0\u9009\u62e9\u8981\u5347\u7ea7\u7684\u5b8c\u6574\u539f\u7248\u5206\u5305\u3002"

    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method

.method private static relative(Ljava/lang/String;)Z
    .locals 6

    .line 457
    const/4 v0, 0x0

    if-eqz p0, :cond_5

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v1

    const/16 v2, 0x1000

    if-gt v1, v2, :cond_5

    const/16 v1, 0x5c

    invoke-virtual {p0, v1}, Ljava/lang/String;->indexOf(I)I

    move-result v1

    if-gez v1, :cond_5

    invoke-virtual {p0, v0}, Ljava/lang/String;->indexOf(I)I

    move-result v1

    if-gez v1, :cond_5

    const-string v1, "/"

    invoke-virtual {p0, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_0

    goto :goto_2

    .line 458
    :cond_0
    invoke-virtual {p0}, Ljava/lang/String;->isEmpty()Z

    move-result v2

    const/4 v3, 0x1

    if-eqz v2, :cond_1

    return v3

    .line 459
    :cond_1
    const/4 v2, -0x1

    invoke-virtual {p0, v1, v2}, Ljava/lang/String;->split(Ljava/lang/String;I)[Ljava/lang/String;

    move-result-object p0

    array-length v1, p0

    move v2, v0

    :goto_0
    if-ge v2, v1, :cond_4

    aget-object v4, p0, v2

    invoke-virtual {v4}, Ljava/lang/String;->isEmpty()Z

    move-result v5

    if-nez v5, :cond_3

    const-string v5, "."

    invoke-virtual {v5, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v5

    if-nez v5, :cond_3

    const-string v5, ".."

    invoke-virtual {v5, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-eqz v4, :cond_2

    goto :goto_1

    :cond_2
    add-int/lit8 v2, v2, 0x1

    goto :goto_0

    :cond_3
    :goto_1
    return v0

    .line 460
    :cond_4
    return v3

    .line 457
    :cond_5
    :goto_2
    return v0
.end method

.method static requireIdle(Landroid/content/Context;)V
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 49
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->pending(Landroid/content/Context;)Z

    move-result p0

    if-nez p0, :cond_0

    .line 50
    return-void

    .line 49
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Claude \u5347\u7ea7\u5c1a\u672a\u5b8c\u6210\uff0c\u5df2\u6682\u505c\u542f\u52a8\uff1b\u8bf7\u4ece\u5bfc\u5165\u5165\u53e3\u6062\u590d\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static requirePackageRecord(Landroid/content/Context;)V
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 313
    const-string v0, "app"

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->live(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object p0

    .line 314
    const-string v0, "package.conf"

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v0

    .line 315
    invoke-virtual {v0}, Ljava/io/File;->isFile()Z

    move-result v1

    if-eqz v1, :cond_0

    invoke-virtual {v0}, Ljava/io/File;->length()J

    move-result-wide v0

    const-wide/16 v2, 0x0

    cmp-long v0, v0, v2

    if-lez v0, :cond_0

    .line 316
    const-string v0, "package.conf.new"

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v0

    invoke-virtual {v0}, Ljava/io/File;->exists()Z

    move-result v0

    if-nez v0, :cond_0

    const-string v0, "package.conf.bak"

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object p0

    invoke-virtual {p0}, Ljava/io/File;->exists()Z

    move-result p0

    if-nez p0, :cond_0

    .line 318
    return-void

    .line 317
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u65e7 Claude \u79c1\u6709\u5b89\u88c5\u8bb0\u5f55\u672a\u7a33\u5b9a\uff0c\u5df2\u505c\u6b62\u5347\u7ea7\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method static requireUpgrade(Lio/github/leexeo/cage/space/ClaudeBundle$State;Lio/github/leexeo/cage/space/ClaudeBundle$State;)V
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 69
    if-eqz p0, :cond_0

    if-eqz p1, :cond_0

    iget-wide v0, p1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->version:J

    iget-wide v2, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->version:J

    cmp-long v0, v0, v2

    if-lez v0, :cond_0

    iget-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->signer:Ljava/lang/String;

    if-eqz v0, :cond_0

    iget-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->signer:Ljava/lang/String;

    iget-object v1, p1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->signer:Ljava/lang/String;

    .line 70
    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_0

    iget-object p0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directory:Ljava/lang/String;

    iget-object p1, p1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directory:Ljava/lang/String;

    invoke-virtual {p0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_0

    .line 72
    return-void

    .line 71
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u5347\u7ea7\u5fc5\u987b\u4f7f\u7528\u66f4\u9ad8\u7248\u672c\u4e14\u5f53\u524d\u5b98\u65b9\u7b7e\u540d\u5b8c\u5168\u76f8\u540c\u7684 Claude \u5b8c\u6574\u5206\u5305\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static restoreTree(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;)V
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 521
    iget-object v0, p2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->live(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object p0

    .line 522
    :try_start_0
    invoke-static {p2, p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->verifyTree(Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;Ljava/io/File;)V
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0

    return-void

    .line 523
    :catch_0
    move-exception v0

    .line 524
    iget-object v0, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "restore-"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    iget-object v2, p2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v2, "-"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-static {}, Ljava/util/UUID;->randomUUID()Ljava/util/UUID;

    move-result-object v2

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v0

    .line 525
    iget-object v1, p2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    invoke-static {p1, v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->backupRoot(Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;Ljava/lang/String;)Ljava/io/File;

    move-result-object v1

    invoke-static {p2, v1, v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->copyTree(Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;Ljava/io/File;Ljava/io/File;)V

    .line 526
    invoke-static {p2, v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->verifyTree(Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;Ljava/io/File;)V

    .line 527
    iget-object v1, p2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    invoke-static {p0, p1, v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->preserve(Ljava/io/File;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;Ljava/lang/String;)V

    .line 528
    iget-boolean v1, p2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->present:Z

    if-eqz v1, :cond_1

    .line 529
    invoke-virtual {v0, p0}, Ljava/io/File;->renameTo(Ljava/io/File;)Z

    move-result v0

    if-eqz v0, :cond_0

    .line 530
    invoke-virtual {p0}, Ljava/io/File;->getParentFile()Ljava/io/File;

    move-result-object v0

    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->syncDirectory(Ljava/io/File;)V

    .line 531
    iget-object p1, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    invoke-static {p1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->syncDirectory(Ljava/io/File;)V

    goto :goto_0

    .line 529
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u65e0\u6cd5\u6062\u590d Claude \u6570\u636e\u76ee\u5f55\uff1b\u526f\u672c\u548c\u73b0\u573a\u5df2\u4fdd\u7559\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 533
    :cond_1
    :goto_0
    invoke-static {p2, p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->verifyTree(Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;Ljava/io/File;)V

    .line 534
    return-void
.end method

.method private static rollback(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V
    .locals 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 188
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->stop(Landroid/content/Context;)V

    .line 189
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->onlyUserZero(Landroid/content/Context;)V

    .line 190
    iget-object v0, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    const/4 v1, 0x0

    const/4 v2, 0x1

    invoke-static {v0, v2, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->validateStored(Lio/github/leexeo/cage/space/ClaudeBundle$State;ZLjava/io/File;)V

    .line 191
    iget-object v0, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->directory:Ljava/io/File;

    const-string v1, "old-active.json"

    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v0

    .line 192
    iget-object v1, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->activeHash:Ljava/lang/String;

    const-wide/32 v3, 0x20000

    invoke-static {v0, v3, v4}, Lio/github/leexeo/cage/space/ClaudeBundle;->sha(Ljava/io/File;J)Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v1, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_5

    .line 194
    const-string v1, "prepared"

    iget-object v3, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    invoke-virtual {v1, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-nez v1, :cond_4

    const-string v1, "backed-up"

    iget-object v3, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    invoke-virtual {v1, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_0

    goto/16 :goto_3

    .line 204
    :cond_0
    invoke-static {p1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->readBackup(Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)Ljava/util/List;

    move-result-object v1

    .line 205
    invoke-interface {v1}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v3

    :goto_0
    invoke-interface {v3}, Ljava/util/Iterator;->hasNext()Z

    move-result v4

    if-eqz v4, :cond_1

    invoke-interface {v3}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v4

    check-cast v4, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;

    iget-object v5, v4, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    invoke-static {p1, v5}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->backupRoot(Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;Ljava/lang/String;)Ljava/io/File;

    move-result-object v5

    invoke-static {v4, v5}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->verifyTree(Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;Ljava/io/File;)V

    goto :goto_0

    .line 206
    :cond_1
    const-string v3, "restoring"

    iput-object v3, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    .line 207
    invoke-static {p0, p1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->saveJournal(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V

    .line 209
    const-string v3, "app"

    invoke-static {p0, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->live(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object v3

    const-string v4, "app-before-rollback"

    invoke-static {v3, p1, v4}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->preserve(Ljava/io/File;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;Ljava/lang/String;)V

    .line 210
    iget-object v3, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    invoke-static {v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->installPrivate(Lio/github/leexeo/cage/space/ClaudeBundle$State;)V

    .line 211
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->stop(Landroid/content/Context;)V

    .line 212
    iget-object v3, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    iget v4, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->uid:I

    invoke-static {p0, v3, v4}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->validateCurrent(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeBundle$State;I)V

    .line 213
    invoke-interface {v1}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v3

    :goto_1
    invoke-interface {v3}, Ljava/util/Iterator;->hasNext()Z

    move-result v4

    if-eqz v4, :cond_2

    invoke-interface {v3}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v4

    check-cast v4, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;

    invoke-static {p0, p1, v4}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->restoreTree(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;)V

    goto :goto_1

    .line 214
    :cond_2
    const/4 v3, 0x0

    invoke-static {p0, v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->root(Landroid/content/Context;Z)Ljava/io/File;

    move-result-object v4

    invoke-static {v4}, Lio/github/leexeo/cage/space/ClaudeBundle;->active(Ljava/io/File;)Landroid/util/AtomicFile;

    move-result-object v4

    const/high16 v5, 0x20000

    invoke-static {v0, v5}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->readFile(Ljava/io/File;I)[B

    move-result-object v0

    invoke-static {v4, v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->writeAtomic(Landroid/util/AtomicFile;[B)V

    .line 215
    invoke-static {p0, v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->root(Landroid/content/Context;Z)Ljava/io/File;

    move-result-object v0

    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->syncDirectory(Ljava/io/File;)V

    .line 216
    iget-object v0, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    iget v3, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->uid:I

    invoke-static {p0, v0, v3}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->validateCurrent(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeBundle$State;I)V

    .line 217
    iget-object v0, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->validateActive(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeBundle$State;)V

    .line 218
    iget-object v0, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->privateBase(Landroid/content/Context;)Ljava/io/File;

    move-result-object v3

    invoke-static {v0, v2, v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->validateStored(Lio/github/leexeo/cage/space/ClaudeBundle$State;ZLjava/io/File;)V

    .line 219
    invoke-interface {v1}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v0

    :goto_2
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z

    move-result v1

    if-eqz v1, :cond_3

    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;

    iget-object v2, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    invoke-static {p0, v2}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->live(Landroid/content/Context;Ljava/lang/String;)Ljava/io/File;

    move-result-object v2

    invoke-static {v1, v2}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->verifyTree(Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;Ljava/io/File;)V

    goto :goto_2

    .line 220
    :cond_3
    const-string v0, "restored"

    iput-object v0, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    .line 221
    invoke-static {p0, p1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->saveJournal(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V

    .line 222
    invoke-static {p0, p1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->closeJournal(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V

    .line 223
    return-void

    .line 196
    :cond_4
    :goto_3
    iget-object v0, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    iget v1, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->uid:I

    invoke-static {p0, v0, v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->validateCurrent(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeBundle$State;I)V

    .line 197
    iget-object v0, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->validateActive(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeBundle$State;)V

    .line 198
    iget-object v0, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->privateBase(Landroid/content/Context;)Ljava/io/File;

    move-result-object v1

    invoke-static {v0, v2, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->validateStored(Lio/github/leexeo/cage/space/ClaudeBundle$State;ZLjava/io/File;)V

    .line 199
    const-string v0, "aborted"

    iput-object v0, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    .line 200
    invoke-static {p0, p1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->saveJournal(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V

    .line 201
    invoke-static {p0, p1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->closeJournal(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V

    .line 202
    return-void

    .line 193
    :cond_5
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u65e7 Claude \u5b89\u88c5\u8bb0\u5f55\u5907\u4efd\u6821\u9a8c\u5931\u8d25\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static running()Ljava/util/List;
    .locals 7
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "()",
            "Ljava/util/List<",
            "Landroid/app/ActivityManager$RunningAppProcessInfo;",
            ">;"
        }
    .end annotation

    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 243
    const-string v0, "top.niunaijun.blackbox.core.system.am.IBActivityManagerService"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    const-class v1, Ljava/lang/String;

    sget-object v2, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v1, v2}, [Ljava/lang/Class;

    move-result-object v1

    .line 244
    const-string v2, "getRunningAppProcesses"

    invoke-virtual {v0, v2, v1}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    .line 245
    const-string v1, "getBActivityManager"

    invoke-static {v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->service(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v1

    const/4 v2, 0x0

    invoke-static {v2}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v2

    const-string v3, "com.anthropic.claude"

    filled-new-array {v3, v2}, [Ljava/lang/Object;

    move-result-object v2

    invoke-virtual {v0, v1, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    .line 246
    if-eqz v0, :cond_5

    .line 247
    invoke-virtual {v0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v1

    const-string v2, "mAppProcessInfoList"

    invoke-virtual {v1, v2}, Ljava/lang/Class;->getField(Ljava/lang/String;)Ljava/lang/reflect/Field;

    move-result-object v1

    invoke-virtual {v1, v0}, Ljava/lang/reflect/Field;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    .line 248
    instance-of v1, v0, Ljava/util/List;

    const-string v2, "\u7a7a\u95f4\u8fdb\u7a0b\u8bb0\u5f55\u65e0\u6548\u3002"

    if-eqz v1, :cond_4

    .line 249
    new-instance v1, Ljava/util/ArrayList;

    invoke-direct {v1}, Ljava/util/ArrayList;-><init>()V

    .line 250
    check-cast v0, Ljava/util/List;

    invoke-interface {v0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v0

    :goto_0
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z

    move-result v4

    if-eqz v4, :cond_3

    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v4

    .line 251
    instance-of v5, v4, Landroid/app/ActivityManager$RunningAppProcessInfo;

    if-eqz v5, :cond_2

    .line 252
    check-cast v4, Landroid/app/ActivityManager$RunningAppProcessInfo;

    .line 253
    iget v5, v4, Landroid/app/ActivityManager$RunningAppProcessInfo;->pid:I

    if-lez v5, :cond_1

    iget v5, v4, Landroid/app/ActivityManager$RunningAppProcessInfo;->pid:I

    invoke-static {}, Landroid/os/Process;->myPid()I

    move-result v6

    if-eq v5, v6, :cond_1

    iget-object v5, v4, Landroid/app/ActivityManager$RunningAppProcessInfo;->processName:Ljava/lang/String;

    if-eqz v5, :cond_1

    iget-object v5, v4, Landroid/app/ActivityManager$RunningAppProcessInfo;->processName:Ljava/lang/String;

    .line 254
    invoke-virtual {v3, v5}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v5

    if-nez v5, :cond_0

    iget-object v5, v4, Landroid/app/ActivityManager$RunningAppProcessInfo;->processName:Ljava/lang/String;

    const-string v6, "com.anthropic.claude:"

    invoke-virtual {v5, v6}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v5

    if-eqz v5, :cond_1

    .line 256
    :cond_0
    invoke-interface {v1, v4}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    .line 257
    goto :goto_0

    .line 255
    :cond_1
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u65e0\u6cd5\u5b89\u5168\u786e\u8ba4 Claude \u6765\u5bbe\u8fdb\u7a0b\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 251
    :cond_2
    new-instance v0, Ljava/io/IOException;

    invoke-direct {v0, v2}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 258
    :cond_3
    return-object v1

    .line 248
    :cond_4
    new-instance v0, Ljava/io/IOException;

    invoke-direct {v0, v2}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 246
    :cond_5
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u65e0\u6cd5\u786e\u8ba4 Claude \u6765\u5bbe\u8fdb\u7a0b\u72b6\u6001\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0
.end method

.method private static saveJournal(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;)V
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 575
    new-instance v0, Lorg/json/JSONObject;

    invoke-direct {v0}, Lorg/json/JSONObject;-><init>()V

    const-string v1, "schema"

    const/4 v2, 0x1

    invoke-virtual {v0, v1, v2}, Lorg/json/JSONObject;->put(Ljava/lang/String;I)Lorg/json/JSONObject;

    move-result-object v0

    const-string v1, "host"

    const-string v2, "top.niunaijun.microdem"

    invoke-virtual {v0, v1, v2}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v0

    const-string v1, "package"

    const-string v2, "com.anthropic.claude"

    invoke-virtual {v0, v1, v2}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v0

    iget-object v1, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->id:Ljava/lang/String;

    .line 576
    const-string v2, "id"

    invoke-virtual {v0, v2, v1}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v0

    const-string v1, "phase"

    iget-object v2, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->phase:Ljava/lang/String;

    invoke-virtual {v0, v1, v2}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v0

    const-string v1, "uid"

    iget v2, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->uid:I

    invoke-virtual {v0, v1, v2}, Lorg/json/JSONObject;->put(Ljava/lang/String;I)Lorg/json/JSONObject;

    move-result-object v0

    iget-object v1, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->activeHash:Ljava/lang/String;

    .line 577
    const-string v2, "activeHash"

    invoke-virtual {v0, v2, v1}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v0

    iget-object v1, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->old:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    invoke-static {v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->encodeState(Lio/github/leexeo/cage/space/ClaudeBundle$State;)Lorg/json/JSONObject;

    move-result-object v1

    const-string v2, "old"

    invoke-virtual {v0, v2, v1}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v0

    iget-object v1, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->next:Lio/github/leexeo/cage/space/ClaudeBundle$State;

    .line 578
    invoke-static {v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->encodeState(Lio/github/leexeo/cage/space/ClaudeBundle$State;)Lorg/json/JSONObject;

    move-result-object v1

    const-string v2, "next"

    invoke-virtual {v0, v2, v1}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    move-result-object v0

    .line 579
    iget-object v1, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->backupHash:Ljava/lang/String;

    if-eqz v1, :cond_0

    const-string v1, "backupHash"

    iget-object p1, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Journal;->backupHash:Ljava/lang/String;

    invoke-virtual {v0, v1, p1}, Lorg/json/JSONObject;->put(Ljava/lang/String;Ljava/lang/Object;)Lorg/json/JSONObject;

    .line 580
    :cond_0
    new-instance p1, Landroid/util/AtomicFile;

    const/4 v1, 0x0

    invoke-static {p0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->root(Landroid/content/Context;Z)Ljava/io/File;

    move-result-object v2

    const-string v3, "pending-upgrade.json"

    invoke-static {v2, v3}, Lio/github/leexeo/cage/space/ClaudeBundle;->child(Ljava/io/File;Ljava/lang/String;)Ljava/io/File;

    move-result-object v2

    invoke-direct {p1, v2}, Landroid/util/AtomicFile;-><init>(Ljava/io/File;)V

    invoke-virtual {v0}, Lorg/json/JSONObject;->toString()Ljava/lang/String;

    move-result-object v0

    sget-object v2, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-virtual {v0, v2}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object v0

    invoke-static {p1, v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->writeAtomic(Landroid/util/AtomicFile;[B)V

    .line 581
    invoke-static {p0, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->root(Landroid/content/Context;Z)Ljava/io/File;

    move-result-object p0

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->syncDirectory(Ljava/io/File;)V

    .line 582
    return-void
.end method

.method private static scan(Ljava/lang/String;Ljava/io/File;Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;)Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 405
    invoke-static {p1}, Lio/github/leexeo/cage/space/ClaudeBundle;->exact(Ljava/io/File;)Ljava/io/File;

    .line 406
    new-instance v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;

    const/4 v1, 0x0

    invoke-direct {v0, v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;-><init>(Lio/github/leexeo/cage/space/ClaudeUpgrade$1;)V

    .line 407
    iput-object p0, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    .line 408
    invoke-virtual {p1}, Ljava/io/File;->exists()Z

    move-result p0

    iput-boolean p0, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->present:Z

    .line 409
    iget-boolean p0, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->present:Z

    if-eqz p0, :cond_0

    .line 410
    iget-object p0, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->entries:Ljava/util/List;

    const/4 v1, 0x0

    invoke-static {p1, p1, p0, p2, v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->collect(Ljava/io/File;Ljava/io/File;Ljava/util/List;Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;I)V

    .line 411
    iget-object p0, v0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->entries:Ljava/util/List;

    new-instance p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$$ExternalSyntheticLambda0;

    invoke-direct {p1}, Lio/github/leexeo/cage/space/ClaudeUpgrade$$ExternalSyntheticLambda0;-><init>()V

    invoke-static {p0, p1}, Ljava/util/Collections;->sort(Ljava/util/List;Ljava/util/Comparator;)V

    .line 413
    :cond_0
    return-object v0
.end method

.method private static service(Ljava/lang/String;)Ljava/lang/Object;
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 236
    const-string v0, "top.niunaijun.blackbox.BlackBoxCore"

    invoke-static {v0}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v0

    const/4 v1, 0x0

    new-array v2, v1, [Ljava/lang/Class;

    invoke-virtual {v0, p0, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p0

    const/4 v0, 0x0

    new-array v2, v1, [Ljava/lang/Object;

    invoke-virtual {p0, v0, v2}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    .line 237
    invoke-virtual {p0}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    move-result-object v0

    const-string v2, "getService"

    new-array v3, v1, [Ljava/lang/Class;

    invoke-virtual {v0, v2, v3}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v0

    new-array v1, v1, [Ljava/lang/Object;

    invoke-virtual {v0, p0, v1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p0

    .line 238
    if-eqz p0, :cond_0

    .line 239
    return-object p0

    .line 238
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string v0, "\u7a7a\u95f4\u79c1\u6709\u670d\u52a1\u6682\u4e0d\u53ef\u7528\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static stop(Landroid/content/Context;)V
    .locals 14
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 262
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->pending(Landroid/content/Context;)Z

    move-result p0

    if-eqz p0, :cond_7

    .line 263
    new-instance p0, Ljava/util/HashSet;

    invoke-direct {p0}, Ljava/util/HashSet;-><init>()V

    .line 264
    invoke-static {}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->running()Ljava/util/List;

    move-result-object v0

    invoke-interface {v0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v0

    :goto_0
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z

    move-result v1

    if-eqz v1, :cond_0

    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Landroid/app/ActivityManager$RunningAppProcessInfo;

    iget v1, v1, Landroid/app/ActivityManager$RunningAppProcessInfo;->pid:I

    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    invoke-interface {p0, v1}, Ljava/util/Set;->add(Ljava/lang/Object;)Z

    goto :goto_0

    .line 265
    :cond_0
    const-string v0, "getBPackageManager"

    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->service(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v0

    .line 266
    const-string v1, "top.niunaijun.blackbox.core.system.pm.IBPackageManagerService"

    invoke-static {v1}, Ljava/lang/Class;->forName(Ljava/lang/String;)Ljava/lang/Class;

    move-result-object v1

    .line 267
    const-class v2, Ljava/lang/String;

    sget-object v3, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v2, v3}, [Ljava/lang/Class;

    move-result-object v2

    const-string v3, "stopPackage"

    invoke-virtual {v1, v3, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v2

    const/4 v4, 0x0

    invoke-static {v4}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v5

    const-string v6, "com.anthropic.claude"

    filled-new-array {v6, v5}, [Ljava/lang/Object;

    move-result-object v5

    invoke-virtual {v2, v0, v5}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 268
    invoke-static {}, Landroid/os/SystemClock;->elapsedRealtime()J

    move-result-wide v7

    const-wide/16 v9, 0x1388

    add-long/2addr v7, v9

    .line 270
    :goto_1
    invoke-static {}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->running()Ljava/util/List;

    move-result-object v2

    .line 271
    invoke-interface {v2}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v5

    :goto_2
    invoke-interface {v5}, Ljava/util/Iterator;->hasNext()Z

    move-result v9

    if-eqz v9, :cond_1

    invoke-interface {v5}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v9

    check-cast v9, Landroid/app/ActivityManager$RunningAppProcessInfo;

    iget v9, v9, Landroid/app/ActivityManager$RunningAppProcessInfo;->pid:I

    invoke-static {v9}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v9

    invoke-interface {p0, v9}, Ljava/util/Set;->add(Ljava/lang/Object;)Z

    goto :goto_2

    .line 272
    :cond_1
    nop

    .line 273
    invoke-interface {p0}, Ljava/util/Set;->iterator()Ljava/util/Iterator;

    move-result-object v5

    move v9, v4

    :cond_2
    :goto_3
    invoke-interface {v5}, Ljava/util/Iterator;->hasNext()Z

    move-result v10

    if-eqz v10, :cond_3

    invoke-interface {v5}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v10

    check-cast v10, Ljava/lang/Integer;

    invoke-virtual {v10}, Ljava/lang/Integer;->intValue()I

    move-result v10

    new-instance v11, Ljava/io/File;

    new-instance v12, Ljava/lang/StringBuilder;

    invoke-direct {v12}, Ljava/lang/StringBuilder;-><init>()V

    const-string v13, "/proc/"

    invoke-virtual {v12, v13}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v12

    invoke-virtual {v12, v10}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v10

    invoke-virtual {v10}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v10

    invoke-direct {v11, v10}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {v11}, Ljava/io/File;->exists()Z

    move-result v10

    if-eqz v10, :cond_2

    const/4 v9, 0x1

    goto :goto_3

    .line 274
    :cond_3
    invoke-interface {v2}, Ljava/util/List;->isEmpty()Z

    move-result v5

    if-eqz v5, :cond_4

    if-nez v9, :cond_4

    return-void

    .line 275
    :cond_4
    invoke-interface {v2}, Ljava/util/List;->isEmpty()Z

    move-result v2

    if-nez v2, :cond_5

    const-class v2, Ljava/lang/String;

    sget-object v5, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v2, v5}, [Ljava/lang/Class;

    move-result-object v2

    invoke-virtual {v1, v3, v2}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object v2

    .line 276
    invoke-static {v4}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v5

    filled-new-array {v6, v5}, [Ljava/lang/Object;

    move-result-object v5

    invoke-virtual {v2, v0, v5}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 277
    :cond_5
    const-wide/16 v9, 0x64

    invoke-static {v9, v10}, Ljava/lang/Thread;->sleep(J)V

    .line 278
    invoke-static {}, Landroid/os/SystemClock;->elapsedRealtime()J

    move-result-wide v9

    cmp-long v2, v9, v7

    if-gez v2, :cond_6

    goto/16 :goto_1

    .line 279
    :cond_6
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Claude \u6765\u5bbe\u8fdb\u7a0b\u5c1a\u672a\u5b8c\u5168\u9000\u51fa\uff0c\u672a\u7ee7\u7eed\u6539\u52a8\u6570\u636e\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 262
    :cond_7
    new-instance p0, Ljava/io/IOException;

    const-string v0, "Claude \u5347\u7ea7\u542f\u52a8\u4fdd\u62a4\u672a\u751f\u6548\u3002"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static supportedMode(ZI)Z
    .locals 0

    .line 453
    if-eqz p0, :cond_0

    const/16 p0, 0x7ff

    goto :goto_0

    :cond_0
    const/16 p0, 0x1ff

    :goto_0
    not-int p0, p0

    and-int/2addr p0, p1

    if-nez p0, :cond_1

    const/4 p0, 0x1

    goto :goto_1

    :cond_1
    const/4 p0, 0x0

    :goto_1
    return p0
.end method

.method private static syncDirectory(Ljava/io/File;)V
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 633
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->exact(Ljava/io/File;)Ljava/io/File;

    move-result-object p0

    invoke-virtual {p0}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object p0

    sget v0, Landroid/system/OsConstants;->O_RDONLY:I

    const/4 v1, 0x0

    invoke-static {p0, v0, v1}, Landroid/system/Os;->open(Ljava/lang/String;II)Ljava/io/FileDescriptor;

    move-result-object p0

    .line 635
    :try_start_0
    invoke-static {p0}, Landroid/system/Os;->fstat(Ljava/io/FileDescriptor;)Landroid/system/StructStat;

    move-result-object v0

    iget v0, v0, Landroid/system/StructStat;->st_mode:I

    invoke-static {v0}, Landroid/system/OsConstants;->S_ISDIR(I)Z

    move-result v0

    if-eqz v0, :cond_0

    .line 636
    invoke-static {p0}, Landroid/system/Os;->fsync(Ljava/io/FileDescriptor;)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 637
    invoke-static {p0}, Landroid/system/Os;->close(Ljava/io/FileDescriptor;)V

    .line 638
    return-void

    .line 635
    :cond_0
    :try_start_1
    new-instance v0, Ljava/io/IOException;

    const-string v1, "\u6062\u590d\u8bb0\u5f55\u7236\u8def\u5f84\u4e0d\u662f\u76ee\u5f55\u3002"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 637
    :catchall_0
    move-exception v0

    invoke-static {p0}, Landroid/system/Os;->close(Ljava/io/FileDescriptor;)V

    throw v0
.end method

.method private static validateActive(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeBundle$State;)V
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 293
    const/4 v0, 0x0

    invoke-static {p0, v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->root(Landroid/content/Context;Z)Ljava/io/File;

    move-result-object v0

    invoke-static {v0}, Lio/github/leexeo/cage/space/ClaudeBundle;->active(Ljava/io/File;)Landroid/util/AtomicFile;

    move-result-object v0

    invoke-virtual {v0}, Landroid/util/AtomicFile;->openRead()Ljava/io/FileInputStream;

    move-result-object v0

    const/high16 v1, 0x20000

    :try_start_0
    invoke-static {v0, v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->read(Ljava/io/InputStream;I)[B

    move-result-object v1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    if-eqz v0, :cond_0

    invoke-virtual {v0}, Ljava/io/InputStream;->close()V

    .line 294
    :cond_0
    new-instance v0, Lorg/json/JSONObject;

    new-instance v2, Ljava/lang/String;

    sget-object v3, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-direct {v2, v1, v3}, Ljava/lang/String;-><init>([BLjava/nio/charset/Charset;)V

    invoke-direct {v0, v2}, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V

    .line 295
    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeBundle;->privateBase(Landroid/content/Context;)Ljava/io/File;

    move-result-object v1

    .line 294
    const/4 v2, 0x1

    invoke-static {p0, v0, v2, v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->decodeState(Landroid/content/Context;Lorg/json/JSONObject;ZLjava/io/File;)Lio/github/leexeo/cage/space/ClaudeBundle$State;

    move-result-object p0

    .line 296
    iget-wide v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->version:J

    iget-wide v2, p1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->version:J

    cmp-long v0, v0, v2

    if-nez v0, :cond_1

    iget-object v0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directory:Ljava/lang/String;

    iget-object v1, p1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->directory:Ljava/lang/String;

    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_1

    iget-object p0, p0, Lio/github/leexeo/cage/space/ClaudeBundle$State;->signer:Ljava/lang/String;

    iget-object p1, p1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->signer:Ljava/lang/String;

    invoke-virtual {p0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_1

    .line 298
    return-void

    .line 297
    :cond_1
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u5df2\u53d1\u5e03\u72b6\u6001\u4e0e\u6062\u590d\u8bb0\u5f55\u4e0d\u4e00\u81f4\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 293
    :catchall_0
    move-exception p0

    if-eqz v0, :cond_2

    :try_start_1
    invoke-virtual {v0}, Ljava/io/InputStream;->close()V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    goto :goto_0

    :catchall_1
    move-exception p1

    invoke-virtual {p0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :cond_2
    :goto_0
    throw p0
.end method

.method private static validateCurrent(Landroid/content/Context;Lio/github/leexeo/cage/space/ClaudeBundle$State;I)V
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 283
    new-instance v0, Lio/github/leexeo/cage/space/SpacePackages;

    invoke-direct {v0, p0}, Lio/github/leexeo/cage/space/SpacePackages;-><init>(Landroid/content/Context;)V

    .line 284
    const-string p0, "com.anthropic.claude"

    invoke-virtual {v0, p0}, Lio/github/leexeo/cage/space/SpacePackages;->installed(Ljava/lang/String;)Landroid/content/pm/PackageInfo;

    move-result-object v1

    .line 285
    if-lez p2, :cond_0

    if-eqz v1, :cond_0

    invoke-virtual {v0, v1}, Lio/github/leexeo/cage/space/SpacePackages;->privateCopy(Landroid/content/pm/PackageInfo;)Z

    move-result v0

    if-eqz v0, :cond_0

    iget-object v0, v1, Landroid/content/pm/PackageInfo;->packageName:Ljava/lang/String;

    .line 286
    invoke-virtual {p0, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_0

    invoke-static {v1}, Lio/github/leexeo/cage/space/SpacePackages;->version(Landroid/content/pm/PackageInfo;)J

    move-result-wide v2

    iget-wide p0, p1, Lio/github/leexeo/cage/space/ClaudeBundle$State;->version:J

    cmp-long p0, v2, p0

    if-nez p0, :cond_0

    iget-object p0, v1, Landroid/content/pm/PackageInfo;->applicationInfo:Landroid/content/pm/ApplicationInfo;

    iget p0, p0, Landroid/content/pm/ApplicationInfo;->uid:I

    if-ne p0, p2, :cond_0

    .line 289
    return-void

    .line 288
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u79c1\u6709\u5b89\u88c5\u7248\u672c\u6216\u539f\u5e94\u7528\u8eab\u4efd\u4e0d\u4e00\u81f4\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static verifyTree(Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;Ljava/io/File;)V
    .locals 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 509
    iget-object v0, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->name:Ljava/lang/String;

    new-instance v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;

    const/4 v2, 0x0

    invoke-direct {v1, v2}, Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;-><init>(Lio/github/leexeo/cage/space/ClaudeUpgrade$1;)V

    invoke-static {v0, p1, v1}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->scan(Ljava/lang/String;Ljava/io/File;Lio/github/leexeo/cage/space/ClaudeUpgrade$Budget;)Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;

    move-result-object p1

    .line 510
    iget-boolean v0, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->present:Z

    iget-boolean v1, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->present:Z

    if-ne v0, v1, :cond_3

    iget-object v0, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->entries:Ljava/util/List;

    invoke-interface {v0}, Ljava/util/List;->size()I

    move-result v0

    iget-object v1, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->entries:Ljava/util/List;

    invoke-interface {v1}, Ljava/util/List;->size()I

    move-result v1

    if-ne v0, v1, :cond_3

    .line 512
    const/4 v0, 0x0

    :goto_0
    iget-object v1, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->entries:Ljava/util/List;

    invoke-interface {v1}, Ljava/util/List;->size()I

    move-result v1

    if-ge v0, v1, :cond_2

    .line 513
    iget-object v1, p0, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->entries:Ljava/util/List;

    invoke-interface {v1, v0}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;

    iget-object v2, p1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Tree;->entries:Ljava/util/List;

    invoke-interface {v2, v0}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;

    .line 514
    iget-object v3, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    iget-object v4, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->path:Ljava/lang/String;

    invoke-virtual {v3, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-eqz v3, :cond_1

    iget-boolean v3, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->directory:Z

    iget-boolean v4, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->directory:Z

    if-ne v3, v4, :cond_1

    iget v3, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->mode:I

    iget v4, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->mode:I

    if-ne v3, v4, :cond_1

    iget v3, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->gid:I

    iget v4, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->gid:I

    if-ne v3, v4, :cond_1

    iget-wide v3, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->size:J

    iget-wide v5, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->size:J

    cmp-long v3, v3, v5

    if-nez v3, :cond_1

    iget-object v3, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->hash:Ljava/lang/String;

    iget-object v4, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->hash:Ljava/lang/String;

    .line 515
    invoke-virtual {v3, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-eqz v3, :cond_1

    iget-boolean v3, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->directory:Z

    if-nez v3, :cond_0

    iget-wide v3, v1, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->modified:J

    iget-wide v1, v2, Lio/github/leexeo/cage/space/ClaudeUpgrade$Entry;->modified:J

    cmp-long v1, v3, v1

    if-nez v1, :cond_1

    .line 512
    :cond_0
    add-int/lit8 v0, v0, 0x1

    goto :goto_0

    .line 516
    :cond_1
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u6570\u636e\u5185\u5bb9\u6216\u6587\u4ef6\u5c5e\u6027\u6821\u9a8c\u5931\u8d25\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 518
    :cond_2
    return-void

    .line 511
    :cond_3
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Claude \u6570\u636e\u76ee\u5f55\u96c6\u5408\u53d1\u751f\u53d8\u5316\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method private static writeAtomic(Landroid/util/AtomicFile;[B)V
    .locals 5
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 597
    nop

    .line 599
    :try_start_0
    invoke-virtual {p0}, Landroid/util/AtomicFile;->startWrite()Ljava/io/FileOutputStream;

    move-result-object v0
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_1

    .line 600
    :try_start_1
    invoke-virtual {v0, p1}, Ljava/io/FileOutputStream;->write([B)V

    .line 601
    invoke-virtual {p0, v0}, Landroid/util/AtomicFile;->finishWrite(Ljava/io/FileOutputStream;)V

    .line 602
    invoke-virtual {p0}, Landroid/util/AtomicFile;->getBaseFile()Ljava/io/File;

    move-result-object v1

    invoke-static {v1}, Lio/github/leexeo/cage/space/ClaudeBundle;->exact(Ljava/io/File;)Ljava/io/File;

    move-result-object v1

    .line 603
    new-instance v2, Ljava/io/File;

    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v3, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v3

    const-string v4, ".new"

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    invoke-direct {v2, v3}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {v2}, Ljava/io/File;->exists()Z

    move-result v2

    if-nez v2, :cond_0

    new-instance v2, Ljava/io/File;

    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v3, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v3

    const-string v4, ".bak"

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    invoke-direct {v2, v3}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {v2}, Ljava/io/File;->exists()Z

    move-result v2

    if-nez v2, :cond_0

    array-length v2, p1

    .line 604
    invoke-static {v1, v2}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->readFile(Ljava/io/File;I)[B

    move-result-object v1

    invoke-static {p1, v1}, Ljava/util/Arrays;->equals([B[B)Z

    move-result p1

    if-eqz p1, :cond_0

    .line 609
    nop

    .line 610
    return-void

    .line 605
    :cond_0
    new-instance p1, Ljava/io/IOException;

    const-string v1, "Claude \u6062\u590d\u8bb0\u5f55\u672a\u5b8c\u6574\u63d0\u4ea4\u3002"

    invoke-direct {p1, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_0

    .line 606
    :catch_0
    move-exception p1

    goto :goto_0

    :catch_1
    move-exception p1

    const/4 v0, 0x0

    .line 607
    :goto_0
    if-eqz v0, :cond_1

    invoke-virtual {p0, v0}, Landroid/util/AtomicFile;->failWrite(Ljava/io/FileOutputStream;)V

    .line 608
    :cond_1
    throw p1
.end method

.method private static writeNew(Ljava/io/File;[B)V
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 613
    invoke-virtual {p0}, Ljava/io/File;->createNewFile()Z

    move-result v0

    if-eqz v0, :cond_0

    .line 614
    new-instance v0, Ljava/io/FileOutputStream;

    invoke-direct {v0, p0}, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V

    :try_start_0
    invoke-virtual {v0, p1}, Ljava/io/FileOutputStream;->write([B)V

    invoke-virtual {v0}, Ljava/io/FileOutputStream;->getFD()Ljava/io/FileDescriptor;

    move-result-object p1

    invoke-virtual {p1}, Ljava/io/FileDescriptor;->sync()V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    invoke-virtual {v0}, Ljava/io/FileOutputStream;->close()V

    .line 615
    invoke-virtual {p0}, Ljava/io/File;->getParentFile()Ljava/io/File;

    move-result-object p0

    invoke-static {p0}, Lio/github/leexeo/cage/space/ClaudeUpgrade;->syncDirectory(Ljava/io/File;)V

    .line 616
    return-void

    .line 614
    :catchall_0
    move-exception p0

    :try_start_1
    invoke-virtual {v0}, Ljava/io/FileOutputStream;->close()V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    goto :goto_0

    :catchall_1
    move-exception p1

    invoke-virtual {p0, p1}, Ljava/lang/Throwable;->addSuppressed(Ljava/lang/Throwable;)V

    :goto_0
    throw p0

    .line 613
    :cond_0
    new-instance p0, Ljava/io/IOException;

    const-string p1, "\u62d2\u7edd\u8986\u76d6\u5df2\u6709 Claude \u6062\u590d\u8bb0\u5f55\u3002"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

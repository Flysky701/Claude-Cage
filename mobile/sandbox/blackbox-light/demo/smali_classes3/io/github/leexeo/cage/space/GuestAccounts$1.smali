.class Lio/github/leexeo/cage/space/GuestAccounts$1;
.super Landroid/content/ContextWrapper;
.source "GuestAccounts.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingMethod;
    value = Lio/github/leexeo/cage/space/GuestAccounts;->serviceCreated(Landroid/app/Service;)V
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x0
    name = null
.end annotation


# direct methods
.method constructor <init>(Landroid/content/Context;)V
    .locals 0

    .line 237
    invoke-direct {p0, p1}, Landroid/content/ContextWrapper;-><init>(Landroid/content/Context;)V

    return-void
.end method


# virtual methods
.method public checkPermission(Ljava/lang/String;II)I
    .locals 1

    .line 239
    const-string v0, "android.permission.ACCOUNT_MANAGER"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_1

    .line 240
    invoke-static {p2, p3}, Lio/github/leexeo/cage/space/GuestAccounts;->access$000(II)Z

    move-result p1

    if-eqz p1, :cond_0

    const/4 p1, 0x0

    goto :goto_0

    :cond_0
    const/4 p1, -0x1

    :goto_0
    return p1

    .line 241
    :cond_1
    invoke-super {p0, p1, p2, p3}, Landroid/content/ContextWrapper;->checkPermission(Ljava/lang/String;II)I

    move-result p1

    return p1
.end method

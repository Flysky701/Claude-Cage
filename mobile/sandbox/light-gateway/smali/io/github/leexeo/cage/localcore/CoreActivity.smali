.class public final Lio/github/leexeo/cage/localcore/CoreActivity;
.super Landroid/app/Activity;
.source "CoreActivity.java"


# static fields
.field private static final VPN_CONSENT:I = 0x6e


# instance fields
.field private autoStarted:Z

.field private feedback:Landroid/widget/TextView;

.field private input:Landroid/widget/EditText;

.field private final main:Landroid/os/Handler;

.field private prepare:Z

.field private final refresh:Ljava/lang/Runnable;

.field private save:Landroid/widget/Button;

.field private saving:Z

.field private start:Landroid/widget/Button;

.field private state:Landroid/widget/TextView;

.field private stop:Landroid/widget/Button;


# direct methods
.method public constructor <init>()V
    .locals 2

    .line 12
    invoke-direct {p0}, Landroid/app/Activity;-><init>()V

    .line 14
    new-instance v0, Landroid/os/Handler;

    invoke-static {}, Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;

    move-result-object v1

    invoke-direct {v0, v1}, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V

    iput-object v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->main:Landroid/os/Handler;

    .line 19
    new-instance v0, Lio/github/leexeo/cage/localcore/CoreActivity$1;

    invoke-direct {v0, p0}, Lio/github/leexeo/cage/localcore/CoreActivity$1;-><init>(Lio/github/leexeo/cage/localcore/CoreActivity;)V

    iput-object v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->refresh:Ljava/lang/Runnable;

    return-void
.end method

.method static synthetic access$000(Lio/github/leexeo/cage/localcore/CoreActivity;)V
    .locals 0

    .line 12
    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->update()V

    return-void
.end method

.method static synthetic access$100(Lio/github/leexeo/cage/localcore/CoreActivity;)Landroid/os/Handler;
    .locals 0

    .line 12
    iget-object p0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->main:Landroid/os/Handler;

    return-object p0
.end method

.method private button(Landroid/widget/LinearLayout;Ljava/lang/String;)Landroid/widget/Button;
    .locals 1

    .line 90
    new-instance v0, Landroid/widget/Button;

    invoke-direct {v0, p0}, Landroid/widget/Button;-><init>(Landroid/content/Context;)V

    invoke-virtual {v0, p2}, Landroid/widget/Button;->setText(Ljava/lang/CharSequence;)V

    invoke-virtual {p1, v0}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    return-object v0
.end method

.method private startNetwork()V
    .locals 2

    .line 94
    const/4 v0, 0x1

    iput-boolean v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->autoStarted:Z

    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->feedback:Landroid/widget/TextView;

    const-string v1, ""

    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    .line 96
    :try_start_0
    invoke-static {p0}, Landroid/net/VpnService;->prepare(Landroid/content/Context;)Landroid/content/Intent;

    move-result-object v0

    .line 97
    if-eqz v0, :cond_0

    const/16 v1, 0x6e

    invoke-virtual {p0, v0, v1}, Lio/github/leexeo/cage/localcore/CoreActivity;->startActivityForResult(Landroid/content/Intent;I)V

    goto :goto_0

    .line 98
    :cond_0
    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->startPreparedNetwork()V
    :try_end_0
    .catch Ljava/lang/RuntimeException; {:try_start_0 .. :try_end_0} :catch_0

    .line 100
    :goto_0
    goto :goto_1

    :catch_0
    move-exception v0

    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->feedback:Landroid/widget/TextView;

    const-string v1, "\u7cfb\u7edf\u6682\u65f6\u65e0\u6cd5\u542f\u52a8\u7f51\u5173\uff0c\u8bf7\u91cd\u8bd5\u3002"

    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    .line 101
    :goto_1
    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->update()V

    .line 102
    return-void
.end method

.method private startPreparedNetwork()V
    .locals 2

    .line 105
    new-instance v0, Landroid/content/Intent;

    const-class v1, Lio/github/leexeo/cage/localcore/CoreService;

    invoke-direct {v0, p0, v1}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V

    invoke-virtual {p0, v0}, Lio/github/leexeo/cage/localcore/CoreActivity;->startForegroundService(Landroid/content/Intent;)Landroid/content/ComponentName;

    .line 106
    return-void
.end method

.method private update()V
    .locals 11

    .line 118
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->state:Landroid/widget/TextView;

    if-nez v0, :cond_0

    return-void

    .line 119
    :cond_0
    invoke-static {p0}, Lio/github/leexeo/cage/localcore/Settings;->configured(Landroid/content/Context;)Z

    move-result v0

    .line 120
    invoke-static {p0}, Lio/github/leexeo/cage/localcore/Settings;->vlessFile(Landroid/content/Context;)Ljava/io/File;

    move-result-object v1

    invoke-virtual {v1}, Ljava/io/File;->isFile()Z

    move-result v1

    .line 121
    sget-object v2, Lio/github/leexeo/cage/localcore/CoreService;->current:Lio/github/leexeo/cage/localcore/CoreService;

    .line 122
    sget-boolean v3, Lio/github/leexeo/cage/localcore/CoreService;->running:Z

    .line 123
    const/4 v4, 0x0

    const/4 v5, 0x1

    if-eqz v2, :cond_1

    invoke-virtual {v2}, Lio/github/leexeo/cage/localcore/CoreService;->tunnelReady()Z

    move-result v6

    if-eqz v6, :cond_1

    move v6, v5

    goto :goto_0

    :cond_1
    move v6, v4

    .line 124
    :goto_0
    if-eqz v2, :cond_2

    invoke-virtual {v2}, Lio/github/leexeo/cage/localcore/CoreService;->isAlwaysOn()Z

    move-result v7

    if-eqz v7, :cond_2

    move v7, v5

    goto :goto_1

    :cond_2
    move v7, v4

    .line 125
    :goto_1
    if-eqz v2, :cond_3

    invoke-virtual {v2}, Lio/github/leexeo/cage/localcore/CoreService;->isLockdownEnabled()Z

    move-result v8

    if-eqz v8, :cond_3

    move v8, v5

    goto :goto_2

    :cond_3
    move v8, v4

    .line 126
    :goto_2
    if-eqz v2, :cond_4

    invoke-virtual {v2}, Lio/github/leexeo/cage/localcore/CoreService;->safeReady()Z

    move-result v2

    if-eqz v2, :cond_4

    move v2, v5

    goto :goto_3

    :cond_4
    move v2, v4

    .line 127
    :goto_3
    iget-boolean v9, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->prepare:Z

    if-eqz v9, :cond_5

    if-eqz v2, :cond_5

    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->isFinishing()Z

    move-result v9

    if-nez v9, :cond_5

    .line 128
    new-instance v0, Landroid/content/Intent;

    invoke-direct {v0}, Landroid/content/Intent;-><init>()V

    const-string v1, "protectionReady"

    invoke-virtual {v0, v1, v5}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Z)Landroid/content/Intent;

    move-result-object v0

    const-string v1, "wholeDevice"

    invoke-virtual {v0, v1, v5}, Landroid/content/Intent;->putExtra(Ljava/lang/String;Z)Landroid/content/Intent;

    move-result-object v0

    const/4 v1, -0x1

    invoke-virtual {p0, v1, v0}, Lio/github/leexeo/cage/localcore/CoreActivity;->setResult(ILandroid/content/Intent;)V

    .line 129
    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->finish()V

    return-void

    .line 131
    :cond_5
    iget-boolean v9, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->prepare:Z

    if-eqz v9, :cond_6

    if-eqz v0, :cond_6

    if-nez v3, :cond_6

    iget-boolean v9, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->autoStarted:Z

    if-nez v9, :cond_6

    iget-boolean v9, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->saving:Z

    if-nez v9, :cond_6

    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->startNetwork()V

    return-void

    .line 132
    :cond_6
    iget-object v9, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->state:Landroid/widget/TextView;

    new-instance v10, Ljava/lang/StringBuilder;

    invoke-direct {v10}, Ljava/lang/StringBuilder;-><init>()V

    if-eqz v1, :cond_7

    const-string v1, "\u51fa\u53e3\u6a21\u5f0f\uff1aVLESS \u517c\u5bb9\u6838\u5fc3\n"

    goto :goto_4

    :cond_7
    const-string v1, "\u51fa\u53e3\u6a21\u5f0f\uff1aSOCKS5\n"

    :goto_4
    invoke-virtual {v10, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    if-eqz v2, :cond_8

    const-string v2, "\u5b89\u5168\u4fdd\u62a4\u5df2\u5c31\u7eea \u00b7 \u5168\u624b\u673a VPN \u96a7\u9053\u5df2\u542f\u52a8"

    goto :goto_7

    .line 133
    :cond_8
    if-eqz v6, :cond_b

    .line 135
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v6, "\u96a7\u9053\u5df2\u542f\u52a8 \u00b7 \u5c1a\u672a\u5f00\u542f\u5b8c\u6574\u65ad\u7f51\u4fdd\u62a4\n\u59cb\u7ec8\u5f00\u542f\uff1a"

    invoke-virtual {v2, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    .line 134
    const-string v6, "\u5df2\u5f00\u542f"

    const-string v10, "\u672a\u5f00\u542f"

    if-eqz v7, :cond_9

    move-object v7, v6

    goto :goto_5

    :cond_9
    move-object v7, v10

    :goto_5
    invoke-virtual {v2, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    const-string v7, "\n\u963b\u6b62\u672a\u8fde\u63a5\u6d41\u91cf\uff1a"

    invoke-virtual {v2, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    .line 135
    if-eqz v8, :cond_a

    goto :goto_6

    :cond_a
    move-object v6, v10

    :goto_6
    invoke-virtual {v2, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    goto :goto_7

    .line 136
    :cond_b
    if-eqz v3, :cond_c

    const-string v2, "\u6b63\u5728\u5efa\u7acb\u5168\u624b\u673a VPN \u96a7\u9053\u2026"

    goto :goto_7

    .line 137
    :cond_c
    sget-boolean v2, Lio/github/leexeo/cage/localcore/CoreService;->startFailed:Z

    if-eqz v2, :cond_d

    const-string v2, "\u542f\u52a8\u5931\u8d25\uff0c\u8bf7\u6838\u5bf9\u51fa\u53e3\u548c\u7f51\u7edc\u3002"

    goto :goto_7

    .line 138
    :cond_d
    if-eqz v0, :cond_e

    const-string v2, "\u51fa\u53e3\u5df2\u4fdd\u5b58 \u00b7 \u7f51\u5173\u5df2\u505c\u6b62"

    goto :goto_7

    :cond_e
    const-string v2, "\u8bf7\u5148\u4fdd\u5b58 SOCKS5 \u51fa\u53e3\u3002"

    :goto_7
    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    .line 132
    invoke-virtual {v9, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    .line 139
    iget-object v1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->start:Landroid/widget/Button;

    if-eqz v0, :cond_f

    if-nez v3, :cond_f

    iget-boolean v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->saving:Z

    if-nez v0, :cond_f

    move v0, v5

    goto :goto_8

    :cond_f
    move v0, v4

    :goto_8
    invoke-virtual {v1, v0}, Landroid/widget/Button;->setEnabled(Z)V

    .line 140
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->stop:Landroid/widget/Button;

    invoke-virtual {v0, v3}, Landroid/widget/Button;->setEnabled(Z)V

    .line 141
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->save:Landroid/widget/Button;

    if-nez v3, :cond_10

    iget-boolean v1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->saving:Z

    if-nez v1, :cond_10

    move v1, v5

    goto :goto_9

    :cond_10
    move v1, v4

    :goto_9
    invoke-virtual {v0, v1}, Landroid/widget/Button;->setEnabled(Z)V

    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->input:Landroid/widget/EditText;

    if-nez v3, :cond_11

    iget-boolean v1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->saving:Z

    if-nez v1, :cond_11

    move v4, v5

    :cond_11
    invoke-virtual {v0, v4}, Landroid/widget/EditText;->setEnabled(Z)V

    .line 142
    return-void
.end method


# virtual methods
.method synthetic lambda$onCreate$0$io-github-leexeo-cage-localcore-CoreActivity(Z)V
    .locals 1

    .line 61
    const/4 v0, 0x0

    iput-boolean v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->saving:Z

    .line 62
    if-eqz p1, :cond_0

    iput-boolean v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->autoStarted:Z

    .line 63
    :cond_0
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->feedback:Landroid/widget/TextView;

    if-eqz p1, :cond_1

    const-string p1, "\u51fa\u53e3\u5df2\u4fdd\u5b58\u3002"

    goto :goto_0

    :cond_1
    const-string p1, "\u4fdd\u5b58\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5\u3002"

    :goto_0
    invoke-virtual {v0, p1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    .line 64
    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->update()V

    .line 65
    return-void
.end method

.method synthetic lambda$onCreate$1$io-github-leexeo-cage-localcore-CoreActivity(Lio/github/leexeo/cage/localcore/Upstream;)V
    .locals 2

    .line 57
    :try_start_0
    invoke-static {p0, p1}, Lio/github/leexeo/cage/localcore/Settings;->save(Landroid/content/Context;Lio/github/leexeo/cage/localcore/Upstream;)V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 58
    const/4 p1, 0x1

    goto :goto_0

    :catch_0
    move-exception p1

    const/4 p1, 0x0

    .line 59
    :goto_0
    nop

    .line 60
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->main:Landroid/os/Handler;

    new-instance v1, Lio/github/leexeo/cage/localcore/CoreActivity$$ExternalSyntheticLambda0;

    invoke-direct {v1, p0, p1}, Lio/github/leexeo/cage/localcore/CoreActivity$$ExternalSyntheticLambda0;-><init>(Lio/github/leexeo/cage/localcore/CoreActivity;Z)V

    invoke-virtual {v0, v1}, Landroid/os/Handler;->post(Ljava/lang/Runnable;)Z

    .line 66
    return-void
.end method

.method synthetic lambda$onCreate$2$io-github-leexeo-cage-localcore-CoreActivity(Landroid/view/View;)V
    .locals 2

    .line 52
    :try_start_0
    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->input:Landroid/widget/EditText;

    invoke-virtual {p1}, Landroid/widget/EditText;->getText()Landroid/text/Editable;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/Object;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-static {p1}, Lio/github/leexeo/cage/localcore/Upstream;->parse(Ljava/lang/String;)Lio/github/leexeo/cage/localcore/Upstream;

    move-result-object p1
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 53
    nop

    .line 54
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->input:Landroid/widget/EditText;

    const-string v1, ""

    invoke-virtual {v0, v1}, Landroid/widget/EditText;->setText(Ljava/lang/CharSequence;)V

    const/4 v0, 0x1

    iput-boolean v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->saving:Z

    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->update()V

    .line 55
    new-instance v0, Ljava/lang/Thread;

    new-instance v1, Lio/github/leexeo/cage/localcore/CoreActivity$$ExternalSyntheticLambda1;

    invoke-direct {v1, p0, p1}, Lio/github/leexeo/cage/localcore/CoreActivity$$ExternalSyntheticLambda1;-><init>(Lio/github/leexeo/cage/localcore/CoreActivity;Lio/github/leexeo/cage/localcore/Upstream;)V

    const-string p1, "Cage-save-upstream"

    invoke-direct {v0, v1, p1}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;Ljava/lang/String;)V

    .line 66
    invoke-virtual {v0}, Ljava/lang/Thread;->start()V

    .line 67
    return-void

    .line 53
    :catch_0
    move-exception p1

    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->feedback:Landroid/widget/TextView;

    const-string v0, "\u8bf7\u8f93\u5165\u542b\u4e3b\u673a\u548c\u7aef\u53e3\u7684 socks5:// \u5730\u5740\uff1b\u8ba4\u8bc1\u9700\u540c\u65f6\u586b\u5199\u7528\u6237\u540d\u548c\u5bc6\u7801\u3002"

    invoke-virtual {p1, v0}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    return-void
.end method

.method synthetic lambda$onCreate$3$io-github-leexeo-cage-localcore-CoreActivity(Landroid/view/View;)V
    .locals 0

    .line 70
    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->startNetwork()V

    return-void
.end method

.method synthetic lambda$onCreate$4$io-github-leexeo-cage-localcore-CoreActivity(Landroid/view/View;)V
    .locals 1

    .line 72
    const/4 p1, 0x1

    iput-boolean p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->autoStarted:Z

    .line 73
    new-instance p1, Landroid/content/Intent;

    const-class v0, Lio/github/leexeo/cage/localcore/CoreService;

    invoke-direct {p1, p0, v0}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V

    const-string v0, "STOP"

    invoke-virtual {p1, v0}, Landroid/content/Intent;->setAction(Ljava/lang/String;)Landroid/content/Intent;

    move-result-object p1

    invoke-virtual {p0, p1}, Lio/github/leexeo/cage/localcore/CoreActivity;->startService(Landroid/content/Intent;)Landroid/content/ComponentName;

    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->update()V

    .line 74
    return-void
.end method

.method synthetic lambda$onCreate$5$io-github-leexeo-cage-localcore-CoreActivity(Landroid/view/View;)V
    .locals 1

    .line 77
    :try_start_0
    new-instance p1, Landroid/content/Intent;

    const-string v0, "android.settings.VPN_SETTINGS"

    invoke-direct {p1, v0}, Landroid/content/Intent;-><init>(Ljava/lang/String;)V

    invoke-virtual {p0, p1}, Lio/github/leexeo/cage/localcore/CoreActivity;->startActivity(Landroid/content/Intent;)V
    :try_end_0
    .catch Ljava/lang/RuntimeException; {:try_start_0 .. :try_end_0} :catch_0

    .line 78
    goto :goto_0

    :catch_0
    move-exception p1

    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->feedback:Landroid/widget/TextView;

    const-string v0, "\u8bf7\u624b\u52a8\u6253\u5f00\u7cfb\u7edf\u8bbe\u7f6e \u2192 VPN\u3002"

    invoke-virtual {p1, v0}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    .line 79
    :goto_0
    return-void
.end method

.method protected onActivityResult(IILandroid/content/Intent;)V
    .locals 0

    .line 109
    invoke-super {p0, p1, p2, p3}, Landroid/app/Activity;->onActivityResult(IILandroid/content/Intent;)V

    .line 110
    const/16 p3, 0x6e

    if-eq p1, p3, :cond_0

    return-void

    .line 111
    :cond_0
    const/4 p1, -0x1

    if-ne p2, p1, :cond_1

    .line 112
    :try_start_0
    invoke-direct {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->startPreparedNetwork()V
    :try_end_0
    .catch Ljava/lang/RuntimeException; {:try_start_0 .. :try_end_0} :catch_0

    .line 113
    goto :goto_0

    :catch_0
    move-exception p1

    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->feedback:Landroid/widget/TextView;

    const-string p2, "\u7cfb\u7edf\u6682\u65f6\u65e0\u6cd5\u542f\u52a8\u7f51\u5173\uff0c\u8bf7\u91cd\u8bd5\u3002"

    invoke-virtual {p1, p2}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    goto :goto_0

    .line 114
    :cond_1
    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->feedback:Landroid/widget/TextView;

    const-string p2, "\u5c1a\u672a\u6388\u4e88\u7cfb\u7edf VPN \u6743\u9650\uff0c\u7a7a\u95f4\u65e0\u6cd5\u7ee7\u7eed\u3002"

    invoke-virtual {p1, p2}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    .line 115
    :goto_0
    return-void
.end method

.method public onCreate(Landroid/os/Bundle;)V
    .locals 5

    .line 24
    invoke-super {p0, p1}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V

    .line 25
    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->getIntent()Landroid/content/Intent;

    move-result-object v0

    invoke-virtual {v0}, Landroid/content/Intent;->getAction()Ljava/lang/String;

    move-result-object v0

    const-string v1, "io.github.leexeo.cage.space.ENSURE_NETWORK"

    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    iput-boolean v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->prepare:Z

    .line 26
    const/4 v0, 0x0

    invoke-virtual {p0, v0}, Lio/github/leexeo/cage/localcore/CoreActivity;->setResult(I)V

    .line 27
    iget-boolean v1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->prepare:Z

    if-eqz v1, :cond_1

    const-string v1, "top.niunaijun.microdem"

    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->getCallingPackage()Ljava/lang/String;

    move-result-object v2

    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_0

    .line 28
    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->getPackageManager()Landroid/content/pm/PackageManager;

    move-result-object v1

    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->getPackageName()Ljava/lang/String;

    move-result-object v2

    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->getCallingPackage()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v1, v2, v3}, Landroid/content/pm/PackageManager;->checkSignatures(Ljava/lang/String;Ljava/lang/String;)I

    move-result v1

    if-eqz v1, :cond_1

    .line 29
    :cond_0
    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->finish()V

    return-void

    .line 30
    :cond_1
    const/4 v1, 0x1

    if-eqz p1, :cond_2

    const-string v2, "autoStarted"

    invoke-virtual {p1, v2}, Landroid/os/Bundle;->getBoolean(Ljava/lang/String;)Z

    move-result p1

    if-eqz p1, :cond_2

    move p1, v1

    goto :goto_0

    :cond_2
    move p1, v0

    :goto_0
    iput-boolean p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->autoStarted:Z

    .line 31
    const-string p1, "Cage \u7a7a\u95f4\u7f51\u5173"

    invoke-virtual {p0, p1}, Lio/github/leexeo/cage/localcore/CoreActivity;->setTitle(Ljava/lang/CharSequence;)V

    .line 32
    new-instance p1, Landroid/widget/ScrollView;

    invoke-direct {p1, p0}, Landroid/widget/ScrollView;-><init>(Landroid/content/Context;)V

    .line 33
    invoke-virtual {p1, v1}, Landroid/widget/ScrollView;->setFitsSystemWindows(Z)V

    .line 34
    new-instance v2, Landroid/widget/LinearLayout;

    invoke-direct {v2, p0}, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V

    .line 35
    invoke-virtual {v2, v1}, Landroid/widget/LinearLayout;->setOrientation(I)V

    .line 36
    invoke-virtual {p0}, Lio/github/leexeo/cage/localcore/CoreActivity;->getResources()Landroid/content/res/Resources;

    move-result-object v3

    invoke-virtual {v3}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;

    move-result-object v3

    iget v3, v3, Landroid/util/DisplayMetrics;->density:F

    const/high16 v4, 0x41a00000    # 20.0f

    mul-float/2addr v3, v4

    invoke-static {v3}, Ljava/lang/Math;->round(F)I

    move-result v3

    .line 37
    invoke-virtual {v2, v3, v3, v3, v3}, Landroid/widget/LinearLayout;->setPadding(IIII)V

    .line 38
    invoke-virtual {v2, v1}, Landroid/widget/LinearLayout;->setFocusableInTouchMode(Z)V

    .line 39
    invoke-virtual {p1, v2}, Landroid/widget/ScrollView;->addView(Landroid/view/View;)V

    invoke-virtual {p0, p1}, Lio/github/leexeo/cage/localcore/CoreActivity;->setContentView(Landroid/view/View;)V

    .line 40
    new-instance p1, Landroid/widget/TextView;

    invoke-direct {p1, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V

    const-string v4, "\u7a7a\u95f4\u7f51\u5173"

    invoke-virtual {p1, v4}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    const/high16 v4, 0x41d00000    # 26.0f

    invoke-virtual {p1, v4}, Landroid/widget/TextView;->setTextSize(F)V

    invoke-virtual {v2, p1}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    .line 41
    new-instance p1, Landroid/widget/TextView;

    invoke-direct {p1, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V

    iput-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->state:Landroid/widget/TextView;

    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->state:Landroid/widget/TextView;

    invoke-virtual {p1, v0, v3, v0, v3}, Landroid/widget/TextView;->setPadding(IIII)V

    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->state:Landroid/widget/TextView;

    invoke-virtual {v2, p1}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    .line 42
    new-instance p1, Landroid/widget/EditText;

    invoke-direct {p1, p0}, Landroid/widget/EditText;-><init>(Landroid/content/Context;)V

    iput-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->input:Landroid/widget/EditText;

    .line 43
    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->input:Landroid/widget/EditText;

    const-string v3, "socks5://\u7528\u6237\u540d:\u5bc6\u7801@\u670d\u52a1\u5668:\u7aef\u53e3"

    invoke-virtual {p1, v3}, Landroid/widget/EditText;->setHint(Ljava/lang/CharSequence;)V

    .line 44
    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->input:Landroid/widget/EditText;

    const-string v3, "SOCKS5 \u51fa\u53e3\u5730\u5740\uff0c\u51ed\u636e\u5df2\u906e\u76d6"

    invoke-virtual {p1, v3}, Landroid/widget/EditText;->setContentDescription(Ljava/lang/CharSequence;)V

    .line 45
    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->input:Landroid/widget/EditText;

    const/16 v3, 0x81

    invoke-virtual {p1, v3}, Landroid/widget/EditText;->setInputType(I)V

    .line 46
    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->input:Landroid/widget/EditText;

    invoke-virtual {p1, v1}, Landroid/widget/EditText;->setSingleLine(Z)V

    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->input:Landroid/widget/EditText;

    invoke-virtual {p1, v0}, Landroid/widget/EditText;->setSaveEnabled(Z)V

    .line 47
    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->input:Landroid/widget/EditText;

    const/16 v0, 0x8

    invoke-virtual {p1, v0}, Landroid/widget/EditText;->setImportantForAutofill(I)V

    .line 48
    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->input:Landroid/widget/EditText;

    invoke-virtual {v2, p1}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    .line 49
    const-string p1, "\u4fdd\u5b58\u51fa\u53e3"

    invoke-direct {p0, v2, p1}, Lio/github/leexeo/cage/localcore/CoreActivity;->button(Landroid/widget/LinearLayout;Ljava/lang/String;)Landroid/widget/Button;

    move-result-object p1

    iput-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->save:Landroid/widget/Button;

    .line 50
    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->save:Landroid/widget/Button;

    new-instance v0, Lio/github/leexeo/cage/localcore/CoreActivity$$ExternalSyntheticLambda2;

    invoke-direct {v0, p0}, Lio/github/leexeo/cage/localcore/CoreActivity$$ExternalSyntheticLambda2;-><init>(Lio/github/leexeo/cage/localcore/CoreActivity;)V

    invoke-virtual {p1, v0}, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V

    .line 68
    new-instance p1, Landroid/widget/TextView;

    invoke-direct {p1, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V

    iput-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->feedback:Landroid/widget/TextView;

    .line 69
    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->feedback:Landroid/widget/TextView;

    invoke-virtual {p1, v1}, Landroid/widget/TextView;->setAccessibilityLiveRegion(I)V

    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->feedback:Landroid/widget/TextView;

    invoke-virtual {v2, p1}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    .line 70
    const-string p1, "\u5f00\u59cb"

    invoke-direct {p0, v2, p1}, Lio/github/leexeo/cage/localcore/CoreActivity;->button(Landroid/widget/LinearLayout;Ljava/lang/String;)Landroid/widget/Button;

    move-result-object p1

    iput-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->start:Landroid/widget/Button;

    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->start:Landroid/widget/Button;

    new-instance v0, Lio/github/leexeo/cage/localcore/CoreActivity$$ExternalSyntheticLambda3;

    invoke-direct {v0, p0}, Lio/github/leexeo/cage/localcore/CoreActivity$$ExternalSyntheticLambda3;-><init>(Lio/github/leexeo/cage/localcore/CoreActivity;)V

    invoke-virtual {p1, v0}, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V

    .line 71
    const-string p1, "\u505c\u6b62"

    invoke-direct {p0, v2, p1}, Lio/github/leexeo/cage/localcore/CoreActivity;->button(Landroid/widget/LinearLayout;Ljava/lang/String;)Landroid/widget/Button;

    move-result-object p1

    iput-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->stop:Landroid/widget/Button;

    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->stop:Landroid/widget/Button;

    new-instance v0, Lio/github/leexeo/cage/localcore/CoreActivity$$ExternalSyntheticLambda4;

    invoke-direct {v0, p0}, Lio/github/leexeo/cage/localcore/CoreActivity$$ExternalSyntheticLambda4;-><init>(Lio/github/leexeo/cage/localcore/CoreActivity;)V

    invoke-virtual {p1, v0}, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V

    .line 75
    const-string p1, "\u6253\u5f00\u7cfb\u7edf VPN \u8bbe\u7f6e"

    invoke-direct {p0, v2, p1}, Lio/github/leexeo/cage/localcore/CoreActivity;->button(Landroid/widget/LinearLayout;Ljava/lang/String;)Landroid/widget/Button;

    move-result-object p1

    .line 76
    new-instance v0, Lio/github/leexeo/cage/localcore/CoreActivity$$ExternalSyntheticLambda5;

    invoke-direct {v0, p0}, Lio/github/leexeo/cage/localcore/CoreActivity$$ExternalSyntheticLambda5;-><init>(Lio/github/leexeo/cage/localcore/CoreActivity;)V

    invoke-virtual {p1, v0}, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V

    .line 80
    new-instance p1, Landroid/widget/TextView;

    invoke-direct {p1, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V

    .line 81
    const-string v0, "\u8fd9\u662f\u5168\u624b\u673a VPN \u7f51\u5173\uff0c\u4f1a\u63a5\u7ba1\u672c\u7528\u6237\u4e0b\u5176\u4ed6\u5e94\u7528\u7684\u6d41\u91cf\u3002\n\u8bf7\u5728\u7cfb\u7edf VPN \u8bbe\u7f6e\u4e2d\u4e3a\u672c\u5e94\u7528\u5f00\u542f\u201c\u59cb\u7ec8\u5f00\u542f\u201d\u4e0e\u201c\u963b\u6b62\u672a\u8fde\u63a5\u6d41\u91cf\u201d\u3002\u5f00\u542f\u540e\uff0c\u7f51\u5173\u505c\u673a\u65f6\u624b\u673a\u5176\u4ed6\u5e94\u7528\u4e5f\u4f1a\u65ad\u7f51\u3002\n\u53ea\u6709\u8fd9\u4e24\u9879\u4fdd\u62a4\u53ca\u96a7\u9053\u5747\u5df2\u5f00\u542f\uff0c\u914d\u5957\u7a7a\u95f4\u624d\u53ef\u7ee7\u7eed\u3002Android \u6bcf\u4e2a\u7528\u6237\u53ea\u80fd\u542f\u7528\u4e00\u4e2a VPN\u3002\n\u96a7\u9053\u5df2\u542f\u52a8\u4e0d\u4ee3\u8868 Google \u6216 Claude \u5df2\u6210\u529f\u8054\u7f51\uff1b\u51fa\u53e3\u4e0d\u53ef\u7528\u65f6\u8fde\u63a5\u5931\u8d25\u3002\n\u5df2\u5bfc\u5165 VLESS \u914d\u7f6e\u65f6\u4f18\u5148\u4f7f\u7528\u517c\u5bb9\u6838\u5fc3\uff1b\u5355\u72ec\u4fdd\u5b58 SOCKS5 \u5730\u5740\u4e0d\u4f1a\u8986\u76d6\u6216\u79fb\u9664 VLESS \u914d\u7f6e\u3002"

    invoke-virtual {p1, v0}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    .line 86
    invoke-virtual {v2, p1}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    invoke-virtual {v2}, Landroid/widget/LinearLayout;->requestFocus()Z

    .line 87
    return-void
.end method

.method protected onPause()V
    .locals 2

    .line 148
    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->main:Landroid/os/Handler;

    iget-object v1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->refresh:Ljava/lang/Runnable;

    invoke-virtual {v0, v1}, Landroid/os/Handler;->removeCallbacks(Ljava/lang/Runnable;)V

    invoke-super {p0}, Landroid/app/Activity;->onPause()V

    return-void
.end method

.method protected onResume()V
    .locals 1

    .line 147
    invoke-super {p0}, Landroid/app/Activity;->onResume()V

    iget-object v0, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->refresh:Ljava/lang/Runnable;

    invoke-interface {v0}, Ljava/lang/Runnable;->run()V

    return-void
.end method

.method protected onSaveInstanceState(Landroid/os/Bundle;)V
    .locals 2

    .line 145
    invoke-super {p0, p1}, Landroid/app/Activity;->onSaveInstanceState(Landroid/os/Bundle;)V

    const-string v0, "autoStarted"

    iget-boolean v1, p0, Lio/github/leexeo/cage/localcore/CoreActivity;->autoStarted:Z

    invoke-virtual {p1, v0, v1}, Landroid/os/Bundle;->putBoolean(Ljava/lang/String;Z)V

    .line 146
    return-void
.end method

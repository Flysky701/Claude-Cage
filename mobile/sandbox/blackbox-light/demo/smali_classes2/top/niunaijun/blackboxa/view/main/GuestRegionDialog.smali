.class public final Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog;
.super Ljava/lang/Object;
.source "GuestRegionDialog.java"


# static fields
.field private static final ID:I = 0x434752


# direct methods
.method public constructor <init>()V
    .locals 0

    .line 11
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static add(Landroid/view/Menu;)V
    .locals 3

    .line 14
    if-eqz p0, :cond_0

    const v0, 0x434752

    const-string v1, "\u6765\u5bbe\u8bed\u8a00\u548c\u65f6\u533a"

    const/4 v2, 0x0

    invoke-interface {p0, v2, v0, v2, v1}, Landroid/view/Menu;->add(IIILjava/lang/CharSequence;)Landroid/view/MenuItem;

    .line 15
    :cond_0
    return-void
.end method

.method private static field(Landroid/app/Activity;Landroid/widget/LinearLayout;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Landroid/widget/EditText;
    .locals 1

    .line 53
    new-instance v0, Landroid/widget/TextView;

    invoke-direct {v0, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V

    .line 54
    invoke-virtual {v0, p2}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    .line 55
    invoke-virtual {p1, v0}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    .line 56
    new-instance p2, Landroid/widget/EditText;

    invoke-direct {p2, p0}, Landroid/widget/EditText;-><init>(Landroid/content/Context;)V

    .line 57
    const/4 p0, 0x1

    invoke-virtual {p2, p0}, Landroid/widget/EditText;->setSingleLine(Z)V

    .line 58
    invoke-virtual {p2, p3}, Landroid/widget/EditText;->setHint(Ljava/lang/CharSequence;)V

    .line 59
    invoke-virtual {p2, p4}, Landroid/widget/EditText;->setText(Ljava/lang/CharSequence;)V

    .line 60
    invoke-virtual {p1, p2}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    .line 61
    return-object p2
.end method

.method static synthetic lambda$open$0(Landroid/app/Activity;ILandroid/widget/EditText;Landroid/widget/EditText;Landroid/app/AlertDialog;Landroid/view/View;)V
    .locals 0

    .line 38
    :try_start_0
    new-instance p5, Ltop/niunaijun/blackbox/region/GuestRegion;

    invoke-virtual {p2}, Landroid/widget/EditText;->getText()Landroid/text/Editable;

    move-result-object p2

    invoke-virtual {p2}, Ljava/lang/Object;->toString()Ljava/lang/String;

    move-result-object p2

    invoke-virtual {p3}, Landroid/widget/EditText;->getText()Landroid/text/Editable;

    move-result-object p3

    invoke-virtual {p3}, Ljava/lang/Object;->toString()Ljava/lang/String;

    move-result-object p3

    invoke-direct {p5, p2, p3}, Ltop/niunaijun/blackbox/region/GuestRegion;-><init>(Ljava/lang/String;Ljava/lang/String;)V

    invoke-static {p0, p1, p5}, Ltop/niunaijun/blackbox/region/GuestRegion;->save(Landroid/content/Context;ILtop/niunaijun/blackbox/region/GuestRegion;)V

    .line 39
    invoke-virtual {p4}, Landroid/app/AlertDialog;->dismiss()V
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_1
    .catch Ljava/lang/IllegalArgumentException; {:try_start_0 .. :try_end_0} :catch_0

    .line 42
    goto :goto_1

    .line 40
    :catch_0
    move-exception p1

    goto :goto_0

    :catch_1
    move-exception p1

    .line 41
    :goto_0
    new-instance p2, Ljava/lang/StringBuilder;

    invoke-direct {p2}, Ljava/lang/StringBuilder;-><init>()V

    const-string p3, "\u4fdd\u5b58\u5931\u8d25\uff1a"

    invoke-virtual {p2, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p1}, Ljava/lang/Exception;->getMessage()Ljava/lang/String;

    move-result-object p1

    invoke-virtual {p2, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    const/4 p2, 0x1

    invoke-static {p0, p1, p2}, Landroid/widget/Toast;->makeText(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;

    move-result-object p0

    invoke-virtual {p0}, Landroid/widget/Toast;->show()V

    .line 43
    :goto_1
    return-void
.end method

.method static synthetic lambda$open$1(Landroid/app/Activity;ILandroid/app/AlertDialog;Landroid/view/View;)V
    .locals 0

    .line 46
    const/4 p3, 0x0

    :try_start_0
    invoke-static {p0, p1, p3}, Ltop/niunaijun/blackbox/region/GuestRegion;->save(Landroid/content/Context;ILtop/niunaijun/blackbox/region/GuestRegion;)V

    .line 47
    invoke-virtual {p2}, Landroid/app/AlertDialog;->dismiss()V
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0

    .line 48
    goto :goto_0

    :catch_0
    move-exception p1

    const-string p1, "\u6062\u590d\u5931\u8d25"

    const/4 p2, 0x1

    invoke-static {p0, p1, p2}, Landroid/widget/Toast;->makeText(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;

    move-result-object p0

    invoke-virtual {p0}, Landroid/widget/Toast;->show()V

    .line 49
    :goto_0
    return-void
.end method

.method public static open(Landroid/app/Activity;Landroid/view/MenuItem;I)Z
    .locals 12

    .line 17
    invoke-interface {p1}, Landroid/view/MenuItem;->getItemId()I

    move-result p1

    const v0, 0x434752

    const/4 v1, 0x0

    if-eq p1, v0, :cond_0

    return v1

    .line 20
    :cond_0
    const/4 p1, 0x1

    :try_start_0
    invoke-static {p0, p2}, Ltop/niunaijun/blackbox/region/GuestRegion;->read(Landroid/content/Context;I)Ltop/niunaijun/blackbox/region/GuestRegion;

    move-result-object v0
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_1
    .catch Ljava/lang/IllegalArgumentException; {:try_start_0 .. :try_end_0} :catch_0

    .line 24
    nop

    .line 25
    new-instance v2, Landroid/widget/LinearLayout;

    invoke-direct {v2, p0}, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V

    .line 26
    invoke-virtual {v2, p1}, Landroid/widget/LinearLayout;->setOrientation(I)V

    .line 27
    invoke-virtual {p0}, Landroid/app/Activity;->getResources()Landroid/content/res/Resources;

    move-result-object v3

    invoke-virtual {v3}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;

    move-result-object v3

    iget v3, v3, Landroid/util/DisplayMetrics;->density:F

    const/high16 v4, 0x41c00000    # 24.0f

    mul-float/2addr v3, v4

    float-to-int v3, v3

    .line 28
    invoke-virtual {v2, v3, v1, v3, v1}, Landroid/widget/LinearLayout;->setPadding(IIII)V

    .line 29
    const-string v1, ""

    if-nez v0, :cond_1

    move-object v3, v1

    goto :goto_0

    :cond_1
    iget-object v3, v0, Ltop/niunaijun/blackbox/region/GuestRegion;->language:Ljava/lang/String;

    :goto_0
    const-string v4, "\u8bed\u8a00\u6807\u7b7e"

    const-string v5, "en-US"

    invoke-static {p0, v2, v4, v5, v3}, Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog;->field(Landroid/app/Activity;Landroid/widget/LinearLayout;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Landroid/widget/EditText;

    move-result-object v9

    .line 30
    if-nez v0, :cond_2

    move-object v3, v1

    goto :goto_1

    :cond_2
    iget-object v3, v0, Ltop/niunaijun/blackbox/region/GuestRegion;->zone:Ljava/lang/String;

    :goto_1
    const-string v4, "\u65f6\u533a"

    const-string v5, "UTC"

    invoke-static {p0, v2, v4, v5, v3}, Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog;->field(Landroid/app/Activity;Landroid/widget/LinearLayout;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Landroid/widget/EditText;

    move-result-object v10

    .line 31
    new-instance v3, Landroid/app/AlertDialog$Builder;

    invoke-direct {v3, p0}, Landroid/app/AlertDialog$Builder;-><init>(Landroid/content/Context;)V

    const-string v4, "\u6765\u5bbe\u8bed\u8a00\u548c\u65f6\u533a"

    invoke-virtual {v3, v4}, Landroid/app/AlertDialog$Builder;->setTitle(Ljava/lang/CharSequence;)Landroid/app/AlertDialog$Builder;

    move-result-object v3

    new-instance v4, Ljava/lang/StringBuilder;

    invoke-direct {v4}, Ljava/lang/StringBuilder;-><init>()V

    .line 32
    if-nez v0, :cond_3

    const-string v1, "\u5f53\u524d\u8ddf\u968f\u624b\u673a\u3002"

    :cond_3
    invoke-virtual {v4, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, "\u8bbe\u7f6e\u7528\u4e8e\u5f53\u524d\u6765\u5bbe\uff0c\u4e0b\u6b21\u51b7\u542f\u52a8\u5e94\u7528\u65f6\u751f\u6548\u3002"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    invoke-virtual {v3, v0}, Landroid/app/AlertDialog$Builder;->setMessage(Ljava/lang/CharSequence;)Landroid/app/AlertDialog$Builder;

    move-result-object v0

    .line 33
    invoke-virtual {v0, v2}, Landroid/app/AlertDialog$Builder;->setView(Landroid/view/View;)Landroid/app/AlertDialog$Builder;

    move-result-object v0

    const-string v1, "\u4fdd\u5b58"

    const/4 v2, 0x0

    invoke-virtual {v0, v1, v2}, Landroid/app/AlertDialog$Builder;->setPositiveButton(Ljava/lang/CharSequence;Landroid/content/DialogInterface$OnClickListener;)Landroid/app/AlertDialog$Builder;

    move-result-object v0

    const-string v1, "\u53d6\u6d88"

    invoke-virtual {v0, v1, v2}, Landroid/app/AlertDialog$Builder;->setNegativeButton(Ljava/lang/CharSequence;Landroid/content/DialogInterface$OnClickListener;)Landroid/app/AlertDialog$Builder;

    move-result-object v0

    .line 34
    const-string v1, "\u8ddf\u968f\u624b\u673a"

    invoke-virtual {v0, v1, v2}, Landroid/app/AlertDialog$Builder;->setNeutralButton(Ljava/lang/CharSequence;Landroid/content/DialogInterface$OnClickListener;)Landroid/app/AlertDialog$Builder;

    move-result-object v0

    invoke-virtual {v0}, Landroid/app/AlertDialog$Builder;->create()Landroid/app/AlertDialog;

    move-result-object v0

    .line 35
    invoke-virtual {v0}, Landroid/app/AlertDialog;->show()V

    .line 36
    const/4 v1, -0x1

    invoke-virtual {v0, v1}, Landroid/app/AlertDialog;->getButton(I)Landroid/widget/Button;

    move-result-object v1

    new-instance v2, Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog$$ExternalSyntheticLambda0;

    move-object v6, v2

    move-object v7, p0

    move v8, p2

    move-object v11, v0

    invoke-direct/range {v6 .. v11}, Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog$$ExternalSyntheticLambda0;-><init>(Landroid/app/Activity;ILandroid/widget/EditText;Landroid/widget/EditText;Landroid/app/AlertDialog;)V

    invoke-virtual {v1, v2}, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V

    .line 44
    const/4 v1, -0x3

    invoke-virtual {v0, v1}, Landroid/app/AlertDialog;->getButton(I)Landroid/widget/Button;

    move-result-object v1

    new-instance v2, Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog$$ExternalSyntheticLambda1;

    invoke-direct {v2, p0, p2, v0}, Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog$$ExternalSyntheticLambda1;-><init>(Landroid/app/Activity;ILandroid/app/AlertDialog;)V

    invoke-virtual {v1, v2}, Landroid/widget/Button;->setOnClickListener(Landroid/view/View$OnClickListener;)V

    .line 50
    return p1

    .line 21
    :catch_0
    move-exception p2

    goto :goto_2

    :catch_1
    move-exception p2

    .line 22
    :goto_2
    const-string p2, "\u8bfb\u53d6\u6765\u5bbe\u8bbe\u7f6e\u5931\u8d25"

    invoke-static {p0, p2, p1}, Landroid/widget/Toast;->makeText(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;

    move-result-object p0

    invoke-virtual {p0}, Landroid/widget/Toast;->show()V

    .line 23
    return p1
.end method

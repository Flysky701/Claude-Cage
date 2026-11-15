.class public final synthetic Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog$$ExternalSyntheticLambda0;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Landroid/view/View$OnClickListener;


# instance fields
.field public final synthetic f$0:Landroid/app/Activity;

.field public final synthetic f$1:I

.field public final synthetic f$2:Landroid/widget/EditText;

.field public final synthetic f$3:Landroid/widget/EditText;

.field public final synthetic f$4:Landroid/app/AlertDialog;


# direct methods
.method public synthetic constructor <init>(Landroid/app/Activity;ILandroid/widget/EditText;Landroid/widget/EditText;Landroid/app/AlertDialog;)V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog$$ExternalSyntheticLambda0;->f$0:Landroid/app/Activity;

    iput p2, p0, Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog$$ExternalSyntheticLambda0;->f$1:I

    iput-object p3, p0, Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog$$ExternalSyntheticLambda0;->f$2:Landroid/widget/EditText;

    iput-object p4, p0, Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog$$ExternalSyntheticLambda0;->f$3:Landroid/widget/EditText;

    iput-object p5, p0, Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog$$ExternalSyntheticLambda0;->f$4:Landroid/app/AlertDialog;

    return-void
.end method


# virtual methods
.method public final onClick(Landroid/view/View;)V
    .locals 6

    .line 0
    iget-object v0, p0, Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog$$ExternalSyntheticLambda0;->f$0:Landroid/app/Activity;

    iget v1, p0, Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog$$ExternalSyntheticLambda0;->f$1:I

    iget-object v2, p0, Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog$$ExternalSyntheticLambda0;->f$2:Landroid/widget/EditText;

    iget-object v3, p0, Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog$$ExternalSyntheticLambda0;->f$3:Landroid/widget/EditText;

    iget-object v4, p0, Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog$$ExternalSyntheticLambda0;->f$4:Landroid/app/AlertDialog;

    move-object v5, p1

    invoke-static/range {v0 .. v5}, Ltop/niunaijun/blackboxa/view/main/GuestRegionDialog;->lambda$open$0(Landroid/app/Activity;ILandroid/widget/EditText;Landroid/widget/EditText;Landroid/app/AlertDialog;Landroid/view/View;)V

    return-void
.end method

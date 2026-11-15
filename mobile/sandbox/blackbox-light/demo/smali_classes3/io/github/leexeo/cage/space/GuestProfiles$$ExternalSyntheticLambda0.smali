.class public final synthetic Lio/github/leexeo/cage/space/GuestProfiles$$ExternalSyntheticLambda0;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Ljava/lang/reflect/InvocationHandler;


# instance fields
.field public final synthetic f$0:Landroid/os/Binder;


# direct methods
.method public synthetic constructor <init>(Landroid/os/Binder;)V
    .locals 0

    .line 0
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lio/github/leexeo/cage/space/GuestProfiles$$ExternalSyntheticLambda0;->f$0:Landroid/os/Binder;

    return-void
.end method


# virtual methods
.method public final invoke(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 1

    .line 0
    iget-object v0, p0, Lio/github/leexeo/cage/space/GuestProfiles$$ExternalSyntheticLambda0;->f$0:Landroid/os/Binder;

    invoke-static {v0, p1, p2, p3}, Lio/github/leexeo/cage/space/GuestProfiles;->lambda$prepare$0(Landroid/os/Binder;Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p1

    return-object p1
.end method

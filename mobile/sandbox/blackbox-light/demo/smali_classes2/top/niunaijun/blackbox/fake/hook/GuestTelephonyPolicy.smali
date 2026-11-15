.class public final Ltop/niunaijun/blackbox/fake/hook/GuestTelephonyPolicy;
.super Landroid/os/Binder;
.source "GuestTelephonyPolicy.java"


# static fields
.field private static final PHONE:Ljava/lang/String; = "com.android.internal.telephony.ITelephony"

.field private static final SUB:Ljava/lang/String; = "com.android.internal.telephony.ISub"


# instance fields
.field private final transactionName:Ljava/lang/reflect/Method;


# direct methods
.method private constructor <init>(Ljava/lang/String;)V
    .locals 3

    .line 20
    invoke-direct {p0}, Landroid/os/Binder;-><init>()V

    .line 21
    const/4 v0, 0x0

    invoke-virtual {p0, v0, p1}, Ltop/niunaijun/blackbox/fake/hook/GuestTelephonyPolicy;->attachInterface(Landroid/os/IInterface;Ljava/lang/String;)V

    .line 22
    sget v1, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v2, 0x24

    if-ne v1, v2, :cond_1

    const-string v1, "com.android.internal.telephony.ITelephony"

    invoke-virtual {v1, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-nez v1, :cond_0

    const-string v1, "com.android.internal.telephony.ISub"

    invoke-virtual {v1, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_1

    .line 23
    :cond_0
    invoke-static {p1}, Ltop/niunaijun/blackbox/fake/hook/GuestTelephonyPolicy;->findTransactionNames(Ljava/lang/String;)Ljava/lang/reflect/Method;

    move-result-object v0

    goto :goto_0

    :cond_1
    nop

    :goto_0
    iput-object v0, p0, Ltop/niunaijun/blackbox/fake/hook/GuestTelephonyPolicy;->transactionName:Ljava/lang/reflect/Method;

    .line 24
    return-void
.end method

.method public static apply(Ljava/util/Map;)V
    .locals 2
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/util/Map<",
            "Ljava/lang/String;",
            "Landroid/os/IBinder;",
            ">;)V"
        }
    .end annotation

    .line 27
    new-instance v0, Ltop/niunaijun/blackbox/fake/hook/GuestTelephonyPolicy;

    const-string v1, "com.android.internal.telephony.ITelephony"

    invoke-direct {v0, v1}, Ltop/niunaijun/blackbox/fake/hook/GuestTelephonyPolicy;-><init>(Ljava/lang/String;)V

    const-string v1, "phone"

    invoke-interface {p0, v1, v0}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 28
    new-instance v0, Ltop/niunaijun/blackbox/fake/hook/GuestTelephonyPolicy;

    const-string v1, "com.android.internal.telephony.ISub"

    invoke-direct {v0, v1}, Ltop/niunaijun/blackbox/fake/hook/GuestTelephonyPolicy;-><init>(Ljava/lang/String;)V

    const-string v1, "isub"

    invoke-interface {p0, v1, v0}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 29
    new-instance v0, Ltop/niunaijun/blackbox/fake/hook/GuestTelephonyPolicy;

    const-string v1, "com.android.internal.telephony.IPhoneSubInfo"

    invoke-direct {v0, v1}, Ltop/niunaijun/blackbox/fake/hook/GuestTelephonyPolicy;-><init>(Ljava/lang/String;)V

    const-string v1, "iphonesubinfo"

    invoke-interface {p0, v1, v0}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 30
    new-instance v0, Ltop/niunaijun/blackbox/fake/hook/GuestTelephonyPolicy;

    const-string v1, "com.android.internal.telephony.ITelephonyRegistry"

    invoke-direct {v0, v1}, Ltop/niunaijun/blackbox/fake/hook/GuestTelephonyPolicy;-><init>(Ljava/lang/String;)V

    const-string v1, "telephony.registry"

    invoke-interface {p0, v1, v0}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 31
    return-void
.end method

.method private static findTransactionNames(Ljava/lang/String;)Ljava/lang/reflect/Method;
    .locals 2

    .line 48
    :try_start_0
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v0, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string v0, "$Stub"

    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    const-class v0, Landroid/os/Binder;

    invoke-virtual {v0}, Ljava/lang/Class;->getClassLoader()Ljava/lang/ClassLoader;

    move-result-object v0

    const/4 v1, 0x0

    invoke-static {p0, v1, v0}, Ljava/lang/Class;->forName(Ljava/lang/String;ZLjava/lang/ClassLoader;)Ljava/lang/Class;

    move-result-object p0

    .line 49
    const-string v0, "getDefaultTransactionName"

    sget-object v1, Ljava/lang/Integer;->TYPE:Ljava/lang/Class;

    filled-new-array {v1}, [Ljava/lang/Class;

    move-result-object v1

    invoke-virtual {p0, v0, v1}, Ljava/lang/Class;->getMethod(Ljava/lang/String;[Ljava/lang/Class;)Ljava/lang/reflect/Method;

    move-result-object p0
    :try_end_0
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_0 .. :try_end_0} :catch_2
    .catch Ljava/lang/LinkageError; {:try_start_0 .. :try_end_0} :catch_1
    .catch Ljava/lang/SecurityException; {:try_start_0 .. :try_end_0} :catch_0

    return-object p0

    .line 50
    :catch_0
    move-exception p0

    goto :goto_0

    :catch_1
    move-exception p0

    goto :goto_0

    :catch_2
    move-exception p0

    .line 51
    :goto_0
    const/4 p0, 0x0

    return-object p0
.end method

.method private writeNoSimReply(ILandroid/os/Parcel;Landroid/os/Parcel;)Z
    .locals 4

    .line 56
    iget-object v0, p0, Ltop/niunaijun/blackbox/fake/hook/GuestTelephonyPolicy;->transactionName:Ljava/lang/reflect/Method;

    const/4 v1, 0x0

    if-nez v0, :cond_0

    return v1

    .line 59
    :cond_0
    :try_start_0
    iget-object v0, p0, Ltop/niunaijun/blackbox/fake/hook/GuestTelephonyPolicy;->transactionName:Ljava/lang/reflect/Method;

    invoke-static {p1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object p1

    filled-new-array {p1}, [Ljava/lang/Object;

    move-result-object p1

    const/4 v2, 0x0

    invoke-virtual {v0, v2, p1}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, Ljava/lang/String;
    :try_end_0
    .catch Ljava/lang/ReflectiveOperationException; {:try_start_0 .. :try_end_0} :catch_2
    .catch Ljava/lang/LinkageError; {:try_start_0 .. :try_end_0} :catch_1
    .catch Ljava/lang/SecurityException; {:try_start_0 .. :try_end_0} :catch_0

    .line 62
    nop

    .line 63
    if-nez p1, :cond_1

    return v1

    .line 64
    :cond_1
    invoke-virtual {p0}, Ltop/niunaijun/blackbox/fake/hook/GuestTelephonyPolicy;->getInterfaceDescriptor()Ljava/lang/String;

    move-result-object v0

    .line 65
    invoke-virtual {p2, v0}, Landroid/os/Parcel;->enforceInterface(Ljava/lang/String;)V

    .line 66
    const-string v2, "com.android.internal.telephony.ITelephony"

    invoke-virtual {v2, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    const/4 v3, 0x1

    if-eqz v2, :cond_5

    const-string v0, "getActivePhoneTypeForSlot"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_2

    invoke-virtual {p2}, Landroid/os/Parcel;->readInt()I

    invoke-virtual {p3}, Landroid/os/Parcel;->writeNoException()V

    invoke-virtual {p3, v1}, Landroid/os/Parcel;->writeInt(I)V

    return v3

    .line 67
    :cond_2
    const-string v0, "getSimStateForSlotIndex"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_4

    .line 68
    invoke-virtual {p2}, Landroid/os/Parcel;->readInt()I

    move-result p1

    .line 69
    invoke-virtual {p3}, Landroid/os/Parcel;->writeNoException()V

    .line 70
    if-gez p1, :cond_3

    goto :goto_0

    :cond_3
    move v1, v3

    :goto_0
    invoke-virtual {p3, v1}, Landroid/os/Parcel;->writeInt(I)V

    .line 71
    return v3

    .line 73
    :cond_4
    const-string p2, "getNetworkCountryIsoForPhone"

    invoke-virtual {p2, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_7

    .line 74
    invoke-virtual {p3}, Landroid/os/Parcel;->writeNoException()V

    .line 75
    const-string p1, ""

    invoke-virtual {p3, p1}, Landroid/os/Parcel;->writeString(Ljava/lang/String;)V

    .line 76
    return v3

    .line 78
    :cond_5
    const-string p2, "com.android.internal.telephony.ISub"

    invoke-virtual {p2, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p2

    if-eqz p2, :cond_7

    .line 80
    invoke-virtual {p1}, Ljava/lang/String;->hashCode()I

    move-result p2

    const/4 v0, -0x1

    sparse-switch p2, :sswitch_data_0

    :cond_6
    goto :goto_1

    :sswitch_0
    const-string p2, "getSubId"

    invoke-virtual {p1, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_6

    const/4 p1, 0x6

    goto :goto_2

    :sswitch_1
    const-string p2, "getDefaultSubIdAsUser"

    invoke-virtual {p1, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_6

    const/4 p1, 0x5

    goto :goto_2

    :sswitch_2
    const-string p2, "getDefaultVoiceSubIdAsUser"

    invoke-virtual {p1, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_6

    const/4 p1, 0x4

    goto :goto_2

    :sswitch_3
    const-string p2, "getDefaultSmsSubIdAsUser"

    invoke-virtual {p1, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_6

    const/4 p1, 0x3

    goto :goto_2

    :sswitch_4
    const-string p2, "getSlotIndex"

    invoke-virtual {p1, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_6

    move p1, v1

    goto :goto_2

    :sswitch_5
    const-string p2, "getPhoneId"

    invoke-virtual {p1, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_6

    move p1, v3

    goto :goto_2

    :sswitch_6
    const-string p2, "getDefaultDataSubId"

    invoke-virtual {p1, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-eqz p1, :cond_6

    const/4 p1, 0x2

    goto :goto_2

    :goto_1
    move p1, v0

    :goto_2
    packed-switch p1, :pswitch_data_0

    .line 95
    return v1

    .line 92
    :pswitch_0
    nop

    .line 93
    goto :goto_3

    .line 85
    :pswitch_1
    nop

    .line 86
    goto :goto_3

    .line 82
    :pswitch_2
    nop

    .line 83
    nop

    .line 97
    :goto_3
    invoke-virtual {p3}, Landroid/os/Parcel;->writeNoException()V

    .line 98
    invoke-virtual {p3, v0}, Landroid/os/Parcel;->writeInt(I)V

    .line 99
    return v3

    .line 101
    :cond_7
    return v1

    .line 60
    :catch_0
    move-exception p1

    goto :goto_4

    :catch_1
    move-exception p1

    goto :goto_4

    :catch_2
    move-exception p1

    .line 61
    :goto_4
    return v1

    nop

    :sswitch_data_0
    .sparse-switch
        -0x28443da -> :sswitch_6
        0x1a4edef3 -> :sswitch_5
        0x27284ebe -> :sswitch_4
        0x2ffc964a -> :sswitch_3
        0x341cb211 -> :sswitch_2
        0x5e37cf6d -> :sswitch_1
        0x7528ddc5 -> :sswitch_0
    .end sparse-switch

    :pswitch_data_0
    .packed-switch 0x0
        :pswitch_2
        :pswitch_1
        :pswitch_0
        :pswitch_0
        :pswitch_0
        :pswitch_0
        :pswitch_0
    .end packed-switch
.end method


# virtual methods
.method protected onTransact(ILandroid/os/Parcel;Landroid/os/Parcel;I)Z
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Landroid/os/RemoteException;
        }
    .end annotation

    .line 35
    const/4 v0, 0x1

    if-lt p1, v0, :cond_3

    const v1, 0xffffff

    if-le p1, v1, :cond_0

    goto :goto_0

    .line 38
    :cond_0
    and-int/2addr p4, v0

    if-nez p4, :cond_2

    if-eqz p3, :cond_2

    .line 39
    invoke-direct {p0, p1, p2, p3}, Ltop/niunaijun/blackbox/fake/hook/GuestTelephonyPolicy;->writeNoSimReply(ILandroid/os/Parcel;Landroid/os/Parcel;)Z

    move-result p1

    if-eqz p1, :cond_1

    return v0

    .line 40
    :cond_1
    new-instance p1, Ljava/lang/SecurityException;

    const-string p2, "Telephony is unavailable in this guest"

    invoke-direct {p1, p2}, Ljava/lang/SecurityException;-><init>(Ljava/lang/String;)V

    invoke-virtual {p3, p1}, Landroid/os/Parcel;->writeException(Ljava/lang/Exception;)V

    .line 42
    :cond_2
    return v0

    .line 36
    :cond_3
    :goto_0
    invoke-super {p0, p1, p2, p3, p4}, Landroid/os/Binder;->onTransact(ILandroid/os/Parcel;Landroid/os/Parcel;I)Z

    move-result p1

    return p1
.end method

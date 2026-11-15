.class Ltop/niunaijun/blackbox/network/GuestExitCheck$2;
.super Ljava/net/ProxySelector;
.source "GuestExitCheck.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingMethod;
    value = Ltop/niunaijun/blackbox/network/GuestExitCheck;->configureJavaProxy(Ljava/net/Proxy;)V
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x0
    name = null
.end annotation


# instance fields
.field final synthetic this$0:Ltop/niunaijun/blackbox/network/GuestExitCheck;

.field final synthetic val$proxy:Ljava/util/List;


# direct methods
.method constructor <init>(Ltop/niunaijun/blackbox/network/GuestExitCheck;Ljava/util/List;)V
    .locals 0
    .annotation system Ldalvik/annotation/MethodParameters;
        accessFlags = {
            0x8010,
            0x1010
        }
        names = {
            null,
            null
        }
    .end annotation

    .line 148
    iput-object p1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$2;->this$0:Ltop/niunaijun/blackbox/network/GuestExitCheck;

    iput-object p2, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$2;->val$proxy:Ljava/util/List;

    invoke-direct {p0}, Ljava/net/ProxySelector;-><init>()V

    return-void
.end method


# virtual methods
.method public connectFailed(Ljava/net/URI;Ljava/net/SocketAddress;Ljava/io/IOException;)V
    .locals 0

    .line 150
    return-void
.end method

.method public select(Ljava/net/URI;)Ljava/util/List;
    .locals 0
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/net/URI;",
            ")",
            "Ljava/util/List<",
            "Ljava/net/Proxy;",
            ">;"
        }
    .end annotation

    .line 149
    iget-object p1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$2;->val$proxy:Ljava/util/List;

    return-object p1
.end method

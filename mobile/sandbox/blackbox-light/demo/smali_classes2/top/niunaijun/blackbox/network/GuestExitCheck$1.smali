.class Ltop/niunaijun/blackbox/network/GuestExitCheck$1;
.super Ljava/net/URLStreamHandler;
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

.field final synthetic val$localProxy:Ljava/net/Proxy;

.field final synthetic val$platformHttps:Ljava/net/URL;


# direct methods
.method constructor <init>(Ltop/niunaijun/blackbox/network/GuestExitCheck;Ljava/net/Proxy;Ljava/net/URL;)V
    .locals 0
    .annotation system Ldalvik/annotation/MethodParameters;
        accessFlags = {
            0x8010,
            0x1010,
            0x1010
        }
        names = {
            null,
            null,
            null
        }
    .end annotation

    .line 133
    iput-object p1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$1;->this$0:Ltop/niunaijun/blackbox/network/GuestExitCheck;

    iput-object p2, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$1;->val$localProxy:Ljava/net/Proxy;

    iput-object p3, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$1;->val$platformHttps:Ljava/net/URL;

    invoke-direct {p0}, Ljava/net/URLStreamHandler;-><init>()V

    return-void
.end method


# virtual methods
.method protected getDefaultPort()I
    .locals 1

    .line 144
    const/16 v0, 0x1bb

    return v0
.end method

.method protected openConnection(Ljava/net/URL;)Ljava/net/URLConnection;
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 135
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$1;->val$localProxy:Ljava/net/Proxy;

    invoke-virtual {p0, p1, v0}, Ltop/niunaijun/blackbox/network/GuestExitCheck$1;->openConnection(Ljava/net/URL;Ljava/net/Proxy;)Ljava/net/URLConnection;

    move-result-object p1

    return-object p1
.end method

.method protected openConnection(Ljava/net/URL;Ljava/net/Proxy;)Ljava/net/URLConnection;
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 138
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$1;->val$localProxy:Ljava/net/Proxy;

    invoke-virtual {v0, p2}, Ljava/net/Proxy;->equals(Ljava/lang/Object;)Z

    move-result p2

    if-eqz p2, :cond_2

    iget-object p2, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$1;->this$0:Ltop/niunaijun/blackbox/network/GuestExitCheck;

    invoke-static {p2}, Ltop/niunaijun/blackbox/network/GuestExitCheck;->access$000(Ltop/niunaijun/blackbox/network/GuestExitCheck;)Z

    move-result p2

    if-eqz p2, :cond_0

    invoke-virtual {p1}, Ljava/net/URL;->getHost()Ljava/lang/String;

    move-result-object p2

    invoke-static {p2}, Lio/github/leexeo/cage/space/SpaceSites;->allows(Ljava/lang/String;)Z

    move-result p2

    if-eqz p2, :cond_2

    goto :goto_0

    :cond_0
    const-string p2, "ipv4.icanhazip.com"

    invoke-virtual {p1}, Ljava/net/URL;->getHost()Ljava/lang/String;

    move-result-object v0

    invoke-virtual {p2, v0}, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z

    move-result p2

    if-eqz p2, :cond_2

    .line 139
    :goto_0
    invoke-virtual {p1}, Ljava/net/URL;->getPort()I

    move-result p2

    const/4 v0, -0x1

    if-eq p2, v0, :cond_1

    invoke-virtual {p1}, Ljava/net/URL;->getPort()I

    move-result p2

    const/16 v0, 0x1bb

    if-ne p2, v0, :cond_2

    .line 142
    :cond_1
    new-instance p2, Ljava/net/URL;

    iget-object v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$1;->val$platformHttps:Ljava/net/URL;

    invoke-virtual {p1}, Ljava/net/URL;->toExternalForm()Ljava/lang/String;

    move-result-object p1

    invoke-direct {p2, v0, p1}, Ljava/net/URL;-><init>(Ljava/net/URL;Ljava/lang/String;)V

    iget-object p1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$1;->val$localProxy:Ljava/net/Proxy;

    invoke-virtual {p2, p1}, Ljava/net/URL;->openConnection(Ljava/net/Proxy;)Ljava/net/URLConnection;

    move-result-object p1

    return-object p1

    .line 140
    :cond_2
    new-instance p1, Ljava/net/ConnectException;

    const-string p2, "outside test HTTPS route"

    invoke-direct {p1, p2}, Ljava/net/ConnectException;-><init>(Ljava/lang/String;)V

    throw p1
.end method

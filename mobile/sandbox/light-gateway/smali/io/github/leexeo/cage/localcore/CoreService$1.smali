.class Lio/github/leexeo/cage/localcore/CoreService$1;
.super Ljava/lang/Object;
.source "CoreService.java"

# interfaces
.implements Landroid/net/DnsResolver$Callback;


# annotations
.annotation system Ldalvik/annotation/EnclosingMethod;
    value = Lio/github/leexeo/cage/localcore/CoreService;->resolveUpstream(Ljava/lang/String;)Ljava/lang/String;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x0
    name = null
.end annotation

.annotation system Ldalvik/annotation/Signature;
    value = {
        "Ljava/lang/Object;",
        "Landroid/net/DnsResolver$Callback<",
        "Ljava/util/List<",
        "Ljava/net/InetAddress;",
        ">;>;"
    }
.end annotation


# instance fields
.field final synthetic this$0:Lio/github/leexeo/cage/localcore/CoreService;


# direct methods
.method constructor <init>(Lio/github/leexeo/cage/localcore/CoreService;)V
    .locals 0

    .line 149
    iput-object p1, p0, Lio/github/leexeo/cage/localcore/CoreService$1;->this$0:Lio/github/leexeo/cage/localcore/CoreService;

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method public bridge synthetic onAnswer(Ljava/lang/Object;I)V
    .locals 0

    .line 149
    check-cast p1, Ljava/util/List;

    invoke-virtual {p0, p1, p2}, Lio/github/leexeo/cage/localcore/CoreService$1;->onAnswer(Ljava/util/List;I)V

    return-void
.end method

.method public onAnswer(Ljava/util/List;I)V
    .locals 1
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/util/List<",
            "Ljava/net/InetAddress;",
            ">;I)V"
        }
    .end annotation

    .line 151
    if-nez p2, :cond_1

    invoke-interface {p1}, Ljava/util/List;->isEmpty()Z

    move-result p2

    if-eqz p2, :cond_0

    goto :goto_0

    .line 153
    :cond_0
    iget-object p2, p0, Lio/github/leexeo/cage/localcore/CoreService$1;->this$0:Lio/github/leexeo/cage/localcore/CoreService;

    invoke-static {p2}, Lio/github/leexeo/cage/localcore/CoreService;->access$000(Lio/github/leexeo/cage/localcore/CoreService;)Ljava/util/concurrent/CompletableFuture;

    move-result-object p2

    invoke-virtual {p2, p1}, Ljava/util/concurrent/CompletableFuture;->complete(Ljava/lang/Object;)Z

    goto :goto_1

    .line 152
    :cond_1
    :goto_0
    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreService$1;->this$0:Lio/github/leexeo/cage/localcore/CoreService;

    invoke-static {p1}, Lio/github/leexeo/cage/localcore/CoreService;->access$000(Lio/github/leexeo/cage/localcore/CoreService;)Ljava/util/concurrent/CompletableFuture;

    move-result-object p1

    new-instance p2, Ljava/io/IOException;

    const-string v0, "upstream DNS failed"

    invoke-direct {p2, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    invoke-virtual {p1, p2}, Ljava/util/concurrent/CompletableFuture;->completeExceptionally(Ljava/lang/Throwable;)Z

    .line 154
    :goto_1
    return-void
.end method

.method public onError(Landroid/net/DnsResolver$DnsException;)V
    .locals 2

    .line 156
    iget-object p1, p0, Lio/github/leexeo/cage/localcore/CoreService$1;->this$0:Lio/github/leexeo/cage/localcore/CoreService;

    invoke-static {p1}, Lio/github/leexeo/cage/localcore/CoreService;->access$000(Lio/github/leexeo/cage/localcore/CoreService;)Ljava/util/concurrent/CompletableFuture;

    move-result-object p1

    new-instance v0, Ljava/io/IOException;

    const-string v1, "upstream DNS failed"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    invoke-virtual {p1, v0}, Ljava/util/concurrent/CompletableFuture;->completeExceptionally(Ljava/lang/Throwable;)Z

    .line 157
    return-void
.end method

.class final Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;
.super Ljava/lang/Object;
.source "GuestExitCheck.java"

# interfaces
.implements Ljava/io/Closeable;


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Ltop/niunaijun/blackbox/network/GuestExitCheck;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "Bridge"
.end annotation


# instance fields
.field final down:Ljava/io/InputStream;

.field final up:Ljava/io/OutputStream;


# direct methods
.method constructor <init>(Landroid/os/ParcelFileDescriptor;Landroid/os/ParcelFileDescriptor;)V
    .locals 1

    .line 252
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 253
    new-instance v0, Landroid/os/ParcelFileDescriptor$AutoCloseOutputStream;

    invoke-direct {v0, p1}, Landroid/os/ParcelFileDescriptor$AutoCloseOutputStream;-><init>(Landroid/os/ParcelFileDescriptor;)V

    iput-object v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;->up:Ljava/io/OutputStream;

    .line 254
    new-instance p1, Landroid/os/ParcelFileDescriptor$AutoCloseInputStream;

    invoke-direct {p1, p2}, Landroid/os/ParcelFileDescriptor$AutoCloseInputStream;-><init>(Landroid/os/ParcelFileDescriptor;)V

    iput-object p1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;->down:Ljava/io/InputStream;

    .line 255
    return-void
.end method


# virtual methods
.method public close()V
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 256
    :try_start_0
    iget-object v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;->up:Ljava/io/OutputStream;

    invoke-virtual {v0}, Ljava/io/OutputStream;->close()V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    iget-object v0, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;->down:Ljava/io/InputStream;

    invoke-virtual {v0}, Ljava/io/InputStream;->close()V

    return-void

    :catchall_0
    move-exception v0

    iget-object v1, p0, Ltop/niunaijun/blackbox/network/GuestExitCheck$Bridge;->down:Ljava/io/InputStream;

    invoke-virtual {v1}, Ljava/io/InputStream;->close()V

    throw v0
.end method

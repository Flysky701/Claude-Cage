.class public final Lio/github/leexeo/cage/gbox/MapPidTrace;
.super Ljava/lang/Object;

.method public static before(Ljava/lang/String;Z)V
    .locals 1
    const/4 v0, 0x0
    invoke-static {p0, p1, v0}, Lio/github/leexeo/cage/gbox/MapPidTrace;->observe(Ljava/lang/String;ZZ)V
    return-void
.end method

.method public static after(Ljava/lang/String;Z)V
    .locals 1
    const/4 v0, 0x1
    invoke-static {p0, p1, v0}, Lio/github/leexeo/cage/gbox/MapPidTrace;->observe(Ljava/lang/String;ZZ)V
    return-void
.end method

.method private static append(Ljava/lang/StringBuilder;Ljava/lang/String;Z)V
    .locals 0
    invoke-virtual {p0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {p0, p2}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;
    return-void
.end method

.method private static observe(Ljava/lang/String;ZZ)V
    .locals 4
    :try_start
    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    if-eqz p2, :before
    const-string v2, "after.mapPidSelfFile"
    goto :phase_ready
    :before
    const-string v2, "before.mapPidSelfFile"
    :phase_ready
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v2, " creator="
    invoke-static {v0, v2, p1}, Lio/github/leexeo/cage/gbox/MapPidTrace;->append(Ljava/lang/StringBuilder;Ljava/lang/String;Z)V
    const-string v2, "@HOST_PACKAGE@"
    invoke-virtual {p0, v2}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v3
    const-string v2, " hostPathMatches="
    invoke-static {v0, v2, v3}, Lio/github/leexeo/cage/gbox/MapPidTrace;->append(Ljava/lang/StringBuilder;Ljava/lang/String;Z)V
    new-instance v1, Ljava/io/File;
    invoke-direct {v1, p0}, Ljava/io/File;-><init>(Ljava/lang/String;)V
    invoke-virtual {v1}, Ljava/io/File;->exists()Z
    move-result v3
    const-string v2, " exists="
    invoke-static {v0, v2, v3}, Lio/github/leexeo/cage/gbox/MapPidTrace;->append(Ljava/lang/StringBuilder;Ljava/lang/String;Z)V
    invoke-virtual {v1}, Ljava/io/File;->canRead()Z
    move-result v3
    const-string v2, " readable="
    invoke-static {v0, v2, v3}, Lio/github/leexeo/cage/gbox/MapPidTrace;->append(Ljava/lang/StringBuilder;Ljava/lang/String;Z)V
    invoke-virtual {v1}, Ljava/io/File;->canWrite()Z
    move-result v3
    const-string v2, " writable="
    invoke-static {v0, v2, v3}, Lio/github/leexeo/cage/gbox/MapPidTrace;->append(Ljava/lang/StringBuilder;Ljava/lang/String;Z)V
    invoke-virtual {v1}, Ljava/io/File;->getParentFile()Ljava/io/File;
    move-result-object v1
    const/4 v3, 0x0
    if-eqz v1, :parent_exists_ready
    invoke-virtual {v1}, Ljava/io/File;->isDirectory()Z
    move-result v3
    :parent_exists_ready
    const-string v2, " parentDirectory="
    invoke-static {v0, v2, v3}, Lio/github/leexeo/cage/gbox/MapPidTrace;->append(Ljava/lang/StringBuilder;Ljava/lang/String;Z)V
    const/4 v3, 0x0
    if-eqz v1, :parent_writable_ready
    invoke-virtual {v1}, Ljava/io/File;->canWrite()Z
    move-result v3
    :parent_writable_ready
    const-string v2, " parentWritable="
    invoke-static {v0, v2, v3}, Lio/github/leexeo/cage/gbox/MapPidTrace;->append(Ljava/lang/StringBuilder;Ljava/lang/String;Z)V
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    const-string v2, "CageNativeTrace"
    invoke-static {v2, v0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end
    .catch Ljava/lang/Throwable; {:try_start .. :try_end} :unavailable
    return-void
    :unavailable
    move-exception v0
    return-void
.end method

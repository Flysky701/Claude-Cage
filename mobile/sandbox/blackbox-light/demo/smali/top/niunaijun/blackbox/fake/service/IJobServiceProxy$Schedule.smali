.class public Ltop/niunaijun/blackbox/fake/service/IJobServiceProxy$Schedule;
.super Ltop/niunaijun/blackbox/fake/hook/MethodHook;
.source "r8-map-id-b030d4079bf46d1be0bde84446c3eaf9c7aec13dc1c4fe379a76cc83ba4f4ecf"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Ltop/niunaijun/blackbox/fake/service/IJobServiceProxy;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x9
    name = "Schedule"
.end annotation

.annotation runtime Ltop/niunaijun/blackbox/fake/hook/ProxyMethod;
    value = "schedule"
.end annotation


# direct methods
.method public constructor <init>()V
    .locals 0

    .line 1
    invoke-direct {p0}, Ltop/niunaijun/blackbox/fake/hook/MethodHook;-><init>()V

    .line 2
    .line 3
    .line 4
    return-void
.end method

.method private createMinimalJobInfo(Ljava/lang/String;)Landroid/app/job/JobInfo;
    .locals 4

    .line 1
    const-string v0, "JobServiceStub"

    .line 2
    .line 3
    const-string v1, "Schedule: Creating minimal JobInfo for work ID: "

    .line 4
    .line 5
    const/4 v2, 0x0

    .line 6
    :try_start_0
    new-instance v3, Ljava/lang/StringBuilder;

    .line 7
    .line 8
    invoke-direct {v3, v1}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 9
    .line 10
    .line 11
    invoke-virtual {v3, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 12
    .line 13
    .line 14
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 15
    .line 16
    .line 17
    move-result-object p1

    .line 18
    invoke-static {v0, p1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 19
    .line 20
    .line 21
    return-object v2

    .line 22
    :catch_0
    move-exception p1

    .line 23
    const-string v1, "Schedule: Failed to create minimal JobInfo"

    .line 24
    .line 25
    invoke-static {v0, v1, p1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 26
    .line 27
    .line 28
    return-object v2
.end method

.method private handleNonJobInfoSchedule(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 5

    .line 1
    const-string v0, "JobServiceStub"

    .line 2
    .line 3
    const-string v1, "Schedule: Handling WorkManager string ID: "

    .line 4
    .line 5
    const/4 v2, 0x0

    .line 6
    :try_start_0
    aget-object v3, p3, v2

    .line 7
    .line 8
    instance-of v4, v3, Ljava/lang/String;

    .line 9
    .line 10
    if-eqz v4, :cond_0

    .line 11
    .line 12
    check-cast v3, Ljava/lang/String;

    .line 13
    .line 14
    invoke-virtual {v1, v3}, Ljava/lang/String;->concat(Ljava/lang/String;)Ljava/lang/String;

    .line 15
    .line 16
    .line 17
    move-result-object v1

    .line 18
    invoke-static {v0, v1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 19
    .line 20
    .line 21
    invoke-direct {p0, v3}, Ltop/niunaijun/blackbox/fake/service/IJobServiceProxy$Schedule;->createMinimalJobInfo(Ljava/lang/String;)Landroid/app/job/JobInfo;

    .line 22
    .line 23
    .line 24
    move-result-object v1

    .line 25
    if-eqz v1, :cond_0

    .line 26
    .line 27
    aput-object v1, p3, v2

    .line 28
    .line 29
    invoke-virtual {p2, p1, p3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 30
    .line 31
    .line 32
    move-result-object p1

    .line 33
    return-object p1

    .line 34
    :catch_0
    move-exception p1

    .line 35
    goto :goto_0

    .line 36
    :cond_0
    invoke-virtual {p2, p1, p3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 37
    .line 38
    .line 39
    move-result-object p1
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 40
    return-object p1

    .line 41
    :goto_0
    const-string p2, "Schedule: Failed to handle non-JobInfo schedule"

    .line 42
    .line 43
    invoke-static {v0, p2, p1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 44
    .line 45
    .line 46
    invoke-static {v2}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 47
    .line 48
    .line 49
    move-result-object p1

    .line 50
    return-object p1
.end method

.method private isUIDValidationError(Ljava/lang/Exception;)Z
    .locals 4

    .line 1
    invoke-virtual {p1}, Ljava/lang/Throwable;->getCause()Ljava/lang/Throwable;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    instance-of v0, v0, Ljava/lang/IllegalArgumentException;

    .line 6
    .line 7
    const/4 v1, 0x1

    .line 8
    const-string v2, "cannot schedule job"

    .line 9
    .line 10
    const/4 v3, 0x0

    .line 11
    if-eqz v0, :cond_1

    .line 12
    .line 13
    invoke-virtual {p1}, Ljava/lang/Throwable;->getCause()Ljava/lang/Throwable;

    .line 14
    .line 15
    .line 16
    move-result-object p1

    .line 17
    invoke-virtual {p1}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 18
    .line 19
    .line 20
    move-result-object p1

    .line 21
    if-eqz p1, :cond_0

    .line 22
    .line 23
    invoke-virtual {p1, v2}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 24
    .line 25
    .line 26
    move-result p1

    .line 27
    if-eqz p1, :cond_0

    .line 28
    .line 29
    return v1

    .line 30
    :cond_0
    return v3

    .line 31
    :cond_1
    invoke-virtual {p1}, Ljava/lang/Throwable;->getCause()Ljava/lang/Throwable;

    .line 32
    .line 33
    .line 34
    move-result-object v0

    .line 35
    instance-of v0, v0, Landroid/os/RemoteException;

    .line 36
    .line 37
    if-eqz v0, :cond_2

    .line 38
    .line 39
    invoke-virtual {p1}, Ljava/lang/Throwable;->getCause()Ljava/lang/Throwable;

    .line 40
    .line 41
    .line 42
    move-result-object p1

    .line 43
    invoke-virtual {p1}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 44
    .line 45
    .line 46
    move-result-object p1

    .line 47
    if-eqz p1, :cond_2

    .line 48
    .line 49
    invoke-virtual {p1, v2}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 50
    .line 51
    .line 52
    move-result p1

    .line 53
    if-eqz p1, :cond_2

    .line 54
    .line 55
    return v1

    .line 56
    :cond_2
    return v3
.end method

.method private scheduleWithUIDSpoofing(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;Landroid/app/job/JobInfo;)Ljava/lang/Object;
    .locals 5

    .line 1
    const/4 v0, 0x0

    .line 2
    invoke-static {v0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 3
    .line 4
    .line 5
    move-result-object v0

    .line 6
    const-string v1, "job_schedule"

    .line 7
    .line 8
    const-string v2, "JobServiceStub"

    .line 9
    .line 10
    const-string v3, "Schedule: Attempting UID spoofing for package: "

    .line 11
    .line 12
    :try_start_0
    invoke-virtual {p4}, Landroid/app/job/JobInfo;->getService()Landroid/content/ComponentName;

    .line 13
    .line 14
    .line 15
    move-result-object p4

    .line 16
    invoke-virtual {p4}, Landroid/content/ComponentName;->getPackageName()Ljava/lang/String;

    .line 17
    .line 18
    .line 19
    move-result-object p4

    .line 20
    new-instance v4, Ljava/lang/StringBuilder;

    .line 21
    .line 22
    invoke-direct {v4, v3}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 23
    .line 24
    .line 25
    invoke-virtual {v4, p4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 26
    .line 27
    .line 28
    invoke-virtual {v4}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 29
    .line 30
    .line 31
    move-result-object v3

    .line 32
    invoke-static {v2, v3}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 33
    .line 34
    .line 35
    invoke-static {v1, p4}, Ltop/niunaijun/blackbox/utils/UIDSpoofingHelper;->logUIDInfo(Ljava/lang/String;Ljava/lang/String;)V

    .line 36
    .line 37
    .line 38
    invoke-static {v1, p4}, Ltop/niunaijun/blackbox/utils/UIDSpoofingHelper;->needsUIDSpoofing(Ljava/lang/String;Ljava/lang/String;)Z

    .line 39
    .line 40
    .line 41
    move-result p4

    .line 42
    if-eqz p4, :cond_0

    .line 43
    .line 44
    const-string p1, "Schedule: UID spoofing needed, attempting to bypass validation"

    .line 45
    .line 46
    invoke-static {v2, p1}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 47
    .line 48
    .line 49
    const-string p1, "Schedule: UID spoofing not fully implemented, returning RESULT_FAILURE"

    .line 50
    .line 51
    invoke-static {v2, p1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 52
    .line 53
    .line 54
    return-object v0

    .line 55
    :catch_0
    move-exception p1

    .line 56
    goto :goto_0

    .line 57
    :cond_0
    const-string p4, "Schedule: No UID spoofing needed, proceeding normally"

    .line 58
    .line 59
    invoke-static {v2, p4}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 60
    .line 61
    .line 62
    invoke-virtual {p2, p1, p3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 63
    .line 64
    .line 65
    move-result-object p1
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 66
    return-object p1

    .line 67
    :goto_0
    const-string p2, "Schedule: UID spoofing failed"

    .line 68
    .line 69
    invoke-static {v2, p2, p1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 70
    .line 71
    .line 72
    return-object v0
.end method


# virtual methods
.method public hook(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;
    .locals 7

    .line 1
    const/4 v0, 0x0

    .line 2
    invoke-static {v0}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    .line 3
    .line 4
    .line 5
    move-result-object v1

    const-class v5, Landroid/app/job/JobInfo;

    invoke-static {p2, v5}, Lio/github/leexeo/cage/space/GuestJobArguments;->index(Ljava/lang/reflect/Method;Ljava/lang/Class;)I

    move-result v0

    .line 6
    const-string v2, "Schedule: Processing JobInfo for package: "

    .line 7
    .line 8
    const-string v3, "Schedule: args[0] is not JobInfo: "

    .line 9
    .line 10
    const-string v4, "JobServiceStub"

    .line 11
    .line 12
    if-eqz p3, :cond_4

    .line 13
    .line 14
    :try_start_0
    array-length v5, p3

    .line 15
    if-nez v5, :cond_0

    .line 16
    .line 17
    goto :goto_0

    .line 18
    :cond_0
    aget-object v5, p3, v0

    .line 19
    .line 20
    if-nez v5, :cond_1

    .line 21
    .line 22
    const-string v0, "Schedule: args[0] is null, returning RESULT_FAILURE"

    .line 23
    .line 24
    invoke-static {v4, v0}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 25
    .line 26
    .line 27
    return-object v1

    .line 28
    :catch_0
    move-exception v0

    .line 29
    goto :goto_1

    .line 30
    :cond_1
    instance-of v6, v5, Landroid/app/job/JobInfo;

    .line 31
    .line 32
    if-nez v6, :cond_2

    .line 33
    .line 34
    invoke-virtual {v5}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 35
    .line 36
    .line 37
    move-result-object v0

    .line 38
    invoke-virtual {v0}, Ljava/lang/Class;->getSimpleName()Ljava/lang/String;

    .line 39
    .line 40
    .line 41
    move-result-object v0

    .line 42
    invoke-virtual {v3, v0}, Ljava/lang/String;->concat(Ljava/lang/String;)Ljava/lang/String;

    .line 43
    .line 44
    .line 45
    move-result-object v0

    .line 46
    invoke-static {v4, v0}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 47
    .line 48
    .line 49
    invoke-direct {p0, p1, p2, p3}, Ltop/niunaijun/blackbox/fake/service/IJobServiceProxy$Schedule;->handleNonJobInfoSchedule(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 50
    .line 51
    .line 52
    move-result-object p1

    .line 53
    return-object p1

    .line 54
    :cond_2
    check-cast v5, Landroid/app/job/JobInfo;

    .line 55
    .line 56
    new-instance v3, Ljava/lang/StringBuilder;

    .line 57
    .line 58
    invoke-direct {v3, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 59
    .line 60
    .line 61
    invoke-virtual {v5}, Landroid/app/job/JobInfo;->getService()Landroid/content/ComponentName;

    .line 62
    .line 63
    .line 64
    move-result-object v2

    .line 65
    invoke-virtual {v2}, Landroid/content/ComponentName;->getPackageName()Ljava/lang/String;

    .line 66
    .line 67
    .line 68
    move-result-object v2

    .line 69
    invoke-virtual {v3, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 70
    .line 71
    .line 72
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 73
    .line 74
    .line 75
    move-result-object v2

    .line 76
    invoke-static {v4, v2}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 77
    .line 78
    .line 79
    :try_start_1
    invoke-static {}, Ltop/niunaijun/blackbox/BlackBoxCore;->getBJobManager()Ltop/niunaijun/blackbox/fake/frameworks/BJobManager;

    .line 80
    .line 81
    .line 82
    move-result-object v2

    .line 83
    invoke-virtual {v2, v5}, Ltop/niunaijun/blackbox/fake/frameworks/BJobManager;->schedule(Landroid/app/job/JobInfo;)Landroid/app/job/JobInfo;

    .line 84
    .line 85
    .line 86
    move-result-object v2

    .line 87
    if-eqz v2, :cond_3

    .line 88
    .line 89
    aput-object v2, p3, v0

    .line 90
    .line 91
    const-string v0, "Schedule: Successfully created proxy JobInfo"

    .line 92
    .line 93
    invoke-static {v4, v0}, Ltop/niunaijun/blackbox/utils/Slog;->d(Ljava/lang/String;Ljava/lang/String;)I

    .line 94
    .line 95
    .line 96
    invoke-virtual {p2, p1, p3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 97
    .line 98
    .line 99
    move-result-object p1
    :try_end_1
    .catch Ljava/lang/Exception; {:try_start_1 .. :try_end_1} :catch_1

    .line 100
    return-object p1

    .line 101
    :catch_1
    move-exception v0

    .line 102
    :try_start_2
    const-string v2, "Schedule: BlackBox job manager failed, trying system fallback"

    .line 103
    .line 104
    invoke-static {v4, v2, v0}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 105
    .line 106
    .line 107
    :cond_3
    invoke-direct {p0, p1, p2, p3, v5}, Ltop/niunaijun/blackbox/fake/service/IJobServiceProxy$Schedule;->scheduleWithUIDSpoofing(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;Landroid/app/job/JobInfo;)Ljava/lang/Object;

    .line 108
    .line 109
    .line 110
    move-result-object p1

    .line 111
    return-object p1

    .line 112
    :cond_4
    :goto_0
    const-string v0, "Schedule: No arguments provided, returning RESULT_FAILURE"

    .line 113
    .line 114
    invoke-static {v4, v0}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_2
    .catch Ljava/lang/Exception; {:try_start_2 .. :try_end_2} :catch_0

    .line 115
    .line 116
    .line 117
    return-object v1

    .line 118
    :goto_1
    const-string v2, "Schedule: Error processing job"

    .line 119
    .line 120
    invoke-static {v4, v2, v0}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 121
    .line 122
    .line 123
    invoke-direct {p0, v0}, Ltop/niunaijun/blackbox/fake/service/IJobServiceProxy$Schedule;->isUIDValidationError(Ljava/lang/Exception;)Z

    .line 124
    .line 125
    .line 126
    move-result v2

    .line 127
    if-eqz v2, :cond_5

    .line 128
    .line 129
    new-instance p1, Ljava/lang/StringBuilder;

    .line 130
    .line 131
    const-string p2, "UID validation failed for job scheduling, returning RESULT_FAILURE: "

    .line 132
    .line 133
    invoke-direct {p1, p2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 134
    .line 135
    .line 136
    invoke-virtual {v0}, Ljava/lang/Throwable;->getCause()Ljava/lang/Throwable;

    .line 137
    .line 138
    .line 139
    move-result-object p2

    .line 140
    invoke-virtual {p2}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 141
    .line 142
    .line 143
    move-result-object p2

    .line 144
    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 145
    .line 146
    .line 147
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 148
    .line 149
    .line 150
    move-result-object p1

    .line 151
    invoke-static {v4, p1}, Ltop/niunaijun/blackbox/utils/Slog;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 152
    .line 153
    .line 154
    return-object v1

    .line 155
    :cond_5
    :try_start_3
    invoke-virtual {p2, p1, p3}, Ljava/lang/reflect/Method;->invoke(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;

    .line 156
    .line 157
    .line 158
    move-result-object p1
    :try_end_3
    .catch Ljava/lang/Exception; {:try_start_3 .. :try_end_3} :catch_2

    .line 159
    return-object p1

    .line 160
    :catch_2
    move-exception p1

    .line 161
    const-string p2, "Schedule: Fallback also failed"

    .line 162
    .line 163
    invoke-static {v4, p2, p1}, Ltop/niunaijun/blackbox/utils/Slog;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 164
    .line 165
    .line 166
    return-object v1
.end method

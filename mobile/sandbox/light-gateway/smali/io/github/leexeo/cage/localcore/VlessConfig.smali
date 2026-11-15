.class final Lio/github/leexeo/cage/localcore/VlessConfig;
.super Ljava/lang/Object;
.source "VlessConfig.java"


# static fields
.field private static final FIELD:Ljava/util/regex/Pattern;

.field private static final SECTION:Ljava/util/regex/Pattern;


# direct methods
.method static constructor <clinit>()V
    .locals 1

    .line 9
    const-string v0, "^([A-Za-z0-9_-]+)\\s*:(.*)$"

    invoke-static {v0}, Ljava/util/regex/Pattern;->compile(Ljava/lang/String;)Ljava/util/regex/Pattern;

    move-result-object v0

    sput-object v0, Lio/github/leexeo/cage/localcore/VlessConfig;->SECTION:Ljava/util/regex/Pattern;

    .line 10
    const-string v0, "^(name|type)\\s*:\\s*(.*)$"

    invoke-static {v0}, Ljava/util/regex/Pattern;->compile(Ljava/lang/String;)Ljava/util/regex/Pattern;

    move-result-object v0

    sput-object v0, Lio/github/leexeo/cage/localcore/VlessConfig;->FIELD:Ljava/util/regex/Pattern;

    return-void
.end method

.method constructor <init>()V
    .locals 0

    .line 8
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method private static indent(Ljava/lang/String;)I
    .locals 3

    .line 93
    const/4 v0, 0x0

    :goto_0
    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v1

    if-ge v0, v1, :cond_0

    invoke-virtual {p0, v0}, Ljava/lang/String;->charAt(I)C

    move-result v1

    const/16 v2, 0x20

    if-ne v1, v2, :cond_0

    add-int/lit8 v0, v0, 0x1

    goto :goto_0

    :cond_0
    return v0
.end method

.method static render(Ljava/lang/String;ILjava/lang/String;)Ljava/lang/String;
    .locals 17
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 13
    move-object/from16 v0, p0

    move/from16 v1, p1

    move-object/from16 v2, p2

    if-eqz v0, :cond_1c

    invoke-virtual {v0}, Ljava/lang/String;->length()I

    move-result v3

    const/high16 v4, 0x40000

    if-gt v3, v4, :cond_1c

    const/4 v3, 0x1

    if-lt v1, v3, :cond_1c

    const v4, 0xffff

    if-gt v1, v4, :cond_1c

    .line 14
    const-string v4, "[0-9a-f-]{36}"

    invoke-virtual {v2, v4}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v4

    if-eqz v4, :cond_1c

    .line 15
    new-instance v4, Ljava/util/HashMap;

    invoke-direct {v4}, Ljava/util/HashMap;-><init>()V

    .line 16
    nop

    .line 17
    const-string v5, "\r\n"

    const-string v6, "\n"

    invoke-virtual {v0, v5, v6}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object v0

    const-string v5, "\ufeff"

    const-string v7, ""

    invoke-virtual {v0, v5, v7}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object v0

    const/4 v5, -0x1

    invoke-virtual {v0, v6, v5}, Ljava/lang/String;->split(Ljava/lang/String;I)[Ljava/lang/String;

    move-result-object v0

    array-length v5, v0

    const/4 v7, 0x0

    move v8, v7

    const/4 v9, 0x0

    :goto_0
    const-string v10, "proxy-groups"

    const-string v11, "proxies"

    const/4 v12, 0x2

    if-ge v8, v5, :cond_a

    aget-object v13, v0, v8

    .line 18
    const/16 v14, 0x9

    invoke-virtual {v13, v14}, Ljava/lang/String;->indexOf(I)I

    move-result v14

    const-string v15, "unsupported YAML"

    if-gez v14, :cond_9

    invoke-virtual {v13, v7}, Ljava/lang/String;->indexOf(I)I

    move-result v14

    if-gez v14, :cond_9

    .line 19
    invoke-virtual {v13}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v14

    .line 20
    invoke-virtual {v14}, Ljava/lang/String;->isEmpty()Z

    move-result v16

    if-nez v16, :cond_8

    const-string v6, "#"

    invoke-virtual {v14, v6}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v6

    if-nez v6, :cond_8

    const-string v6, "---"

    invoke-virtual {v14, v6}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_0

    goto/16 :goto_2

    .line 21
    :cond_0
    sget-object v6, Lio/github/leexeo/cage/localcore/VlessConfig;->SECTION:Ljava/util/regex/Pattern;

    invoke-virtual {v6, v13}, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;

    move-result-object v6

    .line 22
    invoke-virtual {v6}, Ljava/util/regex/Matcher;->matches()Z

    move-result v16

    if-eqz v16, :cond_3

    .line 23
    invoke-virtual {v6, v3}, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;

    move-result-object v9

    .line 24
    invoke-virtual {v9, v11}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v11

    if-nez v11, :cond_1

    invoke-virtual {v9, v10}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v10

    if-eqz v10, :cond_8

    .line 25
    :cond_1
    invoke-interface {v4, v9}, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z

    move-result v10

    if-nez v10, :cond_2

    invoke-virtual {v6, v12}, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;

    move-result-object v6

    invoke-virtual {v6}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v6

    invoke-virtual {v6}, Ljava/lang/String;->isEmpty()Z

    move-result v6

    if-eqz v6, :cond_2

    .line 27
    new-instance v6, Ljava/util/ArrayList;

    new-instance v10, Ljava/lang/StringBuilder;

    invoke-direct {v10}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v10, v9}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v10

    const-string v11, ":"

    invoke-virtual {v10, v11}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v10

    invoke-virtual {v10}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v10

    invoke-static {v10}, Ljava/util/Collections;->singletonList(Ljava/lang/Object;)Ljava/util/List;

    move-result-object v10

    invoke-direct {v6, v10}, Ljava/util/ArrayList;-><init>(Ljava/util/Collection;)V

    invoke-interface {v4, v9, v6}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    goto :goto_2

    .line 26
    :cond_2
    new-instance v0, Ljava/io/IOException;

    const-string v1, "block YAML required"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 31
    :cond_3
    invoke-virtual {v13, v7}, Ljava/lang/String;->charAt(I)C

    move-result v6

    const/16 v10, 0x20

    if-eq v6, v10, :cond_5

    invoke-virtual {v13, v7}, Ljava/lang/String;->charAt(I)C

    move-result v6

    const/16 v10, 0x2d

    if-ne v6, v10, :cond_4

    goto :goto_1

    :cond_4
    new-instance v0, Ljava/io/IOException;

    invoke-direct {v0, v15}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 32
    :cond_5
    :goto_1
    if-eqz v9, :cond_8

    invoke-interface {v4, v9}, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_8

    .line 34
    const-string v6, "<<:"

    invoke-virtual {v14, v6}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v6

    if-nez v6, :cond_7

    const-string v6, "!"

    invoke-virtual {v14, v6}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v6

    if-nez v6, :cond_7

    .line 35
    const-string v6, ".*(?:^|[ :\\[,])[*&!][A-Za-z0-9_-]+.*"

    invoke-virtual {v14, v6}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v6

    if-nez v6, :cond_7

    .line 37
    const-string v6, "(?i)(?:-\\s*)?dialer-proxy\\s*:.*"

    invoke-virtual {v14, v6}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v6

    if-nez v6, :cond_6

    .line 38
    const-string v6, "(?i)skip-cert-verify\\s*:\\s*[\'\"]?true[\'\"]?(?:\\s*#.*)?"

    invoke-virtual {v14, v6}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v6

    if-nez v6, :cond_6

    .line 40
    invoke-interface {v4, v9}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v6

    check-cast v6, Ljava/util/List;

    invoke-interface {v6, v13}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    goto :goto_2

    .line 39
    :cond_6
    new-instance v0, Ljava/io/IOException;

    const-string v1, "unsafe proxy option"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 36
    :cond_7
    new-instance v0, Ljava/io/IOException;

    const-string v1, "YAML aliases not accepted"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 17
    :cond_8
    :goto_2
    add-int/lit8 v8, v8, 0x1

    goto/16 :goto_0

    .line 18
    :cond_9
    new-instance v0, Ljava/io/IOException;

    invoke-direct {v0, v15}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 43
    :cond_a
    invoke-interface {v4, v11}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Ljava/util/List;

    .line 44
    const-string v5, "missing proxy"

    if-eqz v0, :cond_1b

    .line 45
    nop

    .line 46
    invoke-interface {v0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v6

    const v8, 0x7fffffff

    move v9, v8

    :cond_b
    :goto_3
    invoke-interface {v6}, Ljava/util/Iterator;->hasNext()Z

    move-result v11

    const-string v13, "- "

    if-eqz v11, :cond_c

    invoke-interface {v6}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v11

    check-cast v11, Ljava/lang/String;

    invoke-virtual {v11}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v14

    invoke-virtual {v14, v13}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v13

    if-eqz v13, :cond_b

    invoke-static {v11}, Lio/github/leexeo/cage/localcore/VlessConfig;->indent(Ljava/lang/String;)I

    move-result v11

    invoke-static {v9, v11}, Ljava/lang/Math;->min(II)I

    move-result v9

    goto :goto_3

    .line 47
    :cond_c
    if-eq v9, v8, :cond_1a

    .line 48
    nop

    .line 49
    nop

    .line 50
    invoke-interface {v0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v5

    const/4 v6, 0x0

    const/4 v8, 0x0

    :goto_4
    invoke-interface {v5}, Ljava/util/Iterator;->hasNext()Z

    move-result v11

    if-eqz v11, :cond_14

    invoke-interface {v5}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v11

    check-cast v11, Ljava/lang/String;

    .line 51
    nop

    .line 52
    invoke-static {v11}, Lio/github/leexeo/cage/localcore/VlessConfig;->indent(Ljava/lang/String;)I

    move-result v14

    if-ne v14, v9, :cond_d

    invoke-virtual {v11}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v14

    invoke-virtual {v14, v13}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v14

    if-eqz v14, :cond_d

    .line 53
    add-int/lit8 v7, v7, 0x1

    invoke-virtual {v11}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v11

    invoke-virtual {v11, v12}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v11

    invoke-virtual {v11}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v11

    goto :goto_5

    .line 54
    :cond_d
    invoke-static {v11}, Lio/github/leexeo/cage/localcore/VlessConfig;->indent(Ljava/lang/String;)I

    move-result v14

    add-int/lit8 v15, v9, 0x2

    if-ne v14, v15, :cond_e

    invoke-virtual {v11}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v11

    goto :goto_5

    :cond_e
    const/4 v11, 0x0

    .line 55
    :goto_5
    if-nez v11, :cond_f

    goto :goto_4

    .line 56
    :cond_f
    sget-object v14, Lio/github/leexeo/cage/localcore/VlessConfig;->FIELD:Ljava/util/regex/Pattern;

    invoke-virtual {v14, v11}, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;

    move-result-object v11

    .line 57
    invoke-virtual {v11}, Ljava/util/regex/Matcher;->matches()Z

    move-result v14

    if-nez v14, :cond_10

    goto :goto_4

    .line 58
    :cond_10
    invoke-virtual {v11, v12}, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;

    move-result-object v14

    invoke-static {v14}, Lio/github/leexeo/cage/localcore/VlessConfig;->scalar(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v14

    .line 59
    invoke-virtual {v11, v3}, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;

    move-result-object v11

    const-string v15, "name"

    invoke-virtual {v11, v15}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v11

    if-eqz v11, :cond_12

    .line 60
    if-nez v8, :cond_11

    .line 61
    move-object v8, v14

    goto :goto_6

    .line 60
    :cond_11
    new-instance v0, Ljava/io/IOException;

    const-string v1, "duplicate proxy name"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 63
    :cond_12
    if-nez v6, :cond_13

    .line 64
    move-object v6, v14

    .line 66
    :goto_6
    goto :goto_4

    .line 63
    :cond_13
    new-instance v0, Ljava/io/IOException;

    const-string v1, "duplicate proxy type"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 67
    :cond_14
    if-ne v7, v3, :cond_19

    const-string v3, "vless"

    invoke-virtual {v3, v6}, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_19

    if-eqz v8, :cond_19

    invoke-virtual {v8}, Ljava/lang/String;->length()I

    move-result v3

    const/16 v5, 0x80

    if-gt v3, v5, :cond_19

    .line 68
    const-string v3, "[\\p{L}\\p{N}_. +()\\[\\]-]+"

    invoke-virtual {v8, v3}, Ljava/lang/String;->matches(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_19

    .line 69
    const-string v3, "DIRECT"

    invoke-virtual {v8, v3}, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z

    move-result v3

    if-nez v3, :cond_19

    const-string v3, "REJECT"

    invoke-virtual {v8, v3}, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z

    move-result v3

    if-nez v3, :cond_19

    .line 71
    invoke-interface {v4, v10}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Ljava/util/List;

    .line 72
    if-eqz v3, :cond_16

    .line 73
    invoke-interface {v3}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v4

    :goto_7
    invoke-interface {v4}, Ljava/util/Iterator;->hasNext()Z

    move-result v5

    if-eqz v5, :cond_16

    invoke-interface {v4}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v5

    check-cast v5, Ljava/lang/String;

    .line 74
    const-string v6, "(?i)(?:^|[^A-Za-z0-9_-])(DIRECT|COMPATIBLE)(?:$|[^A-Za-z0-9_-])"

    invoke-static {v6}, Ljava/util/regex/Pattern;->compile(Ljava/lang/String;)Ljava/util/regex/Pattern;

    move-result-object v6

    invoke-virtual {v6, v5}, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;

    move-result-object v5

    invoke-virtual {v5}, Ljava/util/regex/Matcher;->find()Z

    move-result v5

    if-nez v5, :cond_15

    goto :goto_7

    .line 75
    :cond_15
    new-instance v0, Ljava/io/IOException;

    const-string v1, "group direct option denied"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 77
    :cond_16
    new-instance v4, Ljava/lang/StringBuilder;

    const-string v5, "mode: rule\nallow-lan: false\nbind-address: 127.0.0.1\n"

    invoke-direct {v4, v5}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 78
    const-string v5, "port: 0\nmixed-port: 0\nsocks-port: "

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v1

    .line 79
    const-string v4, "\nredir-port: 0\ntproxy-port: 0\nauthentication: [\'cage:"

    invoke-virtual {v1, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    .line 80
    const-string v2, "\']\nskip-auth-prefixes: []\nlisteners: []\nexternal-controller: \'\'\n"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    .line 81
    const-string v2, "external-controller-unix: \'\'\nexternal-controller-pipe: \'\'\n"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    .line 82
    const-string v2, "tun: {enable: false}\ndns: {enable: false}\nipv6: true\nlog-level: silent\n"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    .line 83
    const-string v2, "geo-auto-update: false\nprofile: {store-selected: false, store-fake-ip: false}\nfind-process-mode: off\n"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    .line 84
    invoke-interface {v0}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v0

    :goto_8
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z

    move-result v2

    const/16 v4, 0xa

    if-eqz v2, :cond_17

    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Ljava/lang/String;

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2, v4}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    goto :goto_8

    .line 85
    :cond_17
    if-eqz v3, :cond_18

    invoke-interface {v3}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v0

    :goto_9
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z

    move-result v2

    if-eqz v2, :cond_18

    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Ljava/lang/String;

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2, v4}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    goto :goto_9

    .line 88
    :cond_18
    const-string v0, "rules:\n  - \"MATCH,"

    invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, v8}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v2, "\"\n  - MATCH,REJECT\n"

    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 89
    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    return-object v0

    .line 70
    :cond_19
    new-instance v0, Ljava/io/IOException;

    const-string v1, "one named VLESS proxy required"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 47
    :cond_1a
    new-instance v0, Ljava/io/IOException;

    invoke-direct {v0, v5}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 44
    :cond_1b
    new-instance v0, Ljava/io/IOException;

    invoke-direct {v0, v5}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0

    .line 14
    :cond_1c
    new-instance v0, Ljava/io/IOException;

    const-string v1, "invalid private config"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0
.end method

.method private static scalar(Ljava/lang/String;)Ljava/lang/String;
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 97
    invoke-virtual {p0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object p0

    .line 98
    const-string v0, "\'"

    invoke-virtual {p0, v0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v1

    const/4 v2, 0x1

    if-eqz v1, :cond_0

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v1

    if-eqz v1, :cond_0

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v1

    sub-int/2addr v1, v2

    invoke-virtual {p0, v2, v1}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    const-string v1, "\'\'"

    invoke-virtual {p0, v1, v0}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object p0

    return-object p0

    .line 99
    :cond_0
    const-string v0, "\""

    invoke-virtual {p0, v0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v1

    if-eqz v1, :cond_2

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_2

    .line 100
    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v0

    sub-int/2addr v0, v2

    invoke-virtual {p0, v2, v0}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    .line 101
    const/16 v0, 0x5c

    invoke-virtual {p0, v0}, Ljava/lang/String;->indexOf(I)I

    move-result v0

    if-gez v0, :cond_1

    const/16 v0, 0x22

    invoke-virtual {p0, v0}, Ljava/lang/String;->indexOf(I)I

    move-result v0

    if-gez v0, :cond_1

    .line 102
    return-object p0

    .line 101
    :cond_1
    new-instance p0, Ljava/io/IOException;

    const-string v0, "unsupported proxy label"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 104
    :cond_2
    const-string v0, " #"

    invoke-virtual {p0, v0}, Ljava/lang/String;->indexOf(Ljava/lang/String;)I

    move-result v0

    .line 105
    if-gez v0, :cond_3

    goto :goto_0

    :cond_3
    const/4 v1, 0x0

    invoke-virtual {p0, v1, v0}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object p0

    :goto_0
    return-object p0
.end method

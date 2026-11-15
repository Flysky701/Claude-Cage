// Generated from native-hook-inventory-api31-32.json; reviewed exact JNI signatures.
static jint adapt_camera_setup(JNIEnv* env, jobject receiver, jobject p0, jint p1, jstring p2);
static jint adapt_camera_setup_hal(JNIEnv* env, jobject receiver, jobject p0, jint p1, jint p2, jstring p3);
static jint adapt_record_setup_legacy(JNIEnv* env, jobject receiver, jobject p0, jobject p1, jint p2, jint p3, jint p4, jint p5, jint p6, jintArray p7, jstring p8);
static jint adapt_record_setup_string(JNIEnv* env, jobject receiver, jobject p0, jobject p1, jintArray p2, jint p3, jint p4, jint p5, jint p6, jintArray p7, jstring p8, jlong p9);
static jint adapt_record_setup_parcel(JNIEnv* env, jobject receiver, jobject p0, jobject p1, jintArray p2, jint p3, jint p4, jint p5, jint p6, jintArray p7, jobject p8, jlong p9, jint p10);
static jint adapt_record_start(JNIEnv* env, jobject receiver, jint p0, jint p1);
static void adapt_record_stop(JNIEnv* env, jobject receiver);
static void adapt_record_release(JNIEnv* env, jobject receiver);
static jint adapt_recorder_setup_int(JNIEnv* env, jobject receiver, jobject p0, jstring p1);
static void adapt_recorder_setup_string(JNIEnv* env, jobject receiver, jobject p0, jstring p1, jstring p2);
static void adapt_recorder_setup_parcel(JNIEnv* env, jobject receiver, jobject p0, jstring p1, jobject p2);
static jstring adapt_property_get_single(JNIEnv* env, jclass, jstring p0);
static jstring adapt_property_get(JNIEnv* env, jclass, jstring p0, jstring p1);
static jint adapt_property_int(JNIEnv* env, jclass, jstring p0, jint p1);
static jlong adapt_property_long(JNIEnv* env, jclass, jstring p0, jlong p1);
static jboolean adapt_property_boolean(JNIEnv* env, jclass, jstring p0, jboolean p1);

static Hook hooks[] = {
    {"camera_setup", "android/hardware/Camera", "native_setup", "(Ljava/lang/Object;ILjava/lang/String;)I", "LIL", false, true, false, true, 0x28088, 0xe2790, (void*)&adapt_camera_setup},
    {"camera_setup_hal", "android/hardware/Camera", "native_setup", "(Ljava/lang/Object;IILjava/lang/String;)I", "LIIL", false, true, false, false, 0x28150, 0xe2798, (void*)&adapt_camera_setup_hal},
    {"record_setup_legacy", "android/media/AudioRecord", "native_setup", "(Ljava/lang/Object;Ljava/lang/Object;IIIII[ILjava/lang/String;)I", "LLIIIIILL", false, true, false, false, 0x286dc, 0xe27f8, (void*)&adapt_record_setup_legacy},
    {"record_setup_string", "android/media/AudioRecord", "native_setup", "(Ljava/lang/Object;Ljava/lang/Object;[IIIII[ILjava/lang/String;J)I", "LLLIIIILLJ", false, true, false, false, 0x288d0, 0xe2800, (void*)&adapt_record_setup_string},
    {"record_setup_parcel", "android/media/AudioRecord", "native_setup", "(Ljava/lang/Object;Ljava/lang/Object;[IIIII[ILandroid/os/Parcel;JI)I", "LLLIIIILLJI", false, true, false, true, 0x28abc, 0xe2808, (void*)&adapt_record_setup_parcel},
    {"record_start", "android/media/AudioRecord", "native_start", "(II)I", "II", false, true, false, true, 0x28c5c, 0xe2810, (void*)&adapt_record_start},
    {"record_stop", "android/media/AudioRecord", "native_stop", "()V", "", false, true, false, true, 0x28e44, 0xe2818, (void*)&adapt_record_stop},
    {"record_release", "android/media/AudioRecord", "native_release", "()V", "", false, true, false, true, 0x28fa4, 0xe2820, (void*)&adapt_record_release},
    {"recorder_setup_int", "android/media/MediaRecorder", "native_setup", "(Ljava/lang/Object;Ljava/lang/String;)I", "LL", false, true, false, false, 0x29a14, 0xe2828, (void*)&adapt_recorder_setup_int},
    {"recorder_setup_string", "android/media/MediaRecorder", "native_setup", "(Ljava/lang/Object;Ljava/lang/String;Ljava/lang/String;)V", "LLL", false, true, false, false, 0x29ad0, 0xe2830, (void*)&adapt_recorder_setup_string},
    {"recorder_setup_parcel", "android/media/MediaRecorder", "native_setup", "(Ljava/lang/Object;Ljava/lang/String;Landroid/os/Parcel;)V", "LLL", false, true, false, true, 0x29b84, 0xe2838, (void*)&adapt_recorder_setup_parcel},
    {"binder_uid", "android/os/Binder", "getCallingUid", "()I", "", true, true, true, true, 0x2a7d4, 0xe2840, nullptr},
    {"property_get_single", "android/os/SystemProperties", "native_get", "(Ljava/lang/String;)Ljava/lang/String;", "L", true, false, false, false, 0x2b958, 0xe28a8, (void*)&adapt_property_get_single},
    {"property_get", "android/os/SystemProperties", "native_get", "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;", "LL", true, true, false, true, 0x2baf0, 0xe28b0, (void*)&adapt_property_get},
    {"property_int", "android/os/SystemProperties", "native_get_int", "(Ljava/lang/String;I)I", "LI", true, true, false, true, 0x2bdf8, 0xe28b8, (void*)&adapt_property_int},
    {"property_long", "android/os/SystemProperties", "native_get_long", "(Ljava/lang/String;J)J", "LJ", true, true, false, true, 0x2c124, 0xe28c0, (void*)&adapt_property_long},
    {"property_boolean", "android/os/SystemProperties", "native_get_boolean", "(Ljava/lang/String;Z)Z", "LZ", true, true, false, true, 0x2c484, 0xe28c8, (void*)&adapt_property_boolean},
};

static jint adapt_camera_setup(JNIEnv* env, jobject receiver, jobject p0, jint p1, jstring p2) {
    jvalue values[3] = {};
    values[0].l = p0;
    values[1].i = p1;
    values[2].l = p2;
    jobject result = invoke_backup(env, hooks[0], receiver, values);
    return unbox_int(env, result);
}

static jint adapt_camera_setup_hal(JNIEnv* env, jobject receiver, jobject p0, jint p1, jint p2, jstring p3) {
    jvalue values[4] = {};
    values[0].l = p0;
    values[1].i = p1;
    values[2].i = p2;
    values[3].l = p3;
    jobject result = invoke_backup(env, hooks[1], receiver, values);
    return unbox_int(env, result);
}

static jint adapt_record_setup_legacy(JNIEnv* env, jobject receiver, jobject p0, jobject p1, jint p2, jint p3, jint p4, jint p5, jint p6, jintArray p7, jstring p8) {
    jvalue values[9] = {};
    values[0].l = p0;
    values[1].l = p1;
    values[2].i = p2;
    values[3].i = p3;
    values[4].i = p4;
    values[5].i = p5;
    values[6].i = p6;
    values[7].l = p7;
    values[8].l = p8;
    jobject result = invoke_backup(env, hooks[2], receiver, values);
    return unbox_int(env, result);
}

static jint adapt_record_setup_string(JNIEnv* env, jobject receiver, jobject p0, jobject p1, jintArray p2, jint p3, jint p4, jint p5, jint p6, jintArray p7, jstring p8, jlong p9) {
    jvalue values[10] = {};
    values[0].l = p0;
    values[1].l = p1;
    values[2].l = p2;
    values[3].i = p3;
    values[4].i = p4;
    values[5].i = p5;
    values[6].i = p6;
    values[7].l = p7;
    values[8].l = p8;
    values[9].j = p9;
    jobject result = invoke_backup(env, hooks[3], receiver, values);
    return unbox_int(env, result);
}

static jint adapt_record_setup_parcel(JNIEnv* env, jobject receiver, jobject p0, jobject p1, jintArray p2, jint p3, jint p4, jint p5, jint p6, jintArray p7, jobject p8, jlong p9, jint p10) {
    jvalue values[11] = {};
    values[0].l = p0;
    values[1].l = p1;
    values[2].l = p2;
    values[3].i = p3;
    values[4].i = p4;
    values[5].i = p5;
    values[6].i = p6;
    values[7].l = p7;
    values[8].l = p8;
    values[9].j = p9;
    values[10].i = p10;
    jobject result = invoke_backup(env, hooks[4], receiver, values);
    return unbox_int(env, result);
}

static jint adapt_record_start(JNIEnv* env, jobject receiver, jint p0, jint p1) {
    jvalue values[2] = {};
    values[0].i = p0;
    values[1].i = p1;
    jobject result = invoke_backup(env, hooks[5], receiver, values);
    return unbox_int(env, result);
}

static void adapt_record_stop(JNIEnv* env, jobject receiver) {
    jobject result = invoke_backup(env, hooks[6], receiver, nullptr);
    if (result) env->DeleteLocalRef(result);
}

static void adapt_record_release(JNIEnv* env, jobject receiver) {
    jobject result = invoke_backup(env, hooks[7], receiver, nullptr);
    if (result) env->DeleteLocalRef(result);
}

static jint adapt_recorder_setup_int(JNIEnv* env, jobject receiver, jobject p0, jstring p1) {
    jvalue values[2] = {};
    values[0].l = p0;
    values[1].l = p1;
    jobject result = invoke_backup(env, hooks[8], receiver, values);
    return unbox_int(env, result);
}

static void adapt_recorder_setup_string(JNIEnv* env, jobject receiver, jobject p0, jstring p1, jstring p2) {
    jvalue values[3] = {};
    values[0].l = p0;
    values[1].l = p1;
    values[2].l = p2;
    jobject result = invoke_backup(env, hooks[9], receiver, values);
    if (result) env->DeleteLocalRef(result);
}

static void adapt_recorder_setup_parcel(JNIEnv* env, jobject receiver, jobject p0, jstring p1, jobject p2) {
    jvalue values[3] = {};
    values[0].l = p0;
    values[1].l = p1;
    values[2].l = p2;
    jobject result = invoke_backup(env, hooks[10], receiver, values);
    if (result) env->DeleteLocalRef(result);
}

static jstring adapt_property_get_single(JNIEnv* env, jclass, jstring p0) {
    jvalue values[1] = {};
    values[0].l = p0;
    jobject result = invoke_backup(env, hooks[12], nullptr, values);
    return (jstring)result;
}

static jstring adapt_property_get(JNIEnv* env, jclass, jstring p0, jstring p1) {
    jvalue values[2] = {};
    values[0].l = p0;
    values[1].l = p1;
    jobject result = invoke_backup(env, hooks[13], nullptr, values);
    return (jstring)result;
}

static jint adapt_property_int(JNIEnv* env, jclass, jstring p0, jint p1) {
    jvalue values[2] = {};
    values[0].l = p0;
    values[1].i = p1;
    jobject result = invoke_backup(env, hooks[14], nullptr, values);
    return unbox_int(env, result);
}

static jlong adapt_property_long(JNIEnv* env, jclass, jstring p0, jlong p1) {
    jvalue values[2] = {};
    values[0].l = p0;
    values[1].j = p1;
    jobject result = invoke_backup(env, hooks[15], nullptr, values);
    return unbox_long(env, result);
}

static jboolean adapt_property_boolean(JNIEnv* env, jclass, jstring p0, jboolean p1) {
    jvalue values[2] = {};
    values[0].l = p0;
    values[1].z = p1;
    jobject result = invoke_backup(env, hooks[16], nullptr, values);
    return unbox_boolean(env, result);
}

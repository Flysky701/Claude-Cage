package io.github.leexeo.cage.space;

import java.lang.reflect.Method;

/** Android 14+ adds a namespace before JobInfo/job ID; preserve the actual ABI. */
public final class GuestJobArguments {
    private GuestJobArguments() { }
    public static int index(Method method, Class<?> argument) {
        Class<?>[] types = method.getParameterTypes();
        for (int i = 0; i < types.length; i++) if (types[i] == argument) return i;
        return 0; // Keep the existing legacy handling for other signatures.
    }
}

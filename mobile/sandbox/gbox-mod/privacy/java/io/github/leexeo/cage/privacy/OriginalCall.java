package io.github.leexeo.cage.privacy;

import java.lang.reflect.Method;

/** Implemented by the existing VLite service proxy after its entry is wrapped. */
public interface OriginalCall {
    Object cageOriginalInvoke(Object proxy, Method method, Object[] args) throws Throwable;
}

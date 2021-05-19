import java.lang.invoke.MethodHandle;
import java.lang.reflect.Method;

class Test {
    void sinkObject(Object... objects) { }
    <T> void sinkGeneric(T... objects) { }
    void sinkMultiple(int[] ints, Object... objects) { }

    void test() {
        int[] ints = new int[10];
        sinkObject(ints);
        // Not detected due to https://github.com/github/codeql/issues/5929
        sinkGeneric(ints);
        sinkMultiple(ints, ints);
    }

    void sinkPrimitive(int... ints) { }
    void sinkPrimitives(int[]... ints) { }

    void testCorrect() throws Throwable {
        int[] ints = new int[10];
        // Multiple varargs elements
        sinkObject(ints, ints);
        // Explicit varargs array
        sinkPrimitive(ints);
        // Call to method with specific varargs type
        sinkPrimitives(ints);

        // Calling invoking methods where spreading array elements is most likely
        // not the intention
        Method method = null;
        method.invoke(null, ints);

        MethodHandle methodHandle = null;
        methodHandle.invoke(ints);
        methodHandle.invokeExact(ints);
        methodHandle.invokeWithArguments(ints);
    }
}
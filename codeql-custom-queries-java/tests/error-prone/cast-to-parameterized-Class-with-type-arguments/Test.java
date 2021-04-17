import java.util.List;
import java.util.Map;

class Test {
    <T> void test(Class<?> c) {
        Object r;
        r = (Class<List<String>>) c;
        r = (Class<List<T>>) c;
        r = (Class<Map<?, Integer>>) c;
    }

    <T> void testCorrect(Class<?> c) {
        Object r;
        r = (Class<String>) c;
        r = (Class<List<?>>) c;

        // Raw types should not be reported
        r = (Class<List>) c;

        // Even though usage of type variable can be error-prone, often it is
        // used in a safe way; there don't report it
        r = (Class<T>) c;
    }

    // Only cast expressions should be reported, type access in general, such as
    // this parameter type, should not be reported
    void testTypeAccess(Class<List<String>> c) {
    }
}
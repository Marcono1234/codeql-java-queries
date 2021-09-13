import java.util.Arrays;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

class Test {
    void test() {
        Object r;
        r = (int) 1;
        r = (Integer) 1; // TODO: Currently not reported
        r = (Object) "";
        r = (String[]) new String[0];
        r = (Object[]) new String[0];
        r = (ArrayList<String>) new ArrayList<>(Arrays.asList("a"));
        r = (ArrayList<?>) new ArrayList<String>(); // TODO: Currently not reported
        r = (List<String>) new ArrayList<String>();
        r = (HashMap<?, Integer>) new HashMap<Integer, Integer>(); // TODO: Currently not reported
    }

    void overloaded(String s) { }
    void overloaded(Object o) { }

    class ShadowingSuper {
        String f = "super";
    }

    class ShadowingSub extends ShadowingSuper {
        String f = "sub";
    }

    <T> T genericMethod(T t) {
        return t;
    }

    void testCorrect() {
        Object r;
        // Unboxing could cause NullPointerException
        r = (int) Integer.valueOf(1);

        r = (String[]) new Object[0];

        // Cast to raw type; might be used to assign to parameterized type with different
        // type arguments
        r = (ArrayList) new ArrayList<>();

        r = (HashMap<?, String>) (HashMap<?, ?>) new HashMap<Integer, Integer>();
        r = (List<String>) (List<?>) new ArrayList<String>();

        // Uses cast to choose correct overload
        overloaded((Object) "");

        // Uses cast to access shadowed field
        r = ((ShadowingSuper) new ShadowingSub()).f;

        // Ignore if used as argument for type variable parameter; might be used to
        // influence type inference
        genericMethod((Object) "");
    }
}

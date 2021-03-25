import java.lang.reflect.Type;
import java.util.List;

class Test {
    static class TypeToken<T> {
        protected TypeToken() { }

        public Type getType() {
            return null;
        }
    }

    void test() {
        new TypeToken<String>() {};
        new TypeToken<List>() {}; // raw type
    }

    // Has two type variables, probably not a type token
    static class NotATypeToken<T1, T2> {
        protected NotATypeToken() { }

        public Type getType() {
            return null;
        }
    }

    <T> void testCorrect() {
        new TypeToken<List<String>>() {};
        new TypeToken<T>() {}; // capturing type variable
        new NotATypeToken<String, String>() {};
    }

    // Ignore non-anonymous subclasses; they might implement custom logic,
    // or supertype which was assumed to be type token might not actually
    // be a type token
    static class Subclass extends TypeToken<String> {
    }
}
class Test {
    interface Generic<T> {
        T get();
    }

    Void getVoid() {
        return null;
    }

    void test() {
        if (getVoid() != null) { }

        Generic<Void> g = null;
        System.out.println(g.get());
    }

    Object testBadDelegate() {
        // Performing (redundant) cast is more than just delegating
        return (Object) getVoid();
    }

    void sink(Object o) { }
    // Note: Using Void as parameter is already questionable
    void sinkVoid(Void v) { }

    void testBadArguments() {
        sink(getVoid());
        sinkVoid(getVoid());
    }

    void testCorrect() {
        getVoid();

        Generic<Void> g = null;
        g.get();

        Runnable r = () -> getVoid();

        // Correct: Implements interface with Void as return type
        g = () -> getVoid();
        g = this::getVoid;

        // Correct: Implements interface with Object as return type
        Generic<Object> g2 = () -> getVoid();
        g2 = this::getVoid;
    }

    Void testDelegate() {
        // Ignore if returning delegate result
        return getVoid();
    }

    Object testDelegateObject() {
        // Ignore if returning delegate result
        return getVoid();
    }

    static class ConstructorDelegation {
        ConstructorDelegation(Void v) {
        }

        public ConstructorDelegation() {
            this(checkPermission());
        }

        void badNew() {
            // This is bad usage, could instead put checkPermission() call
            // as separate statement (and maybe use `null` as Void argument)
            new ConstructorDelegation(checkPermission());
        }

        // Pattern used by OpenJDK to perform SecurityManager check before
        // calling delegate `this(...)` or `super(...)` (which have to be
        // the first statement)
        static Void checkPermission() { }
    }

    static class Subclass extends ConstructorDelegation {
        Subclass() {
            super(checkPermission());
        }
    }
}
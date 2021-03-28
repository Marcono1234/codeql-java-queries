import java.util.function.*;

class Test {
    static class ComplexBase {
        public String f1;
        public String f2;
        public String f3;

        public void doSomething1() { }
        public void doSomething2() { }
        public void doSomething3() { }
    }

    // Should be reported, extends class with multiple methods and fields
    static class ExtendingComplexBase extends ComplexBase implements Predicate<String> {
        @Override
        public boolean test(String s) {
            return true;
        }
    }

    interface ComplexInterface extends Function<String, String> {
        void doSomething1();
        void doSomething2();
        void doSomething3();
        void doSomething4();
        void doSomething5();
        void doSomething6();
    }

    interface ComplexExtendingRaw extends Predicate {
        void doSomething1();
        void doSomething2();
        void doSomething3();
        void doSomething4();
    }

    // Each implemented interface should be considered separately when ignoring
    // inherited methods, so when either of them exceeds threshold type implementing
    // them should be reported
    interface MultipleStandardInterfaces extends Function<String, String>, Predicate<String> {
    }

    // Overriding Object methods should not be considered complex
    static class ObjectMethods implements Supplier<String> {
        public String f1;

        @Override
        public int hashCode() {
            return 0;
        }

        @Override
        public boolean equals(Object o) {
            return true;
        }

        @Override
        public String toString() {
            return "";
        }

        @Override
        public ObjectMethods clone() {
            return null;
        }

        @Override
        public void finalize() {
        }

        @Override
        public String get() {
            return null;
        }
    }

    // Inheriting enum methods should not be considered complex
    enum EnumMethods implements Supplier<String> {
        ;

        public void doSomething1() { }

        @Override
        public String get() {
            return "";
        }
    }

    // Static fields and methods should not be considered complex
    static class StaticMembers implements Supplier<String> {
        public static String f1;
        public static String f2;
        public static String f3;
        public static String f4;
        public static String f5;
        public static String f6;
        public static String f7;

        public static void doSomething1() { }
        public static void doSomething2() { }
        public static void doSomething3() { }
        public static void doSomething4() { }
        public static void doSomething5() { }
        public static void doSomething6() { }
        public static void doSomething7() { }

        @Override
        public String get() {
            return "";
        }
    }

    // Private or package-private fields and methods should not be considered complex
    static class PrivateMembers implements Predicate<String> {
        private String f1;
        private String f2;
        private String f3;
        private String f4;
        String f5;
        String f6;
        String f7;

        private void doSomething1() { }
        private void doSomething2() { }
        private void doSomething3() { }
        void doSomething4() { }
        void doSomething5() { }
        void doSomething6() { }
        void doSomething7() { }

        @Override
        public boolean test(String s) {
            return true;
        }
    }

    @FunctionalInterface
    interface CustomFunctionalInterface {
        void doSomething();
    }

    // Custom functional interfaces should be ignored
    static class ImplementingCustomInterface extends ComplexBase implements CustomFunctionalInterface {
        @Override
        public void doSomething() { }
    }

    // Should not report types which only transitively implement functional interface
    interface NotDirectlyExtendingInterface extends ComplexInterface {
    }

    // Extending raw types should not be reported when no new methods are added
    interface ExtendingRaw extends Predicate {
        @Override
        default boolean test(Object o) {
            return true;
        }

        @Override
        default Predicate and(Predicate other) {
            return null;
        }

        @Override
        default Predicate negate() {
            return null;
        }
    }
}
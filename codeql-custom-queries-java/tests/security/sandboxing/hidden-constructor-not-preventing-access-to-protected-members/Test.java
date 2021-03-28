public class Test {
    public static class PubliclyVisible {
        private PubliclyVisible() { }

        protected static int i;
        protected static void test() { }
        protected static class Nested { }

        // These should not be reported
        private static int privateF;
        static int packageF;
        public static int publicF;
        protected int instanceF;
    }

    public static class PubliclyVisible2 {
        PubliclyVisible2() { }

        protected static int i;
    }

    // Should not be reported, class if final
    public static final class PubliclyVisibleFinal {
        private PubliclyVisibleFinal() { }

        protected static int i;
    }

    // Should not be reported, has public default constructor
    public static class PubliclyVisibleWithDefaultConstructor {
        protected static int i;
    }

    // Should not be reported, has public constructor
    public static class PubliclyVisibleWithPublicConstructor {
        public PubliclyVisibleWithPublicConstructor() { }

        protected static int i;
    }

    // Should not be reported, has protected constructor
    public static class PubliclyVisibleWithProtectedConstructor {
        protected PubliclyVisibleWithProtectedConstructor() { }

        protected static int i;
    }

    // Should not be reported, is not publicly visible
    static class NonPubliclyVisible {
        private NonPubliclyVisible() { }

        protected static int i;
    }
}

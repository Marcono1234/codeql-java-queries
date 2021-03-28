class Test {
    enum EnumTest implements Runnable {
        // Has no constants
        ;

        private String s;

        EnumTest(String s) {
            this.s = s;
        }

        @Override
        public void run() { }

        // Non-static inner class
        class InnerClass {
        }
    }

    enum EnumTestSubclasses {
        // Has anonymous subclass as constant
        Test() {
            public String s2;
        };

        public String s;
    }

    enum EnumTestUtility {
        // Has no constants
        ;

        // But only has static utility methods and fields
        public static final String s = "";

        public static void test() { }

        static class Nested { }
    }
}
class Test {
    static final String EMPTY = "";

    void test() {
        new StringBuilder("");
        new StringBuffer("");
    }

    void testCorrect(String s) {
        new StringBuilder(s);
        new StringBuffer(s);

        new StringBuilder("a");
        new StringBuilder("" + "a");
        new StringBuffer("a");
        new StringBuffer("" + "a");

        // Don't consider compile time constants
        new StringBuilder(EMPTY);
        new StringBuffer(EMPTY);

        new StringBuilder();
        new StringBuilder(10);
        new StringBuffer();
        new StringBuffer(10);
    }
}
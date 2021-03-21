class Test {
    static final boolean TRUE = true;

    void test() {
        assert true;
        assert (true);
        assert true : "Some message";
    }

    boolean getBoolean() {
        return true;
    }

    void testCorrect(boolean b, Boolean boxed) {
        assert b;
        assert boxed;
        assert getBoolean();
        assert false;
        assert false : "Some message";
        // Compile time constants should not be detected
        assert TRUE;
        assert true && true;
    }
}
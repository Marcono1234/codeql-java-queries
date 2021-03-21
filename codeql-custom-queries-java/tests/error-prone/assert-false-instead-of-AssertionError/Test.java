class Test {
    static final boolean FALSE = false;

    void test() {
        assert false;
        assert (false);
        assert false : "Some message";
        // Also consider compile time constants
        assert FALSE;
        assert true && false;
    }

    boolean getBoolean() {
        return true;
    }

    void testCorrect(boolean b, Boolean boxed) {
        assert b;
        assert boxed;
        assert getBoolean();
        assert true;
        assert true : "Some message";
        assert true && true;
    }
}
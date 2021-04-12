class Test {
    void test() {
        long r = 1;
        r = r % -1;
        r = r % -2147483648;
        r = r % -1L;
        r = r % -9223372036854775808L;
        r = r % +(-1);
        r = r % (int) -1f;
        r = r % (int) -1d;

        // Also consider non-literal negative expressions
        r = r % -r;

        r %= -1;
    }

    void testCorrect() {
        final int constant = -1;
        long r = 1;
        r = r % 1;

        // Don't report negative non-decimal constants
        r = r % 0x80000000;
        r = r % 0x8000000000000000L;

        // Don't report compile time constants
        r = r % constant;

        r = r % +1;
        r = r % (int) 1;
        r %= 1;
    }
}
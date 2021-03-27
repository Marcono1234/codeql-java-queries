class Test {
    void test(byte b) {
        boolean r;
        r = b < 16;
        r = 16 > b;
        r = b <= 15;
        r = 15 >= b;
        r = b > 15;
        r = 15 < b;
        r = b >= 16;
        r = 16 <= b;

        Byte boxedB = b;
        r = boxedB > 15;
    }

    void testCorrect(byte b) {
        boolean r;
        // Correct, checks unsigned value
        r = (b & 0xFF) > 15;
        int i = b;
        // Don't report this, value is not a byte
        r = i > 15;

        // Don't report this, byte is used as counter
        for (byte counter = 0; counter < 16; counter++) {
        }
    }
}
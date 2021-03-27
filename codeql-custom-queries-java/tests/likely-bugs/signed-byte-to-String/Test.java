class Test {
    void test(byte b) {
        Integer.toString(b, 2);
        Integer.toString(b, 8);
        Integer.toString(b, 16);
        Integer.toBinaryString(b);
        Integer.toOctalString(b);
        Integer.toHexString(b);

        Byte boxedB = b;
        Integer.toHexString(boxedB);
    }

    void testCorrect() {
        byte b = (byte) 0xFF;
        Integer.toHexString(b & 0xFF);

        // Ignore regular toString or toString with non-binary, octal or hex radix
        Integer.toString(b);
        Integer.toString(b, 10);

        // Ignore if only part of display message
        System.out.println("The value is: " + Integer.toString(b));

        // Argument is not of type byte
        Integer.toHexString(255);
    }
}
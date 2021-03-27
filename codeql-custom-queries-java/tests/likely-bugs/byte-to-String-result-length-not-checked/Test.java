class Test {
    void test(byte b) {
        StringBuilder sb = new StringBuilder();
        sb.append(Integer.toString(b & 0xFF, 16));
        sb.append(Integer.toString(0xFF & b, 8));
        sb.append(Integer.toString(b & 255, 2));
        sb.append(Integer.toBinaryString(b & 0xFF));
        sb.append(Integer.toOctalString(b & 0xFF));
        sb.append(Integer.toHexString(b & 0xFF));

        String s = Integer.toHexString(b & 0xFF);
        sb.append(s);
        s = "test";
        // Performs test on re-assigned value
        if (s.length() == 1) {
        }

        sb.append(String.format("%x", b));
        sb.append(String.format("%X", b));

        s = String.format("%x", b);
        // Report formatter call even though this performs length check;
        // for formatter calls width should be specified instead
        if (s.length() == 1) {
        }

        Byte boxedB = b;
        sb.append(Integer.toHexString(boxedB & 0xFF));
        sb.append(String.format("%X", boxedB));
    }

    void testCorrect(byte b) {
        StringBuilder sb = new StringBuilder();

        int unsignedB = b & 0xFF;
        // Don't report this for now; assume that since conversion to unsigned
        // is not performed at call, there is likely a `unsignedB < 16` check
        sb.append(Integer.toHexString(unsignedB));

        // Don't report this, using signed byte is detected by separate query
        sb.append(Integer.toHexString(b));

        // Correct, uses 0x0F (instead of 0xFF) as bitmask
        sb.append(Integer.toHexString(b & 0x0F));

        // Ignore regular toString or toString with non-binary, octal or hex radix
        sb.append(Integer.toString(b & 0xFF));
        sb.append(Integer.toString(b & 0xFF, 10));

        // Ignore if only part of display message
        System.out.println("The value is: " + Integer.toHexString(b & 0xFF));

        // Correct, specifies width
        sb.append(String.format("%02x", b));
        sb.append(String.format("%02X", b));
        // Ignore, not a byte value
        sb.append(String.format("%x", 255));

        String s = Integer.toHexString(b & 0xFF);
        // Correct, checks length
        if (s.length() == 1) {
            sb.append('0');
        }
        sb.append(s);
    }
}
class Test {
    void testCast() {
        Object r;
        r = (byte) '\u0100'; // TODO: Not detected yet
        r = (byte) -129;
        r = (byte) 256;
        r = (byte) -129L;
        r = (byte) 256L;
        r = (byte) -128.1f;
        r = (byte) 255.1f;
        r = (byte) -128.1d;
        r = (byte) 255.1d;

        r = (short) -32769;
        r = (short) 65536;
        r = (short) -32769;
        r = (short) 65536L;
        r = (short) -32768.1f;
        r = (short) 65535.1f;
        r = (short) -32768.1d;
        r = (short) 65535.1d;

        // Note: Somtimes `(char) -1` is used as 'no-value', however this will just wrap around
        //   to `\uFFFF`, which might cause incorrect behavior when that char is actually part
        //   of the input
        r = (char) -1;
        r = (char) 65536;
        r = (char) -1L;
        r = (char) 65536L;
        r = (char) -0.1f;
        r = (char) 65535.1f;
        r = (char) -0.1d;
        r = (char) 65535.1d;

        r = (int) -2147483649L;
        r = (int) 2147483648L;
        r = (int) -2147483648.1f;
        r = (int) 2147483647.1f;
        r = (int) -2147483648.1d;
        r = (int) 2147483647.1d;

        r = (long) -19223372036854775808.0f;
        r = (long) 19223372036854775808.0f;
        r = (long) -19223372036854775808.0d;
        r = (long) 19223372036854775808.0d;

        r = (float) -3.4028235E40d;
        r = (float) 3.4028235E40d;
    }

    void testCastCorrect() {
        Object r;
        // Allow up to 255 to handle unsigned byte value
        r = (byte) '\u00FF';
        r = (byte) -128;
        r = (byte) 127;
        r = (byte) 255;
        r = (byte) -128L;
        r = (byte) 255L;
        r = (byte) -128f;
        r = (byte) 255f;
        r = (byte) -128d;
        r = (byte) 255d;

        // Allow up to 65535 to handle unsigned short value
        r = (short) '\uFFFF';
        r = (short) -32768;
        r = (short) 65535;
        r = (short) -32768;
        r = (short) 65535L;
        r = (short) -32768f;
        r = (short) 65535f;
        r = (short) -32768d;
        r = (short) 65535d;

        r = (char) 0;
        r = (char) 65535;
        r = (char) 0L;
        r = (char) 65535L;
        r = (char) -0f;
        r = (char) 65535f;
        r = (char) -0d;
        r = (char) 65535d;

        r = (int) -2147483648L;
        r = (int) 2147483647L;
        r = (int) -2147483648f;
        r = (int) 2147483647f;
        r = (int) -2147483648d;
        r = (int) 2147483647d;

        r = (long) -9223372036854775808f;
        r = (long) 9223372036854775807f;
        r = (long) -9223372036854775808d;
        r = (long) 9223372036854775807d;

        r = (float) 3.4028235E38d;
        r = (float) 3.4028235E38d;
    }

    void testAssign() {
        byte b = 0;
        b += '\u0100'; // TODO: Not detected yet
        b += -129;
        b += 256;
        b += -129L;
        b += 256L;
        b += -128.1f;
        b += 255.1f;
        b += -128.1d;
        b += 255.1d;

        short s = 0;
        s += -32769;
        s += 65536;
        s += -32769;
        s += 65536L;
        s += -32768.1f;
        s += 65535.1f;
        s += -32768.1d;
        s += 65535.1d;

        char c = 0;
        c += -1;
        c += 65536;
        c += -1L;
        c += 65536L;
        c += -0.1f;
        c += 65535.1f;
        c += -0.1d;
        c += 65535.1d;

        int i = 0;
        i += -2147483649L;
        i += 2147483648L;
        i += -2147483648.1f;
        i += 2147483647.1f;
        i += -2147483648.1d;
        i += 2147483647.1d;

        long l = 0;
        l += -19223372036854775808.0f;
        l += 19223372036854775808.0f;
        l += -19223372036854775808.0d;
        l += 19223372036854775808.0d;

        float f = 0f;
        f += -3.4028235E40d;
        f += 3.4028235E40d;
    }

    void testAssignCorrect() {
        byte b = 0;
        // Allow up to 255 to handle unsigned byte value
        b += '\u00FF';
        b += -128;
        b += 127;
        b += 255;
        b += -128L;
        b += 255L;
        b += -128f;
        b += 255f;
        b += -128d;
        b += 255d;

        short s = 0;
        // Allow up to 65535 to handle unsigned short value
        s += '\uFFFF';
        s += -32768;
        s += 65535;
        s += -32768;
        s += 65535L;
        s += -32768f;
        s += 65535f;
        s += -32768d;
        s += 65535d;

        char c = 0;
        c += 0;
        c += 65535;
        c += 0L;
        c += 65535L;
        c += -0f;
        c += 65535f;
        c += -0d;
        c += 65535d;

        int i = 0;
        i += -2147483648L;
        i += 2147483647L;
        i += -2147483648f;
        i += 2147483647f;
        i += -2147483648d;
        i += 2147483647d;

        long l = 0;
        l += -9223372036854775808f;
        l += 9223372036854775807f;
        l += -9223372036854775808d;
        l += 9223372036854775807d;

        float f = 0;
        f += 3.4028235E38d;
        f += 3.4028235E38d;
    }
}
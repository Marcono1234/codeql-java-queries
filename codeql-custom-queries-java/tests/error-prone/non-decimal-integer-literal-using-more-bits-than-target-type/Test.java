class Test {
    void bad() {
        byte b;
        b = 0xFFFF_FFFF; // -1
        b = 0Xffff_ffff; // -1
        b = 0xFFFF_FF80; // -128
        b = 0_377_7777_7777; // -1
        b = 0_377_7777_7600; // -128
        b = 0b1111_1111_1111_1111_1111_1111_1111_1111; // -1
        b = 0B1111_1111_1111_1111_1111_1111_1111_1111; // -1
        b = 0b1111_1111_1111_1111_1111_1111_1000_0000; // -128
        Byte boxedByte = 0xFFFF_FFFF; // -1

        short s;
        s = 0xFFFF_FFFF; // -1
        s = 0Xffff_ffff; // -1
        s = 0xFFFF_8000; // -32768
        s = 0_377_7777_7777; // -1
        s = 0_377_7770_0000; // -32768
        s = 0b1111_1111_1111_1111_1111_1111_1111_1111; // -1
        s = 0B1111_1111_1111_1111_1111_1111_1111_1111; // -1
        s = 0b1111_1111_1111_1111_1000_0000_0000_0000; // -32768
        Short boxedShort = 0xFFFF_FFFF; // -1
    }

    void good() {
        // Explicit cast
        byte b = (byte) 0xFFFF_FFFF;

        // Larger target type
        int i = 0xFFFF_FFFF;

        // char is unsigned, value is within range
        char c = 0xFFFF;

        // Within range
        b = 0;
        b = 0x7F;
        b = 0_177;
        b = 0b111_1111;
    }
}
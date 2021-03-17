class Test {
    float[] imprecise = {
        2147483647f,
        9223372036854775807f,
        123456789E25f,
        1.55555555555555555f,
        // Rounds to Float.MIN_VALUE
        1.0E-45f,
        0x1.23456789p1f, // MISSING
        0X.23456789P1f // MISSING
    };

    float[] precise = {
        0.0f,
        0.1f,
        2.14748365E9f,
        2147483650f,
        9223372000000000000f,
        // From the JLS
        0x1.fffffeP+127f,
        0x0.000002P-126f,
        0x1.0P-149f,
        0X1.p-149f,
        3.4028235e38f,
        1.4e-45f
    };

    // double is not detected by query
    double impreciseDouble = 1.55555555555555555;
}
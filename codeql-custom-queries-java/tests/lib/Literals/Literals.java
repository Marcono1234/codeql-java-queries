class Literals {
    boolean[] booleans = {
        true,
        false
    };

    char[] chars = {
        'a', // $numeric=97
        '\0', // $numeric=0
        '\uFFFF' // $numeric=65535
    };

    int[] ints = {
        0, // $numeric=0
        -2147483648, // $numeric=-2147483648
        2147483647, // $numeric=2147483647
        // Minus is not part of literal
        -2147483647, // $numeric=2147483647
        0xFFFF_FFFF, // $numeric=-1
    };

    long[] longs = {
        0L, // $numeric=0
        -9223372036854775808L, // $numeric=-9223372036854775808
        // Numbers are parsed as 64-bit CodeQL float so there is precision loss
        9223372036854775807L, // $numeric=9223372036854775808
        0xFFFF_FFFF_FFFF_FFFFL // $numeric=-1
    };

    // TODO: Has some incorrect test outputs due to https://github.com/github/codeql/issues/5451

    float[] floats = {
        0f, // $numeric=0
        // Minus is not part of literal
        -0f, // $numeric=0

        // Float.MIN_VALUE
        1.4E-45f, // $ SPURIOUS: numeric=0
        0x0.000002P-126f, // $ SPURIOUS: numeric=0
        // Rounds to Float.MIN_VALUE
        1.0E-45f, // $ SPURIOUS: numeric=0
        // Close to Float.MIN_VALUE without losing precision
        1e-43f, // $ SPURIOUS: numeric=0

        // Float.MIN_NORMAL
        1.17549435E-38f, // $ SPURIOUS: numeric=0
        0x1.0p-126f, // $ SPURIOUS: numeric=0

        // -Float.MAX_VALUE (minus is not part of literal)
        -3.4028235E38f, // $ SPURIOUS: numeric=340282349999999991754788743781432688640
        // Float.MAX_VALUE
        3.4028235E38f, // $ SPURIOUS: numeric=340282349999999991754788743781432688640
        0x1.fffffeP+127f, // $ SPURIOUS: numeric=340282349999999991754788743781432688640

        1.5555f, // $numeric=1.5555
        1.555555555f, // $ SPURIOUS: numeric=1.555556
        1.55555555555555555f // $ SPURIOUS: numeric=1.555556
    };

    double[] doubles = {
        0d, // $numeric=0
        // Minus is not part of literal
        -0d, // $numeric=0

        // `float` rounded Float.MIN_VALUE (as double)
        1.4E-45d, // $ SPURIOUS: numeric=0
        0x0.000002P-126d, // $ SPURIOUS: numeric=0

        // `float` rounded Float.MAX_VALUE (as double)
        3.4028235E38d, // $ SPURIOUS: numeric=340282349999999991754788743781432688640
        0x1.fffffeP+127d, // $ SPURIOUS: numeric=340282346638528859811704183484516925440

        // Double.MIN_VALUE
        4.9E-324d, // $ SPURIOUS: numeric=0
        0x0.0000000000001P-1022d, // $ SPURIOUS: numeric=0
        // Rounds to Double.MIN_VALUE
        3.0E-324d, // $ SPURIOUS: numeric=0
        // Close to Double.MIN_VALUE without losing precision
        1.0E-323d, // $ SPURIOUS: numeric=0

        // Double.MIN_NORMAL
        2.2250738585072014E-308d, // $ SPURIOUS: numeric=0
        0x1.0p-1022d, // $ SPURIOUS: numeric=0

        // -Double.MAX_VALUE (minus is not part of literal)
        -1.7976931348623157E308d, // $ SPURIOUS: numeric=179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368
        // Double.MAX_VALUE
        1.7976931348623157E308d, // $ SPURIOUS: numeric=179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368
        0x1.fffffffffffffP+1023d, // $ SPURIOUS: numeric=179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368

        1.5555d, // $numeric=1.5555
        1.555555555d, // $ SPURIOUS: numeric=1.555556
        1.55555555555555555d // $ SPURIOUS: numeric=1.555556
    };
}
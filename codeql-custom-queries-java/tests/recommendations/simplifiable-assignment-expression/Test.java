class Test {
    void test(int i) {
        i = i + i;
        i = i + 1;
        i = i + (int) 1.0; // Not detected as unary
        i = i + 2;
        i = 1 + i;
        i = 1 + 1; // Should not be reported
        i = 2 + i;
        i = i - 1;
        i = i - 2;
        i = 1 - i; // Should not be reported
    }

    void sink(int i) { }

    void testUnary(int i) {
        i = i + 1;
        sink(i = i + 1); // must use pre increment
        i = i - 1;
        sink(i = i - 1); // must use pre decrement
    }

    void testOperators(int i) {
        i = i + 2;
        i = 2 + i;
        i = i - 2;
        i = 2 - i; // Should not be reported
        i = i * 2;
        i = 2 * i;
        i = i / 2;
        i = 2 / i; // Should not be reported
        i = i % 2;
        i = 2 % i; // Should not be reported
        i = i & 2;
        i = 2 & i;
        i = i ^ 2;
        i = 2 ^ i;
        i = i | 2;
        i = 2 | i;
        i = i << 2;
        i = 2 << i; // Should not be reported
        i = i >> 2;
        i = 2 >> i; // Should not be reported
        i = i >>> 2;
        i = 2 >>> i; // Should not be reported

        boolean b = i == 0;
        // Don't have compound assignment operators
        b = b && b;
        b = b || b;
    }

    void testStringConcat(String a, int i) {
        a = a + "test";
        a = "test" + a; // Should not be reported
        a = a + i;
        a = i + a; // Should not be reported
        a = a + a;
        a = a + 1;
    }

    void testArrayAccess(int[] a) {
        a[0] = a[0] + 1;
        a[0] = 1 + a[0];
        a[0] = a[0] - 1;
        a[0] = 1 - a[0]; // Should not be reported
        a[0] = a[1] + 1; // Should not be reported (different indices)
    }

    void testFloatingPoint(float f, double d) {
        f = f + 5;
        f = 5 + f;
        d = d + 5;
        d = 5 + d;
    }

    void testLiteralsUnary(int i, long l, float f, double d) {
        i = i + 1;

        l = l + 1;
        l = l + 1L;

        f = f + 1;
        f = f + 1L;
        f = f + 1f;
        
        d = d + 1;
        d = d + 1L;
        d = d + 1f;
        d = d + 1d;
    }
}
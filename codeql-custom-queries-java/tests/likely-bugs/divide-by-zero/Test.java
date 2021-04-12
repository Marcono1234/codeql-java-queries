class Test {
    final byte bFinal = 0;
    final int iFinal = 0;
    final long lFinal = 0L;
    final float fFinal = 0f;
    final double dFinal = 0d;

    void test() {
        Object r;
        r = 1 / 0;
        r = 1 / 0L;
        r = 1 / 0f;
        r = 1 / 0d;
        r = 1 % 0;
        r = 1 % 0L;
        r = 1 % 0f;
        r = 1 % 0d;

        r = 1 / bFinal;
        r = 1 / iFinal;
        r = 1 / lFinal;
        r = 1 / fFinal;
        r = 1 / dFinal;

        final byte bLocalFinal = 0;
        final int iLocalFinal = 0;
        final long lLocalFinal = 0L;
        final float fLocalFinal = 0f;
        final double dLocalFinal = 0d;

        r = 1 / bLocalFinal;
        r = 1 / iLocalFinal;
        r = 1 / lLocalFinal;
        r = 1 / fLocalFinal;
        r = 1 / dLocalFinal;

        // non-final variables without reassignment
        byte bLocal = 0;
        int iLocal = 0;
        long lLocal = 0L;
        float fLocal = 0f;
        double dLocal = 0d;

        r = 1 / bLocal;
        r = 1 / iLocal;
        r = 1 / lLocal;
        r = 1 / fLocal;
        r = 1 / dLocal;

        r = 1 / (int) 0f;
        r = 1 / (double) 0L;
        r = 1 / (1 - 1);

        int i = 1;
        i /= 0;
        i %= 0;
    }

    void test(int i) {
        int r;

        if (i == 0) {
            r = 0 / i;
            i = 1; // Should ignore this reassignment
        }
        if (i != 0) {
        }
        else {
            r = 0 / i;
            i = 1; // Should ignore this reassignment
        }
    }

    byte b = 0;
    int i = 0;
    long l = 0L;
    float f = 0f;
    double d = 0d;

    void testCorrect() {
        Object r;
        r = 1 / 1;
        r = 1 / 1L;
        r = 1 / 1f;
        r = 1 / 1d;
        r = 1 % 1;
        r = 1 % 1L;
        r = 1 % 1f;
        r = 1 % 1d;

        // Usage of non-final fields
        r = 1 / b;
        r = 1 / i;
        r = 1 / l;
        r = 1 / f;
        r = 1 / d;

        byte bLocal = 0;
        int iLocal = 0;
        long lLocal = 0L;
        float fLocal = 0f;
        double dLocal = 0d;

        // Reassignment of local variables
        if (true) {
            bLocal = 1;
            iLocal = 1;
            lLocal = 1;
            fLocal = 1;
            dLocal = 1;
        }

        r = 1 / bLocal;
        r = 1 / iLocal;
        r = 1 / lLocal;
        r = 1 / fLocal;
        r = 1 / dLocal;

        r = 1 / (int) 1f;
        r = 1 / (double) 1L;
        r = 1 / (1 - 2);

        int i = 1;
        i /= 1;
        i %= 1;
    }

    void testCorrect(int i) {
        int r;

        if (i != 0) {
            r = 0 / i;
        }
        if (i == 0) {
            // Reassignment before division
            i = 2;
            r = 0 / i;
        }
        else {
            r = 0 / i;
        }
    }
}
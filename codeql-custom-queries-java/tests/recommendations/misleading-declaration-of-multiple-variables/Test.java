class Test {
    String s1, s2 = "test";
    int i1 = 1, i2, i3 = 2;

    void test() {
        String s1, s2 = "test";
        int i1 = 1, i2, i3 = 2;
    }

    // Allow multiple declarations without initializer
    double d1, d2;
    // Allow if initializer occurs before field without initializer
    long l1 = 1, l2;
    float f1, f2;
    {
        // Ignore if initialization does not occur at field declaration
        f2 = 1f;
    }

    void testCorrect() {
        // Allow multiple declarations without initializer
        double d1, d2;
        // Allow if initializer occurs before var without initializer
        long l1 = 1, l2;

        float f1, f2;
        // Ignore if initialization does not occur at var declaration
        f2 = 1f;

        // Ignore declaration in loops; there might be no alternative
        for (int i, i2 = 1; i2 < 10; i2++) {
        }
    }
}
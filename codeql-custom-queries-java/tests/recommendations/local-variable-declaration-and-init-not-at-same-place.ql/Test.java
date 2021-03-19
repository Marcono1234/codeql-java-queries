class Test {
    private String f;
    {
        // Should not match fields
        f = "";
    }

    void sink(int i) { }

    void doSomething() { }

    void test() {
        String s;
        s = "";

        // Not proper assignment chains
        int i;
        i = 1;
        doSomething();
        i = 2; // Should only match first assignment, not this one

        int j;
        doSomething();
        j = 1;
        j = 2;

        int k;
        sink(k = 1);
        sink(k = 2);

        String a, b, c;
        a = "a";
        b = "b";
        c = "c";

        // This only initializes "f"
        String d, e, f = "f";
        d = "d";
        e = "e";

        int r;
        // This decreases readability even further
        sink(r = i + 1);
    }

    void testCorrect(String p) {
        // Should not match re-assignment of parameter
        p = "test";

        double d = 1.0;

        // Assignment chains are allowed
        int b;
        b = 1;
        b |= 2;

        int i;
        // Should not match assignment in loop init
        for (i = 0; i < 10; i++) {
        }

        try {
            // Loop variable in enhanced for loop has implicit init
            for (String s : new String[0]) {
                s = "";
            }
        }
        // catch has implicit init
        catch (Exception e) {
            e = null;
        }

        String s;
        try {
            // Should not match assignment in separate block
            s = System.lineSeparator();
        } finally {
        }
    }
}
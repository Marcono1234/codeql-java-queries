class Test {
    int f;
    int g = f = getInt(); // This is allowed
    int h = 1 + (f = getInt()); // This should be detected
    Exception e;

    int getInt() {
        return 1;
    }

    boolean getBoolean() {
        return false;
    }

    void sink(int i) { }
    
    int test() {
        sink(f = 1);

        int i;
        // Only permit multi assignment as StmtExpr
        sink(f = i = 1);
        f |= i |= 1; // This is not a normal multi assignment, should be detected

        if (getBoolean()) {
            // This is pretty exotic and should be detected
            throw e = new Exception();
        }

        // Assignment in init and update of for loop should be detected
        for (int j = 1 + (i = getInt()); getBoolean(); sink(f = getInt())) {
        }

        // Should be detected; not a simple assignment as return result
        return 1 + (f = getInt());
    }

    int testCorrect() {
        int i = 1;

        // Multi assignment is allowed
        f = i = 2;

        // Usage in loop is allowed
        while ((i = getInt()) != -1) {
        }
        for (; (i = getInt()) != -1;) {
        }
        do {} while ((i = getInt()) != -1);

        // Unary assignments should not be detected
        sink(i++);

        // Should not be detected, still quite readable and used by some libraries
        return f = getInt();
    }
}
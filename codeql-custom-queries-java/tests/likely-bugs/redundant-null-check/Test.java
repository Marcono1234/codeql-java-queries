class Test {
    final String s;

    public Test(boolean b) {
        if (b) {
            s = "a";
        } else {
            s = "b";
        }
    }

    void testFinalVariable(boolean b) {
        final String l;
        if (b) {
            l = "a";
        } else {
            l = "b";
        }

        if (l == null) {
            System.out.println();
        }

        if (s == null) {
            System.out.println();
        }
    }

    void testAssignedNonNull() {
        String l = null;
        l = "";

        if (l == null) {
            System.out.println();
        }
    }

    void testAssignAddConcat() {
        String l = null;
        // Result of String concatenation is never null
        l += null;

        if (l == null) {
            System.out.println();
        }
    }

    void testDereference(String p) {
        // Would have thrown a NullPointerException
        p.isEmpty();

        if (p == null) {
            System.out.println();
        }
    }

    void testDereferenceFinally(String p) {
        try {
            p.isEmpty();
        } finally {
            // This is not redundant since `finally` is also executed when
            // dereference throws NullPointerException
            if (p == null) {
                System.out.println();
            }
        }
    }

    void testOtherNullGuard(String p) {
        if (p != null) {
            if (p == null) {
                System.out.println();
            }
        }
    }
}
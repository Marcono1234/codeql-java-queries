public class Test {
    // Field `f1` is only used by constructors
    String f1;

    Test(String s) {
        this.f1 = s;
        if (f1.isEmpty()) {
            System.out.println();
        }
    }

    Test(String s, Void dummy) {
        this.f1 = s;
        if (f1.isEmpty()) {
            System.out.println();
        }
    }

    // Field should be reported because only usage occurs in `test(String)`
    // which always overwrites value
    // TODO: Not reported at the moment
    String f2 = "initial";
    {
        f2 = "other-value";
        if (f2.isEmpty()) {
        }
    }

    void test(String s) {
        f2 = s;
        if (f2.isBlank()) {
            if (f2.isEmpty()) {
                System.out.println();
            }
        }
    }

    static String f3 = "static";
    static {
        f3 = "other-value";
        if (f3.isEmpty()) {
        }
    }

    void testStatic(String s) {
        f2 = s;
        if (f2.isBlank()) {
            if (f2.isEmpty()) {
                System.out.println();
            }
        }
    }

    // Field is used by multiple methods and constructors, but they always overwrite value
    // TODO: Not reported at the moment
    String f4;

    Test(Void dummy) {
        if (f4.isEmpty()) {
            System.out.println();
        }
    }

    void testMultiple1(String s) {
        f4 = s;
        if (f4.isBlank()) {
            System.out.println();
        }
    }

    void testMultiple2(String s) {
        f4 = s;
        if (f4.isBlank()) {
            System.out.println();
        }
    }

    // Field is only used in static initializer
    // TODO: Not reported at the moment
    static String staticInit;
    static {
        staticInit = "a";
        if (staticInit.isEmpty()) {
            System.out.println();
        }
    }

    // Ignore completely unused fields; should be covered by a separate query
    String unused;
    static String unusedStatic;

    private String fPrivate;
    String fPackage;
    // Ignore fields which are protected or public
    protected String fProtected;
    public String fPublic;

    void testVisibility(String s) {
        fPrivate = fPackage = fProtected = fPublic = s;
        String[] arr = {
            fPrivate,
            fPackage,
            fProtected,
            fPublic
        };
    }
    
    // Ignore fields which are not reassigned
    String noReassign = "a";
    static String noReassignStatic = "b";

    void testNoReassign() {
        if (noReassign.isEmpty() && noReassignStatic.isEmpty()) {
            System.out.println();
        }
    }

    String otherUsageNoRead; // TODO: Not reported at the moment
    // Ignore fields which are used by other methods
    String otherUsage;
    static String otherUsageStatic;

    void testOtherUsage(String s) {
        otherUsageNoRead = s;
        otherUsage = s;
        otherUsageStatic = s;
        if (otherUsageNoRead.isEmpty() && otherUsage.isEmpty() && otherUsageStatic.isEmpty()) {
            System.out.println();
        }
    }

    void testOtherUsageNonLocal() {
        // Only writing to field should have no effect, field should be reported anyways
        otherUsageNoRead = "c";

        if (otherUsage.isEmpty() && otherUsageStatic.isEmpty()) {
            System.out.println();
        } 
    }

    // Ignore if field is accessed on other variable (i.e. not own field access)
    String otherFieldAccess = "other";

    void testOtherFieldAccess(Test other) {
        other.otherFieldAccess = "";

        if (otherFieldAccess.isEmpty()) {
            System.out.println();
        }
    }
}
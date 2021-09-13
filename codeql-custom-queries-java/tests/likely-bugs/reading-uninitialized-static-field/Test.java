class Test {
    static String s;
    static int i;
    static int i2;
    static {
        System.out.println(s);
        // Compound assignment first reads (default) value
        i += 1;
        // Unary assign first reads (default) value
        i2++;
    }

    static void nonInitializingMethod() {
        // Does not perform an assignment on uninitialized field
        System.out.println(s);
    }

    static {
        nonInitializingMethod();
        System.out.println(s);
    }

    // Should only cover static fields, not instance fields
    String instanceField;
    {
        System.out.println(instanceField);
    }

    static String nativelyInitialized;
    static native void initializeFieldsNative();

    static {
        // Bad: Occurs before initialization method call
        System.out.println(nativelyInitialized);

        initializeFieldsNative();
        System.out.println(nativelyInitialized);
    }

    static String initialized;
    static void initializeFields() {
        initialized = "";
    }

    static {
        // Bad: Occurs before initialization method call
        System.out.println(initialized); // TODO: Missing, not sure why

        // Ignore if called method initializes field
        initializeFields();
        System.out.println(initialized);
    }

    static String directlyInitialized;
    static {
        // Bad: Occurs before initialization
        System.out.println(directlyInitialized);

        directlyInitialized = "";
        System.out.println(directlyInitialized);
    }

    // Ok: Uses compile time constant whose value is inlined during compilation
    static String fromConstant = Test.constant;
    static final String constant = "";
}
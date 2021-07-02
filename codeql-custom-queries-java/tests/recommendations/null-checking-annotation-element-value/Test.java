class Test {
    @interface MyAnnotation {
        String value();
        String[] array();
    }

    boolean testDirect(MyAnnotation a) {
        return a.value() == null || a.value() != null;
    }

    boolean testIndirect(MyAnnotation a) {
        String s = a.value();
        return s == null || s != null;
    }

    boolean testArray(MyAnnotation a) {
        // null check on array (instead of its elements)
        return a.array() == null;
    }

    boolean testArrayElement(MyAnnotation a) {
        return a.array()[0] == null || a.array()[1] != null;
    }

    boolean testArrayElementIndirect(MyAnnotation a) {
        String[] array = a.array();
        String s = array[0];
        return s == null || s != null; 
    }

    boolean testOverwriteVar(MyAnnotation a) {
        String s = "test";
        // Overwrite existing value
        s = a.value();
        return s == null;
    }

    boolean testGoodReassign(MyAnnotation a) {
        String s = a.value();
        System.out.println(s);
        s = null;
        return s == null;
    }

    boolean testGoodConditionalAssign(MyAnnotation a) {
        String s = null;
        if (a != null) {
            s = a.value();
        }
        // s might still be null
        return s != null;
    }

    boolean testGoodInstanceOf(MyAnnotation a) {
        Object o = a.value();
        // `instanceof` is only a non-null check; should not be reported
        return o instanceof String;
    }
}
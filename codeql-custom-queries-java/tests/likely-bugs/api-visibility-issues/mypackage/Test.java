package mypackage;

import java.util.List;

public class Test {
    private static class PrivateClass extends Exception {
    }

    // Bad, exposes through type variable bound
    public static class ExposingGeneric<T extends PrivateClass> {
    }

    // Bad, exposes through field type
    public PrivateClass exposingField;

    private Test() {
    }

    /*
     * Bad, constructor exposes through:
     * - type variable bound
     * - parameter type
     * - `throws` clause
     */
    public <T extends PrivateClass> Test(PrivateClass c) throws PrivateClass {
    }

    /*
     * Bad, method exposes through:
     * - type variable bound
     * - return type
     * - parameter type (but only `p1`)
     * - `throws` clause
     */
    public <T extends PrivateClass> PrivateClass exposingMethod(PrivateClass p1, T p2) throws PrivateClass {
        return null;
    }

    public static class InheritanceBase {
        public PrivateClass exposingField;

        public PrivateClass exposingMethod() {
            return null;
        }

        public PrivateClass otherExposingMethod() {
            return null;
        }

        // Should also be reported for InheritingExposing
        //   TODO: Currently not reported
        public static class NestedExposing {
            public PrivateClass exposingMethod() {
                return null;
            }
        }
    }

    // Bad, inherits all visibility issues
    public static class InheritingExposing extends InheritanceBase {
        public static class PublicClass extends PrivateClass {
        }

        // Correct, overrides method but uses publicly visible type
        @Override
        public PublicClass otherExposingMethod() {
            return null;
        }
    }

    // Bad, exposes type through various type usages
    public static <T extends PrivateClass & Runnable> void typeExposing(List<? extends PrivateClass> p1, List<? super PrivateClass> p2, PrivateClass[] p3, PrivateClass[][] p4, List<? extends List<? super PrivateClass>[]> p5) {
    }

    public static class Generic<T> {
        public T get() {
            return null;
        }
    }

    private static class PrivateGeneric extends Generic<PrivateClass> {
    }

    // Bad, inherits method `T get()` with T being PrivateClass
    public static class TransitivelyGenericExposing extends PrivateGeneric {
    }
}

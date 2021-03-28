public class Test {
    private static class BaseImplementation {
        protected void baseMethod() { }
        protected void overriddenBaseMethod() { }
        protected void visibilityIncreasedOverriddenBaseMethod() { }
    }

    private static class Implementation extends BaseImplementation {
        // Constructor is not inherited
        public Implementation() {
        }

        public static class Nested { }
        // package-private; not publicly visible
        static class NestedCorrect { }

        protected String f;
        // package-private; not publicly visible
        String fCorrect;

        protected void doSomething() { }
        // package-private; not publicly visible
        void doSomethingCorrect() { }

        // Should not be reported here but only for BaseImplementation since
        // visibility is not increased
        @Override
        protected void overriddenBaseMethod() { }

        // Should be reported here and for BaseImplementation since visibility
        // is increased from protected to public
        @Override
        public void visibilityIncreasedOverriddenBaseMethod() { }

        // Should also consider static methods
        protected static void staticMethod() { }
    }

    private interface Generic<T> {
        default void genericDoSomething() { }
    }

    // Bad, inherits implementation members
    public static class Public extends Implementation implements Generic<String> {
        // Shadows field from Implementation, but for now report Implementation field anyways
        protected String f;
    }

    public static abstract class PublicApi {
        public abstract void doSomething();
        abstract void internalMethod();
    }

    private static class ImplementationExtendingPublic extends PublicApi {
        // Correct, doSomething is defined in public interface
        @Override
        public void doSomething() { }

        // Bad, overrides internal method of publicly visible type and makes it public
        @Override
        protected void internalMethod() { }

        protected void doSomethingElse() { }
    }

    public static class PublicExtendingTransitivelyPublic extends ImplementationExtendingPublic {
        // Correct, is overridden in public class
        @Override
        protected void doSomethingElse() { }
    }

    private static class PrivateSimple {
        public void doSomething() { }
        public void doSomethingOverridden() { }
    }

    // Bad, inherits implemenation members
    public static class PublicSimple extends PrivateSimple {
        // Override inherited implementation method; subclasses of PublicSimple should
        // not report base method then
        @Override
        public void doSomethingOverridden() { }
    }

    // Bad, transitively (over public type) inherits implementation members
    // Report this as well in case PublicSimple is actually part of internal
    // implementation (e.g. indicated by documentation), but is for example
    // for backward compatibility public
    public static class PublicExtendingPublicSimple extends PublicSimple {
    }

    private static class PrivateExtendingPublicSimple extends PublicSimple {
    }

    // Bad, transitively (over private and public type) inherits implementation members
    public static class PublicTransitivelyExtendingPublicSimple extends PrivateExtendingPublicSimple {
    }
}

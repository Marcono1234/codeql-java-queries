import java.lang.annotation.*;

class Test {
    @Target(ElementType.METHOD)
    @Inherited
    @interface Bad { }

    @Inherited
    @interface GoodNoExplicitTarget { }

    @Target(ElementType.TYPE)
    @Inherited
    @interface GoodTypeTarget { }

    // TYPE_USE allows placing annotation on class declaration
    @Target(ElementType.TYPE_USE)
    @Inherited
    @interface GoodTypeUseTarget { }
}
import java.lang.annotation.*;

class Test {
    @interface Ann { }

    @interface Anns {
        Ann[] value();
    }

    // Already Repeatable
    @Repeatable(ContainingAnns.class)
    @interface GoodRepeatable { }

    @interface ContainingAnns {
        GoodRepeatable[] value();
    }

    @interface NonContaining {
        Ann[] value();

        // Has other elements; not suitable as containing annotation type
        String someOtherValue();
    }
}
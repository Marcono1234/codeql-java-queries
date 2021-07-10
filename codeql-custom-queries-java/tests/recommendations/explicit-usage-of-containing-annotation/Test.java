import java.lang.annotation.*;

class Test {
    @Repeatable(Markers.class)
    @interface Marker {
        String value();
    }

    @interface Markers {
        Marker[] value();
    }

    @Markers({
        @Marker("a"),
        @Marker("b")
    })
    String s;

    @Marker("a")
    @Marker("b")
    String repeated;

    // Cannot replace empty containing annotation
    @Markers({})
    String empty;

    @Repeatable(ContainingAdditional.class)
    @interface Ann {
        String value();
    }

    @interface ContainingAdditional {
        Ann[] value();
        // Has additional elements; omitting containing annotation could be a
        // behavior change
        int otherValue() default 1;
    }

    @ContainingAdditional({
        @Ann("a"),
        @Ann("b")
    })
    String additionalElement;
}
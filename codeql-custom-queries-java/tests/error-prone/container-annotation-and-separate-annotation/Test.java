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
    @Marker("c")
    String s;


    @interface Ann {
        String value();
    }

    @interface CustomContainer {
        Ann[] value();
    }

    // Don't report when annotation is not Repeatable
    @CustomContainer({
        @Ann("a"),
        @Ann("b")
    })
    @Ann("c")
    String customContainer;
}
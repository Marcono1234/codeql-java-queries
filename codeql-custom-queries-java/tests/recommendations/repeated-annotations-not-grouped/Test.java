import java.lang.annotation.*;

class Test {
    @Inherited
    @Repeatable(Markers.class)
    @interface Marker {
        Other[] other() default { };
    }

    @Inherited
    @interface Markers {
        Marker[] value();
    }

    @interface Other { }


    @Marker
    @Other
    @Marker
    String notGrouped;

    @Marker @Other @Marker
    String notGroupedSameLine;
    

    @Marker
    @Marker
    @Other
    String grouped;

    @Other @Marker @Marker
    String groupedSameLine;

    @Markers({
        @Marker,
        @Marker
    })
    @Other
    String groupedExplicitContainer;

    @Marker
    @Marker(other = @Other)
    @Marker
    String groupedNested;

    @Markers({
        @Marker,
        @Marker
    })
    static class Base { }

    // Verify that inherited Markers annotation is ignored
    @Other
    @Marker
    static class Sub extends Base { }
}
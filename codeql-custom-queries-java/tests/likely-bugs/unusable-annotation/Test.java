import java.lang.annotation.*;
import java.lang.reflect.*;

public class Test {
    // No target element types
    @Target({})
    @interface Unusable { }

    // Good: Is used by Container annotation below
    @Target({})
    @interface NestedSingle { }

    // Good: Is used by Container annotation below
    @Target({})
    @interface NestedArray { }

    @interface Container {
        NestedSingle single();
        NestedArray[] array();
    }
}
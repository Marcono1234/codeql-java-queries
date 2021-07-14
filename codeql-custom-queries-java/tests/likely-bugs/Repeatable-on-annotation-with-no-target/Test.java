import java.lang.annotation.*;
import java.lang.reflect.*;

public class Test {
    // @Repeatable is pointless because empty array is used for @Target
    @Repeatable(Container.class)
    @Target({})
    @interface Ann { }

    @Target({})
    @interface Container {
        Ann[] value();
    }
}
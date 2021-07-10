import java.lang.annotation.*;

public class Test {
    @Retention(RetentionPolicy.RUNTIME)
    @Repeatable(ContainingAnn.class)
    @interface Ann { }

    @Retention(RetentionPolicy.RUNTIME)
    @interface ContainingAnn { Ann[] value(); }

    void bad() {
        Test.class.getAnnotation(Ann.class);
        Test.class.getDeclaredAnnotation(Ann.class);
        Test.class.isAnnotationPresent(Ann.class);
    }

    @Retention(RetentionPolicy.RUNTIME)
    @interface NonRepeatableAnn { }

    void good() {
        Test.class.getAnnotationsByType(Ann.class);
        Test.class.getDeclaredAnnotationsByType(Ann.class);

        Test.class.getAnnotation(NonRepeatableAnn.class);
    }
}
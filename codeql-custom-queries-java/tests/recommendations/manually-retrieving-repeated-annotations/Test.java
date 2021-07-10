import java.lang.annotation.*;

class Test {
    @Retention(RetentionPolicy.RUNTIME)
    @Repeatable(ContainingAnn.class)
    @interface Ann { }

    @Retention(RetentionPolicy.RUNTIME)
    @interface ContainingAnn {
        Ann[] value();
    }

    @Retention(RetentionPolicy.RUNTIME)
    @Repeatable(NestedContainingAnn1.class)
    @interface NestedAnn { }

    @Retention(RetentionPolicy.RUNTIME)
    // Containing annotation type is repeatable itself
    @Repeatable(NestedContainingAnn2.class)
    @interface NestedContainingAnn1 {
        NestedAnn[] value();
    }

    @Retention(RetentionPolicy.RUNTIME)
    @interface NestedContainingAnn2 {
        NestedContainingAnn1[] value();
    }

    void bad() {
        Test.class.getAnnotation(ContainingAnn.class);
        Test.class.getAnnotationsByType(ContainingAnn.class);
        Test.class.getDeclaredAnnotation(ContainingAnn.class);
        Test.class.getDeclaredAnnotationsByType(ContainingAnn.class);

        // Looking up containing annotation type which is itself repeatable, but
        // using methods which do not support Repeatable annotation
        Test.class.getAnnotation(NestedContainingAnn1.class);
        Test.class.getDeclaredAnnotation(NestedContainingAnn1.class);
    }

    @Retention(RetentionPolicy.RUNTIME)
    @interface NotContainingAnn {
        Ann[] value();
    }

    @Retention(RetentionPolicy.RUNTIME)
    @Repeatable(AdditionalContainingAnn.class)
    @interface AdditionalAnn { }

    @Retention(RetentionPolicy.RUNTIME)
    @interface AdditionalContainingAnn {
        AdditionalAnn[] value();

        // Has additional element
        int other() default 1;
    }

    void good() {
        Test.class.getAnnotationsByType(Ann.class);
        Test.class.getDeclaredAnnotationsByType(Ann.class);

        // Not retrieving container annotation
        Test.class.getAnnotation(Ann.class);
        Test.class.getDeclaredAnnotation(Ann.class);

        // Not the annotation type refered to by @Repeatable
        Test.class.getAnnotation(NotContainingAnn.class);

        // Containing annotation type has additional elements
        Test.class.getAnnotation(AdditionalContainingAnn.class);

        // Looking up containing annotation type which is itself repeatable, but
        // using methods which support Repeatable annotation
        Test.class.getAnnotationsByType(NestedContainingAnn1.class);
        Test.class.getDeclaredAnnotationsByType(NestedContainingAnn1.class);
    }
}
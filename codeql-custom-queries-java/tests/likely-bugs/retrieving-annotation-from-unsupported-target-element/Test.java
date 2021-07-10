import java.lang.annotation.*;
import java.lang.reflect.*;

public class Test {
    @Target(ElementType.CONSTRUCTOR)
    @Retention(RetentionPolicy.RUNTIME)
    @interface AnnConstructor { }

    @Target(ElementType.FIELD)
    @Retention(RetentionPolicy.RUNTIME)
    @interface AnnField { }

    @Target(ElementType.METHOD)
    @Retention(RetentionPolicy.RUNTIME)
    @interface AnnMethod { }

    @Target(ElementType.MODULE)
    @Retention(RetentionPolicy.RUNTIME)
    @interface AnnModule { }

    @Target(ElementType.PACKAGE)
    @Retention(RetentionPolicy.RUNTIME)
    @interface AnnPackage { }

    @Target(ElementType.PARAMETER)
    @Retention(RetentionPolicy.RUNTIME)
    @interface AnnParameter { }

    @Target(ElementType.RECORD_COMPONENT)
    @Retention(RetentionPolicy.RUNTIME)
    @interface AnnRecordComponent { }

    @Target(ElementType.TYPE)
    @Retention(RetentionPolicy.RUNTIME)
    @interface AnnType { }

    @Target(ElementType.TYPE_USE)
    @Retention(RetentionPolicy.RUNTIME)
    @interface AnnTypeUse { }

    void bad() throws Exception {
        Test.class.getAnnotation(AnnField.class);

        Constructor c = null;
        c.getAnnotation(AnnMethod.class);

        Executable e = null;
        e.getAnnotation(AnnTypeUse.class);

        Field f = null;
        f.getAnnotation(AnnParameter.class);

        Method m = null;
        m.getAnnotation(AnnConstructor.class);

        Module module = null;
        module.getAnnotation(AnnType.class);

        Package p = null;
        p.getAnnotation(AnnType.class);

        Parameter param = null;
        param.getAnnotation(AnnField.class);

        RecordComponent r = null;
        r.getAnnotation(AnnField.class);
    }

    void good() throws Exception {
        Test.class.getAnnotation(AnnType.class);
        Test.class.getAnnotation(AnnTypeUse.class);

        Constructor c = null;
        c.getAnnotation(AnnConstructor.class);

        Executable e = null;
        e.getAnnotation(AnnConstructor.class);
        e.getAnnotation(AnnMethod.class);

        Field f = null;
        f.getAnnotation(AnnField.class);

        Method m = null;
        m.getAnnotation(AnnMethod.class);

        Module module = null;
        module.getAnnotation(AnnModule.class);

        Package p = null;
        p.getAnnotation(AnnPackage.class);

        Parameter param = null;
        param.getAnnotation(AnnParameter.class);

        RecordComponent r = null;
        r.getAnnotation(AnnRecordComponent.class);
    }
}
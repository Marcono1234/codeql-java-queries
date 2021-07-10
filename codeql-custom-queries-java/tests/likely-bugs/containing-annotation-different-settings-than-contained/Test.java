import java.lang.annotation.*;

class Test {
    @Repeatable(ContainingDocumented.class)
    @interface AnnNotDocumented { }

    // Marked as Documented, but contained is not
    @Documented
    @interface ContainingDocumented { AnnNotDocumented[] value(); }

    /* ---------------------------------- */

    @Repeatable(ContainingInherited.class)
    @interface AnnNotInherited { }

    // Marked as Inherited, but contained is not
    @Inherited
    @interface ContainingInherited { AnnNotInherited[] value(); }

    /* ---------------------------------- */

    @Repeatable(ContainingNoTarget.class)
    // Note: Need to list all targets here explicitly because contained annotation must have at
    // least the same targets as containing annotation; but that one does not have an explicit
    // target for this test so its targets are (nearly) all values
    @Target({
        ElementType.ANNOTATION_TYPE,
        ElementType.CONSTRUCTOR,
        ElementType.FIELD,
        ElementType.LOCAL_VARIABLE,
        ElementType.METHOD,
        ElementType.MODULE,
        ElementType.PACKAGE,
        ElementType.PARAMETER,
        ElementType.TYPE,
        ElementType.TYPE_PARAMETER,
        ElementType.TYPE_USE
    })
    @interface AnnTarget { }

    // Specifies no Target
    @interface ContainingNoTarget { AnnTarget[] value(); }

    /* ---------------------------------- */

    @Repeatable(ContainingTarget.class)
    @interface AnnNoTarget { }

    // Specifies Target, but contained does not
    @Target(ElementType.METHOD)
    @interface ContainingTarget { AnnNoTarget[] value(); }

    /* ---------------------------------- */

    @Repeatable(ContainingTargetMismatch.class)
    @Target({ ElementType.METHOD, ElementType.PARAMETER })
    @interface AnnTargetMismatch { }

    // Specifies different Target
    @Target(ElementType.METHOD)
    @interface ContainingTargetMismatch { AnnTargetMismatch[] value(); }

    /* ---------------------------------- */

    @Repeatable(ContainingNoRetention.class)
    @Retention(RetentionPolicy.SOURCE)
    @interface AnnRetention { }

    // Specifies no Retention
    @interface ContainingNoRetention { AnnRetention[] value(); }

    /* ---------------------------------- */

    @Repeatable(ContainingRetention.class)
    @interface AnnNoRetention { }

    // Specifies Retention, but contained does not
    @Retention(RetentionPolicy.RUNTIME)
    @interface ContainingRetention { AnnNoRetention[] value(); }

    /* ---------------------------------- */

    @Repeatable(ContainingRetentionMismatch.class)
    @Retention(RetentionPolicy.SOURCE)
    @interface AnnRetentionMismatch { }

    // Specifies different Retention
    @Retention(RetentionPolicy.RUNTIME)
    @interface ContainingRetentionMismatch { AnnRetentionMismatch[] value(); }
}
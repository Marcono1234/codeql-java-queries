import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import java.util.List;

class Test {
    @Target({
        ElementType.ANNOTATION_TYPE,
        ElementType.CONSTRUCTOR,
        ElementType.FIELD,
        ElementType.LOCAL_VARIABLE,
        ElementType.METHOD,
        ElementType.MODULE,
        ElementType.PACKAGE,
        ElementType.PARAMETER,
        ElementType.RECORD_COMPONENT,
        ElementType.TYPE,
        ElementType.TYPE_PARAMETER,
        ElementType.TYPE_USE
    })
    @Retention(RetentionPolicy.SOURCE)
    @interface NotNull {
    }

    @NotNull
    int f;

    @NotNull
    public int doSomething(@NotNull short s) {
        @NotNull
        boolean localVar = true;
        return 0;
    }

    List<@NotNull byte[]> f2;

    record MyRecord(@NotNull long l) { }

    // Correct usage
    @NotNull
    public String doSomething(@NotNull Integer i) {
        return "";
    }

    // Annotating method with `void` return type should not be reported
    @NotNull
    public <@NotNull T> void doSomething() {
    }
}
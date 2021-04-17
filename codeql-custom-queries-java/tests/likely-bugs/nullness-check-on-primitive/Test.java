import java.util.Objects;
import java.util.function.IntPredicate;
import java.util.function.Predicate;

class Test {
    void test(int i) {
        Objects.requireNonNull(i);
        Objects.requireNonNull(i, "test");
        Objects.requireNonNull(i, () -> "test");
        Objects.requireNonNullElse(i, 1);
        Objects.requireNonNullElseGet(i, () -> 1);

        IntPredicate p1 = value -> Objects.nonNull(value);
        // TODO: Not detected due to https://github.com/github/codeql/issues/5706
        IntPredicate p2 = Objects::isNull;
    }

    boolean test2(int i) {
        return true;
    }

    void testCorrect(Integer i) {
        Objects.requireNonNull(i);
        Objects.requireNonNullElse(i, 1);
        Predicate<Long> p1 = value -> Objects.nonNull(value);
        Predicate<Integer> p2 = Objects::isNull;
    }
}
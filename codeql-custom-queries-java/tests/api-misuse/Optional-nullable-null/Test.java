import java.util.Optional;
import java.util.OptionalInt;

class Test {
    void test() {
        Optional.ofNullable(null);
    }

    void testCorrect() {
        Optional.ofNullable("not null");
        OptionalInt.of(0); // this is not the same as an empty optional
    }
}
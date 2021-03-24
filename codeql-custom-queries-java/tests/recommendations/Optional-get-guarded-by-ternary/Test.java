import java.util.Optional;
import java.util.OptionalDouble;
import java.util.OptionalInt;
import java.util.OptionalLong;

class Test {
    void test(Optional<String> opt) {
        Object r;
        r = opt.isPresent() ? opt.get() : "test";
        r = opt.isPresent() ? opt.orElseThrow() : "test";
        r = opt.isEmpty() ? "test" : opt.get();
        r = opt.isEmpty() ? "test" : opt.orElseThrow();
    }

    void test(OptionalDouble opt) {
        double r;
        r = opt.isPresent() ? opt.getAsDouble() : 1d;
        r = opt.isPresent() ? opt.orElseThrow() : 1d;
        r = opt.isEmpty() ? 1d : opt.getAsDouble();
        r = opt.isEmpty() ? 1d : opt.orElseThrow();
    }

    void test(OptionalInt opt) {
        int r;
        r = opt.isPresent() ? opt.getAsInt() : 1;
        r = opt.isPresent() ? opt.orElseThrow() : 1;
        r = opt.isEmpty() ? 1 : opt.getAsInt();
        r = opt.isEmpty() ? 1 : opt.orElseThrow();
    }

    void test(OptionalLong opt) {
        long r;
        r = opt.isPresent() ? opt.getAsLong() : 1L;
        r = opt.isPresent() ? opt.orElseThrow() : 1L;
        r = opt.isEmpty() ? 1L : opt.getAsLong();
        r = opt.isEmpty() ? 1L : opt.orElseThrow();
    }

    void testCorrect(Optional<String> opt, Optional<String> opt2) {
        Object r;
        r = opt.isPresent() ? opt2.get() : "test"; // different variable
        r = opt.isPresent() ? "present" : "test";
    }

    void test(OptionalDouble opt, OptionalDouble opt2) {
        double r;
        r = opt.isPresent() ? opt2.getAsDouble() : 1d; // different variable
        r = opt.isPresent() ? 2d : 1d;
    }

    void test(OptionalInt opt, OptionalInt opt2) {
        int r;
        r = opt.isPresent() ? opt2.getAsInt() : 1; // different variable
        r = opt.isPresent() ? 2 : 1;
    }

    void test(OptionalLong opt, OptionalLong opt2) {
        long r;
        r = opt.isPresent() ? opt2.getAsLong() : 1L; // different variable
        r = opt.isPresent() ? 2L : 1L;
    }
}
import java.io.IOException;
import java.util.function.Function;
import java.util.function.Supplier;
import java.util.Optional;

class Test {
    Exception factoryBad() {
        throw new Exception();
    }

    // Throws UnsupportedOperationException, but also has
    // other `throw` statement
    Exception factoryBadUnsupported(boolean b) {
        if (b) {
            throw new UnsupportedOperationException();
        }
        throw new RuntimeException();
    }

    Exception factoryBadMultiple(boolean b) {
        if (b) {
            throw new Error();
        } else {
            throw new RuntimeException();
        }
    }

    // `throws` clause might intended be for argument validation,
    // however thrown exception type does not match
    IllegalStateException factoryBadThrows(String m) throws IllegalArgumentException {
        throw new IllegalStateException();
    }

    void lambdaBad(boolean b) {
        Supplier<? extends Throwable> factory = () -> {
            throw new RuntimeException();
        };

        factory = () -> {
            if (b) {
                throw new Error();
            } else {
                throw new RuntimeException();
            }
        };

        Function<String, IllegalArgumentException> factory2 = message -> {
            throw new IllegalArgumentException(message);
        };

        Optional<String> optional = Optional.of("test");
        // Argument of orElseThrow is supposed to return exception, not throw it
        optional.orElseThrow​(() -> {
            throw new IllegalStateException();
        });
    }

    IOException factoryCorrect(String s) {
        return new IOException(s);
    }

    Exception factoryCorrectUnsupported() {
        // Assume that the intention is that factory method is not supported
        throw new UnsupportedOperationException();
    }

    Exception factoryCorrect(boolean b) {
        if (b) {
            // Exception as part of argument validation is allowed
            throw new IllegalArgumentException("Wrong argument");
        }
        return new Exception();
    }

    IllegalStateException factoryCorrectThrows(String m) throws IllegalArgumentException {
        if (m.isEmpty()) {
            throw new IllegalArgumentException();
        }
        return new IllegalStateException(m);
    }

    IllegalArgumentException factoryCorrectThrows() throws IllegalArgumentException {
        // Exception matches type of throws clause, likely intended
        // to throw exception
        throw new IllegalArgumentException();
    }

    void lambdaCorrect(boolean b) {
        Supplier<? extends Throwable> factory = () -> {
            return new Exception();
        };

        factory = () -> {
            if (b) {
                // Exception as part of argument validation is allowed
                throw new IllegalArgumentException("Wrong argument");
            }
            return new Exception();
        };

        Function<String, IllegalArgumentException> factory2 = message -> {
            return new IllegalArgumentException(message);
        };

        Optional<String> optional = Optional.of("test");
        optional.orElseThrow​(() -> new IllegalStateException());
        optional.orElseThrow​(IllegalArgumentException::new);
    }
}
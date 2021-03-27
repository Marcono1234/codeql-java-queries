import java.security.NoSuchAlgorithmException;

class Test {
    void throwingMethod() throws Exception { }
    void specificThrowingMethod() throws NoSuchAlgorithmException { }

    void test() throws Exception {
        try {
            throwingMethod();
        }
        // Should not be reported; RuntimeException is not a supertype
        catch (RuntimeException e) {
        }
        catch (NoSuchAlgorithmException e) {
            // Not properly handled
        }
        // Should not be reported; previous catch already caught exception
        catch (Exception e) {
        }

        try {
            throwingMethod();
        } catch (NoSuchAlgorithmException | IllegalStateException e) {
            // Not properly handled
        }

        try {
            specificThrowingMethod();
        }
        // Should not be reported; RuntimeException is not a supertype
        catch (RuntimeException e) {
        }
        catch (Exception e) {
            // Not properly handled
        }
    }

    void testCorrect() throws Exception {
        try {
            throwingMethod();
        } catch (NoSuchAlgorithmException e) {
            // Correct, rethrows exception
            throw e;
        }

        try {
            try {
                specificThrowingMethod();
            } catch (Exception e) {
                throw e;
            }
        }
        // Nested try handles exception
        catch (Exception e) {
        }

        try {
            specificThrowingMethod();
        } catch (Exception e) {
            // Correct, rethrows exception
            throw e;
        }
    }
}
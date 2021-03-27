import java.security.GeneralSecurityException;
import javax.crypto.AEADBadTagException;
import javax.crypto.BadPaddingException;

class Test {
    void throwingMethod() throws Exception { }
    void specificThrowingMethod() throws BadPaddingException { }
    void subtypeThrowingMethod() throws AEADBadTagException { }

    void test() throws Exception {
        try {
            throwingMethod();
        }
        // Should not be reported; RuntimeException is not a supertype
        catch (RuntimeException e) {
            throw e;
        }
        // Should not be reported; AEADBadTagException is subtype for which padding oracle is not possible
        catch (AEADBadTagException e) {
            throw e;
        }
        catch (BadPaddingException e) {
            // Not properly handled, adversary might see exception
            throw e;
        }
        // Should not be reported; previous catch already caught exception
        catch (Exception e) {
            throw e;
        }

        try {
            throwingMethod();
        } catch (BadPaddingException | IllegalStateException e) {
            // Not properly handled, adversary might see exception
            throw e;
        }

        try {
            specificThrowingMethod();
        }
        // Should not be reported; RuntimeException is not a supertype
        catch (RuntimeException e) {
            throw e;
        }
        catch (Exception e) {
            // Not properly handled, adversary might see exception
            throw e;
        }
    }

    // `throws Exception` hides that BadPaddingException is thrown
    void testThrowsHiding() throws Exception {
        specificThrowingMethod();
    }

    // `throws` hides that BadPaddingException is thrown
    void testThrowsHiding2() throws GeneralSecurityException, AEADBadTagException {
        specificThrowingMethod();
    }

    boolean testCorrect() throws Exception {
        try {
            throwingMethod();
        } catch (BadPaddingException e) {
            // Correct (?), does not indicate that an exception occurred
        }

        try {
            subtypeThrowingMethod();
        }
        // Should not report this; thrown exception is AEADBadTagException which is
        // not vulnerable to padding oracle attacks
        catch (BadPaddingException e) {
            throw e;
        }

        try {
            try {
                specificThrowingMethod();
            } catch (Exception e) {
                // Correct, does not indicate that an exception occurred
                return false;
            }
        }
        // Nested try handles exception
        catch (Exception e) {
            throw e;
        }

        try {
            specificThrowingMethod();
        } catch (Exception e) {
            // Correct, does not indicate that an exception occurred
            return false;
        }

        return false;
    }

    // `throws` indicates that BadPaddingException is thrown
    void testThrowsCorrect() throws BadPaddingException {
        specificThrowingMethod();
    }
}
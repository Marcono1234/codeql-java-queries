import java.io.Closeable;
import java.io.FileOutputStream;

class Test {
    void test(Closeable c) throws Exception {
        try {
        } catch (Exception e) {
        }

        try {
            // Only contains block and empty statements
            {
                {
                    ;
                    ;
                    {}
                }
            }
        } finally {
        }

        // Only has a single resource, should instead explicitly call `close()`
        try (c) {
        }
    }

    void testCorrect(Closeable c1, Closeable c2) throws Exception {
        try {
            System.lineSeparator();
        } catch (Exception e) {
        }

        try {
            {
                System.lineSeparator();
            }
        } catch (Exception e) {
        }

        try {
            ;
            System.lineSeparator();
        } catch (Exception e) {
        }

        // Using more than one resource should not be reported
        try (c1; c2) {
        }

        // Resource declaration should not be reported
        try (Closeable c = new FileOutputStream("file")) {
        }
    }
}
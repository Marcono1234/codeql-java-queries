import java.io.IOException;

class Test {
    interface Bad1 {
        // Wrong return types
        void clone();
        Object finalize();
    }

    interface Bad2 {
        // Wrong return types
        int clone();
        boolean finalize();
    }

    interface Bad3 {
        // Wrong exception type
        Object clone() throws Exception;
    }

    interface Bad4 {
        // Default methods with incompatible signature
        default Object clone() throws Exception {
            return null;
        }

        default boolean finalize() {
            return false;
        }
    }

    interface Good1 {
        // Different signatures
        void clone(int i);
        boolean finalize(String s);
    }

    interface Good2 {
        // Correct return types
        Object clone();
        void finalize();
    }

    interface Good3 {
        // Correct exception types
        Object clone() throws CloneNotSupportedException;
        void finalize() throws Throwable;
    }

    interface Good4 {
        // Runtime exception types
        Object clone() throws IllegalArgumentException;
        // Exception subtypes
        void finalize() throws CloneNotSupportedException, IOException;
    }

    interface Good5 {
        // Subtype of return type
        Number clone();
    }

    interface Good6 {
        // Private methods
        private void clone() {
        }

        private String finalize() {
            return null;
        }
    }

    interface Good7 {
        // Static methods
        static void clone() {
        }

        static String finalize() {
            return null;
        }
    }
}

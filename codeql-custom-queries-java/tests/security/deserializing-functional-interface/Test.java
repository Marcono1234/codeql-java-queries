import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.Serializable;
import java.util.function.Supplier;

class Test {
    static class FieldDeserialization<T> implements Serializable {
        // static fields should be ignored
        public static final Supplier<String> EMPTY_STRING_SUPPLIER = () -> "";

        // Functional interface instance is deserialized
        private final Supplier<T> supplier;
        private T value;

        public FieldDeserialization(Supplier<T> supplier) {
            this.supplier = supplier;
        }

        public T getValue() {
            if (value == null) {
                value = supplier.get();
            }
            return value;
        }
    }

    static class CustomDeserialization<T> implements Serializable {
        private transient Supplier<T> supplier;
        private transient T value;

        public CustomDeserialization(Supplier<T> supplier) {
            this.supplier = supplier;
        }

        public T getValue() {
            if (value == null) {
                value = supplier.get();
            }
            return value;
        }

        @SuppressWarnings("unchecked")
        private void readObject(ObjectInputStream in) throws IOException, ClassNotFoundException {
            // Manually deserializes functional interface instance
            supplier = (Supplier<T>) in.readObject();
        }
    }

    static class CustomSupplier implements Supplier<String> {
        @Override
        public String get() {
            return "test";
        }
    }

    static class SafeDeserialization implements Serializable {
        // Safe, specific class is used
        private final CustomSupplier supplier;
        private String value;

        public SafeDeserialization(CustomSupplier supplier) {
            this.supplier = supplier;
        }

        public String getValue() {
            if (value == null) {
                value = supplier.get();
            }
            return value;
        }
    }
}
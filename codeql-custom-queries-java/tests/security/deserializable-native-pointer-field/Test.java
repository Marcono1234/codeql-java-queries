import java.io.Serializable;

class Test {
    private static native long allocate(int i);
    private static native void free(long l);

    static class Base {
        // Should not be reported, Base is not Serializable
        private long address;

        @Override
        protected void finalize() throws Throwable {
            super.finalize();
            free(address);
        }
    }

    static class Subclass extends Base implements Serializable {
        private long otherAddress;
        private long pointer = allocate(10);

        @Override
        protected void finalize() throws Throwable {
            super.finalize();
            free(otherAddress);
        }

        // Should ignore static and transient fields
        private static long staticPointer = allocate(10);
        private transient long transientPointer = allocate(10);

        // Should ignore methods whose values are not pointers
        private long nanos = System.nanoTime();
        private long millis = System.currentTimeMillis();

        private long sleepMillis = 0;
        private void sleep() throws Exception {
            Thread.sleep(sleepMillis);
        }

        private static native int otherNativeMethod();
        private static native void otherNativeMethod(int i);

        // otherNativeMethod returns `int`, should be ignored
        private long other = otherNativeMethod();
        // Field has type `int`, probably not a pointer
        private int other2;
        {
            otherNativeMethod(other2);
        }
    }
}
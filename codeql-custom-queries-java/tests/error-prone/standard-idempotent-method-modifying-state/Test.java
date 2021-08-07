class Test {
    static class Bad implements Comparable<Bad> {
        public int i;
        public boolean b;
        public String s;
        public int[] arr;

        @Override
        public int hashCode() {
            return i++;
        }

        @Override
        public boolean equals(Object obj) {
            if (obj == this) {
                return true;
            }
            if (!(obj instanceof Bad)) {
                return false;
            }

            Bad other = (Bad) obj;
            // Assigment instead of equality test
            return b = other.b;
        }

        @Override
        public String toString() {
            return s += "a";
        }

        @Override
        public int compareTo(Bad other) {
            return arr[0]++ + (arr[0] = 1);
        }
    }

    static class Good {
        String cachedToString;

        @Override
        public String toString() {
            // Caches result in field; should not be reported
            if (cachedToString == null) {
                cachedToString = "test";
            }

            return cachedToString;
        }
    }
}
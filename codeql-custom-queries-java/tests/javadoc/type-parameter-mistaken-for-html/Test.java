class Test {
    /**
     * List<String>
     * Map<K,V>
     * Map<K, V>
     * List<E extends Number>
     * List<>
     * List<?>
     * Map<?, ?>
     * Map<?,?>
     * Map<? extends Number, ? super String>
     * List<Map<K, List<E extends Nested>>>
     * new List<Integer>() {}
     */
    int bad1;

    /**
     * <pre>{@code
     * Code block
     * }</pre>
     * 
     * Outside of code block:
     * List<E>
     */
    int bad2;

    /**
     * {@code List<E>}
     * {@literal Map<K, ? extends List<String>}
     * {@link Map<K, V>}
     * {@linkplain List<E>}
     */
    int good1;

    /**
     * <pre>{@code
     * List<E>
     * }</pre>
     */
    int good2;

    /**
     * <CODE>Test</CODE>
     * This is <B>bold</B> text
     */
    int good3;

    /**
     * @param <T> the parameter
     */
    <T> void test() {}

    /*
     * Not Javadoc
     * List<E>
     */
    int good4;

    // Not Javadoc List<E>
    int good5;

    /**
     * No commented element
     * List<E>
     */
}

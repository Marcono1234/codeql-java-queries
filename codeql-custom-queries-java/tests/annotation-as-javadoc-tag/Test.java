/**
 * @Deprecated Incorrect usage
 */
public abstract class Test {
    /**
     * Will be treated as javadoc tag:
     * <pre>
     * @Override
     * public void test() {
     *   ...
     * }
     * </pre>
     */
    public abstract void test();

    /**
     * Correct usage:
     * <pre>
     * &#64;Override
     * public void testCorrect() {
     *   ...
     * }
     * </pre>
     * 
     * @deprecated Correct usage
     */
    public abstract void testCorrect();

    // This is necessary; otherwise CodeQL does not have annotation types (at least @Override)
    // in database
    @Deprecated
    @Override
    public String toString() {
        return "";
    }
}
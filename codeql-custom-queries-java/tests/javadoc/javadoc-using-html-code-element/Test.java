/**
 * <code>test</code>
 * <cOdE>test</CoDe>
 * <code></code>
 * 
 * Should not be reported:
 * <code>{test</code>
 * <code>test}</code>
 * <code><b>test</b></code>
 */
class Test {
    // Ignore non-javadoc comments
    /*
     * <code>test</code>
     */
    String f;

    // <code>test</code>
    String f2;

    // Ignore javadoc comments without documented element
    /**
     * <code>test</code>
     */
}
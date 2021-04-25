/**
 * Finds test methods whose `@Test` annotation is commented out. E.g.:
 * ```java
 * // @Test
 * public void testSomething() {
 *     ...
 * }
 * ```
 * Often unit tests frameworks provide annotations for disabling test methods,
 * e.g. JUnit 5 provides `@Disabled`. Such annotations should be preferred since
 * they make it more clear that a test is disabled. That test will appear in the
 * test summary as skipped test and often these annotations also allow specifying
 * a reason why the test has been disabled. E.g.:
 * ```java
 * @Disabled("Test is randomly failing, disabled for now")
 * @Test
 * public void testSomething() {
 *     ...
 * }
 * ```
 */

import java

from JavadocText commentText, Method testMethod
where
    // Note: This predicate might be an implementation detail, see https://github.com/github/codeql/issues/3695
    isEolComment(commentText.getJavadoc())
    // Comment matches '@Test' or '@Test(...)'
    and commentText.getText().regexpMatch("\\s*@Test(\\(.*\\))?\\s*")
    // And is placed above a method inside a test class
    and testMethod.getFile() = commentText.getLocation().getFile()
    and testMethod.getDeclaringType() instanceof TestClass
    and testMethod.getLocation().getStartLine() = commentText.getLocation().getEndLine() + 1
select commentText, "Instead of commenting out @Test annotation of $@ method, should use annotation for disabling test", testMethod, "this"

/**
 * Finds usages of the "double brace initialization pattern" which consists of
 * creating an anonymous class containing only an initializer block to ease
 * calling instance methods, e.g.:
 * ```
 * new ArrayList<String>() {
 *   {
 *      add("a");
 *      add("b");
 *   }
 * }
 * ```
 *
 * While this might look tempting, it has several disadvantages and often is
 * unnecessary because either the JDK or other common libraries provide simple
 * ways of constructing such objects, e.g. `java.util.List.of(...)` or
 * `com.google.common.collect.ImmutableList.builder()`.
 *
 * See also https://stackoverflow.com/a/27521360
 */

import java

from AnonymousClass c
where
    count(c.getAMethod()) = 1 // Only the initializer block
    and c.getAMethod() instanceof InitializerMethod
    and count (c.getAField()) = 0 // No declared fields
select c

/**
 * Finds classes which directly extend `java.lang.Throwable`.
 * The javadoc only describes the meaning for the subclasses:
 *   - java.lang.Error:
 *     > An Error is a subclass of Throwable that indicates serious problems that a reasonable application should not try to catch.
 *   - java.lang.Exception:
 *     > The class Exception and its subclasses are a form of Throwable that indicates conditions that a reasonable application might want to catch.
 *
 * It is not clear what the severity of a custom Throwable subclass is, or
 * how it should be handled. Exception classes should therefore rather extend
 * either Error or Exception instead of directly extending Throwable.
 */

import java

from Class c
where
    c.getASupertype() instanceof TypeThrowable
select c

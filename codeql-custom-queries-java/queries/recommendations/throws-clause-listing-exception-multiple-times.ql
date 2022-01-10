/**
 * Finds callables whose `throws` clause lists the same exception type multiple times.
 * Repeating the exception type does not add any value and might only confuse the user.
 * If the intention was to indicate that the exception type can be thrown in multiple
 * situations, then instead multiple `@throws` Javadoc tags for the same exception type
 * should be used in the documentation comment.
 */

import java

from Callable callable, Exception exception, RefType exceptionType
where
    callable.getAnException() = exception
    and exceptionType = exception.getType()
    /*
     * This check needs to consider the following issues:
     * - Duplicate exception type is modeled as single Exception with multiple locations
     *   https://github.com/github/codeql/issues/7309
     * - Exception can have multiple locations when class has multiple locations; work around
     *   this by verify that the absolute file paths match
     *   https://github.com/github/codeql/issues/5734
     * - Exception element also exists for thrown exceptions; work around this by checking `fromSource()`
     *   https://github.com/github/codeql/issues/5464
     */
    // Make sure there are at least two different locations
    and exists(Location location, Location otherLocation |
        location = exception.getLocation()
        and location.getFile().(CompilationUnit).fromSource()
        and otherLocation = exception.getLocation()
        and otherLocation.getFile().(CompilationUnit).fromSource()
        and location != otherLocation
        and location.getFile() = otherLocation.getFile()
    )
select callable, "Declares exception type " + exceptionType.getQualifiedName() + " multiple times in `throws` clause"

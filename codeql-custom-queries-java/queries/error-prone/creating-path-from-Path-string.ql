/**
 * Finds code which uses the string representation of `java.nio.file.Path` as path,
 * for example for methods taking a `String`, creating a `java.io.File` or for
 * resolving against another `java.nio.file.Path`.
 * 
 * A `Path` may not belong to the default file system, or to the same file system
 * as another `Path`; it might not even use the same path name separator (e.g. `/`).
 * Therefore converting it to a `String` and then using the path is error-prone.
 * 
 * Instead it might be safer to do the following:
 * - For the default file system: Call `Path.toFile()`
 * - For resolving against another `Path`: Call `Path.resolve(Path)`
 * 
 * If the file systems of the paths do not match, an exception is thrown which
 * might prevent any incorrect behavior.
 * 
 * @kind problem
 */

import java
import semmle.code.java.security.PathCreation
import semmle.code.java.dataflow.DataFlow

// TODO: Maybe also consider File string representation flow to creation of Path;
// though should only consider Path instance methods and FileSystem.getPath calls
// because otherwise sink uses default file system, which is correct

abstract class PathStringSource extends Expr {
    abstract Expr getPathExpr();
}

class PathToStringCall extends PathStringSource, MethodAccess {
    PathToStringCall() {
        getMethod() instanceof ToStringMethod
        // Don't consider subtypes; for them using their string representation might be fine
        and getReceiverType() instanceof TypePath
    }

    override
    Expr getPathExpr() {
        result = getQualifier()
    }
}

class PathStringConcat extends PathStringSource {
    PathStringConcat() {
        // Don't consider subtypes; for them using their string representation might be fine
        getType() instanceof TypePath
        and (
            any(AddExpr e).getAnOperand() = this
            or any(AssignAddExpr e).getRhs() = this
        )
    }

    override
    Expr getPathExpr() {
        result = this
    }
}

/**
 * `java.nio.file.Path` method which returns a `Path` representing only a single
 * path element.
 */
class PathGetSingleElementMethod extends Method {
    PathGetSingleElementMethod() {
        getDeclaringType().getASourceSupertype*() instanceof TypePath
        and hasStringSignature([
            "getFileName()",
            "getName(int)"
        ])
    }
}

from PathStringSource stringPathSource, PathCreation pathCreation
where
    DataFlow::localExprFlow(stringPathSource, pathCreation.getAnInput())
    // Ignore if string is obtained from a single path element because then string
    // won't contain separator and usage across different file systems might be intended
    and not exists(MethodAccess singlePathElementCall |
        singlePathElementCall.getMethod() instanceof PathGetSingleElementMethod
        and DataFlow::localExprFlow(singlePathElementCall, stringPathSource.getPathExpr())
    )
select stringPathSource, "String representation of Path is used $@ to create a file path", pathCreation, "here"

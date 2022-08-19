/**
 * Finds code which creates a ZIP or JAR entry name from the string repesentation
 * of a file path. The ZIP specification requires that `/` is used, and that no
 * drive letter or leading slash is used. However, on Windows the file system
 * separator is `\`. Therefore using a Windows file path as ZIP entry name would
 * create a malformed name. Similarly the string representation of `java.nio.file.Path`
 * should not be used either because the file system it belongs to might use a
 * completely different path name separator.
 * 
 * The following methods can be used for creating a ZIP entry name:
 * ```java
 * public static String fileToZipEntryName(File file) {
 *     StringBuilder sb = new StringBuilder();
 *     while (true) {
 *         sb.insert(0, file.getName());
 *         file = file.getParentFile();
 * 
 *         // Return if no parent or parent has empty name and has itself no parent
 *         if (file == null || (file.getParent() == null && file.getName().isEmpty())) {
 *             return sb.toString();
 *         } else {
 *             sb.insert(0, '/');
 *         }
 *    }
 * }
 * 
 * // Note: Does not handle empty path elements correctly, in case
 * // they are supported by the file system `path` belongs to
 * public static String pathToZipEntryName(Path path) {
 *     // Uses java.util.StringJoiner
 *     StringJoiner stringJoiner = new StringJoiner("/");
 *     for (int i = 0; i < path.getNameCount(); i++) {
 *         stringJoiner.add(path.getName(i).toString());
 *     }
 *
 *     return stringJoiner.toString();
 * }
 * ```
 * 
 * See [ZIP file specification](https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT)
 * section 4.4.17.
 * 
 * @kind problem
 */

/*
 * Note: The opposite, i.e. using a ZIP entry name as file path, is error-prone as well, however
 * both Windows and Unix accept forward slashes so it would not cause an issue for them
 * (except for the Zip Slip vulnerability, but that is covered by a CodeQL query).
 * For other custom NIO file systems it might be an issue, but they are probably rather rare.
 */

import java
import semmle.code.java.dataflow.DataFlow

abstract class PathStringSource extends Expr {
    abstract Expr getReceiverExpr();
}

class PathToStringCall extends PathStringSource, MethodAccess {
    PathToStringCall() {
        getMethod() instanceof ToStringMethod
        // Don't consider subtypes; for them using their string representation might be fine
        and getReceiverType() instanceof TypePath
    }

    override
    Expr getReceiverExpr() {
        result = getQualifier()
    }
}

class FileStringCall extends PathStringSource, MethodAccess {
    FileStringCall() {
        getReceiverType().getASourceSupertype*() instanceof TypeFile
        and getMethod().hasStringSignature([
            "getAbsolutePath()",
            "getCanonicalPath()",
            // Note: Don't cover `getName()` because it only returns the last path element
            "getParent()",
            "getPath()",
            "toString()"
        ])
    }

    override
    Expr getReceiverExpr() {
        result = getQualifier()
    }
}

/**
 * Access of results from `File.list(...)` call.
 */
class FileListCallArrayAccess extends PathStringSource, ArrayAccess {
    Expr receiverExpr;

    FileListCallArrayAccess() {
        exists(MethodAccess listCall |
            receiverExpr = listCall.getQualifier()
            and listCall.getReceiverType().getASourceSupertype*() instanceof TypeFile
            and listCall.getMethod().hasName("list")
        |
            DataFlow::localExprFlow(listCall, this.getArray())
        )
    }

    override
    Expr getReceiverExpr() {
        result = receiverExpr
    }
}

class PathStringConcat extends PathStringSource {
    PathStringConcat() {
        (
            // Don't consider subtypes; for them using their string representation might be fine
            getType() instanceof TypePath
            or getType().(RefType).getASourceSupertype*() instanceof TypeFile
        )
        and (
            any(AddExpr e).getAnOperand() = this
            or any(AssignAddExpr e).getRhs() = this
        )
    }

    override
    Expr getReceiverExpr() {
        result = this
    }
}

class TypeZipEntry extends Class {
    TypeZipEntry() {
        hasQualifiedName("java.util.zip", "ZipEntry")
    }
}

class TypeJarEntry extends Class {
    TypeJarEntry() {
        hasQualifiedName("java.util.jar", "JarEntry")
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
            // Note: Don't consider getRoot() because its string representation is not
            // a suitable ZIP entry name
        ])
    }
}

from PathStringSource stringPathSource, ClassInstanceExpr newZipEntryExpr
where
    (
        // Only consider ZipEntry and JarEntry, ignore custom subclasses
        newZipEntryExpr.getConstructedType() instanceof TypeZipEntry
        or newZipEntryExpr.getConstructedType() instanceof TypeJarEntry
    )
    and DataFlow::localExprFlow(stringPathSource, newZipEntryExpr.getAnArgument())
    // Ignore if string is obtained from a single path element because then string
    // won't contain separator
    and not stringPathSource.getReceiverExpr().(MethodAccess).getMethod() instanceof PathGetSingleElementMethod
select newZipEntryExpr, "Creates ZIP entry with name based on $@ string representation of path", stringPathSource, "this"

/**
 * Finds C-style array declarations, i.e. the brackets are placed behind
 * the variable name or for a method return type behind the parameter list.
 * E.g.:
 * ```
 * // C-style array declaration:
 * int a[];
 * // Recommended (brackets behind component type):
 * int[] a;
 * ```
 * C-style array declarations can be confusing because the brackets logically
 * belong to the component type and not to the name of the variable, so this
 * style should therefore be avoided.
 */

import java

// See https://docs.oracle.com/javase/specs/jls/se14/html/jls-10.html#jls-10.2
class CStyleArrayParent extends Top {
    CStyleArrayParent() {
        this instanceof FieldDeclaration
        or this instanceof LocalVariableDecl
        or this instanceof Parameter
        or this instanceof Method // TODO: Not tested
    }
}

/*
 * Finds an array access and then makes sure that there is no
 * other element (except type accesses) between the array access
 * start and the array access end in the source
 * If there is another element, then the array access is C-style
 */
from ArrayTypeAccess arrayTypeAccess, CStyleArrayParent parent, Location location, Top other, Location otherLocation
where
    arrayTypeAccess != other
    and parent = arrayTypeAccess.getParent()
    and not other instanceof TypeAccess
    and not other instanceof ArrayTypeAccess
    and not other instanceof WildcardTypeAccess
    and location = arrayTypeAccess.getLocation()
    and otherLocation = other.getLocation()
    and location.getFile() = otherLocation.getFile()
    and location.getStartLine() <= otherLocation.getStartLine()
    and location.getEndLine() >= otherLocation.getEndLine()
    and location.getStartColumn() <= otherLocation.getStartColumn()
    and location.getEndColumn() >= otherLocation.getEndColumn()
select parent, arrayTypeAccess

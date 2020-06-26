/**
 * Finds access of static fields or methods where the qualifier of
 * the access is an instance reference, e.g.:
 * ```
 * class Container {
 *     private static final int MAX_SIZE = 100;
 *     private int size;
 *
 *     ...
 *
 *     public boolean isFull() {
 *         // Instance reference is used for static field `MAX_SIZE`
 *         return this.size == this.MAX_SIZE;
 *     }
 * }
 * ```
 *
 * While this is allowed by Java, it should be avoided because it
 * can be confusing to the reader. It ignores the instance reference
 * value (even if it is `null`) and instead accesses the member of
 * the compile time type of the instance reference.
 * Therefore instead either no qualifier should be used, e.g. in case
 * the static member is in the same class, or the declaring type should
 * be used as qualifier. So for the example above, the field access
 * could be written as `Container.MAX_SIZE`.
 *
 * See also:
 *  - Field access: https://docs.oracle.com/javase/specs/jls/se14/html/jls-15.html#d5e26203
 *  - Method call: https://docs.oracle.com/javase/specs/jls/se14/html/jls-15.html#d5e27924
 */

import java

class MemberAccess extends Expr {
    MemberAccess() {
        this instanceof FieldAccess
        or this instanceof MethodAccess
    }
    
    Member getMember() {
        result = this.(FieldAccess).getField()
        or result = this.(MethodAccess).getMethod()
    }
    
    Expr getQualifier() {
        result = this.(FieldAccess).getQualifier()
        or result = this.(MethodAccess).getQualifier()
    }
}

from MemberAccess memberAccess, Expr qualifier
where
    memberAccess.getMember().isStatic()
    and qualifier = memberAccess.getQualifier()
    // If a qualifier exists and it is not a TypeAccess, then it is
    // and instance expression
    and not qualifier instanceof TypeAccess
select memberAccess

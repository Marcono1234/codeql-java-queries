/**
 * Finds fields which could be `final`, e.g.:
 * ```
 * class Name {
 *     // These fields are only assigned a value in the constructor
 *     // so they could be final
 *     private String forename;
 *     private String surname;
 *
 *     public Name(String forename, String surname) {
 *         this.forename = forename;
 *         this.surname = surname;
 *     }
 *
 *     public String getForename() {
 *         return forename;
 *     }
 *
 *     public String getSurname() {
 *         return surname;
 *     }
 * }
 * ```
 * `final` fields provide memory visibility guarantees for multi-threaded use
 * and allow the compiler to produce more efficient byte code
 * (see JLS 14 §17.5. "`final` Field Semantics").
 * Additionally they can make the code less error-prone by preventing future
 * code changes from re-assigning a value to the field by accident.
 *
 * See https://docs.oracle.com/javase/specs/jls/se14/html/jls-17.html#jls-17.5
 */

import java

predicate isPubliclyVisible(RefType type) {
    type.isPublic()
    or (
        type.isProtected()
        and isPubliclyVisible(type.getEnclosingType())
    )
}

from Field f
where
    f.fromSource()
    and not f.isFinal()
    // Ignore static fields since their value visibility is guaranteed due to static initialization
    and not f.isStatic()
    // Make sure field is not publicly visible, otherwise cannot guarantee that
    // there happens no assignment to it
    and (
        f.isPrivate()
        or f.isPackageProtected()
        or (
            f.isProtected()
            and not isPubliclyVisible(f.getDeclaringType())
        )
    )
    and forall (LValue fieldWrite | fieldWrite.getVariable() = f |
        fieldWrite.getRhs() = f.getInitializer()
        or fieldWrite.getEnclosingCallable().(Constructor).getDeclaringType() = f.getDeclaringType()
    )
select f, "Field could be final."
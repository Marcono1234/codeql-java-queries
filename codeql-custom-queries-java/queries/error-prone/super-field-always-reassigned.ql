/**
 * Finds fields which are overwritten in the constructors of all subclasses.
 * It might be less error-prone to instead add an additional parameter to the superclass
 * constructor and initialize the field there (and optionally reduce the visibility of
 * the field). This way it can be ensured that no subclass forgets to initialize the field.
 *
 * For example:
 * ```java
 * class Superclass {
 *   protected int f;
 *
 *   protected Superclass() {
 *   }
 * }
 *
 * class Subclass {
 *   public Subclass() {
 *     f = 1;
 *   }
 * }
 * ```
 *
 * Should be changed to:
 * ```java
 * class Superclass {
 *   private final int f;
 *
 *   protected Superclass(int f) {
 *     this.f = f;
 *   }
 * }
 *
 * class Subclass {
 *   public Subclass() {
 *     super(1);
 *   }
 * }
 * ```
 *
 * This query might yield incorrect results in case external code can create instances
 * of the superclass, or create custom subclasses, and is not required to overwrite the
 * field value.
 *
 * @kind problem
 * @id TODO
 */

import java

from Field f, Class declaringType
where
  not f.isStatic() and
  f.getDeclaringType() = declaringType and
  // Class must be part of the project, since this query suggests to modify it
  declaringType.fromSource() and
  (
    declaringType.isAbstract()
    or
    // Class is not directly instantiated
    not exists(ClassInstanceExpr newExpr |
      newExpr.getConstructedType().getSourceDeclaration() = declaringType
    )
  ) and
  // Make sure there are multiple subclasses, so that the query is actually relevant
  count(Class subtype |
    subtype.fromSource() and subtype.getASupertype().getSourceDeclaration() = declaringType
  ) >= 2 and
  // Use `forex` here to make sure there are actually subclasses, with constructors
  forex(Class subtype |
    subtype.fromSource() and subtype.getASupertype().getSourceDeclaration() = declaringType
  |
    forex(Constructor c | c = subtype.getAConstructor() |
      exists(AssignExpr fieldWrite, FieldAccess fieldAccess |
        fieldWrite.getEnclosingCallable() = c and
        fieldWrite.getDest() = fieldAccess and
        fieldAccess.getField() = f and
        fieldAccess.isOwnFieldAccess()
      )
    )
  )
select f,
  "All subclasses reassign this field in their constructor; consider initializing this field in the constructor of this class"

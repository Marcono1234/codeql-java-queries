/**
 * Finds `hashCode` implementations which cast `float`, `double` or `long` values to `int` for the
 * hash code calculation. This conversion is lossy for values outside the `int` value range, and
 * can therefore increase chances of a hash collision for not-equal values.
 *
 * Instead prefer the `hashCode` methods of the boxed types, for example `Long#hashCode(long)`,
 * to obtain an `int` for further calculations.
 *
 * @id TODO
 * @kind problem
 */

import java

Member getOwnAccessedMember(Expr e) {
  exists(FieldRead f | f = e | f.isOwnFieldAccess() and result = f.getField())
  or
  exists(MethodAccess c | c = e | c.isOwnMethodAccess() and result = c.getMethod())
}

from HashCodeMethod hashCodeMethod, Expr castingExpr, BoxedType boxedSourceType
where
  castingExpr.getEnclosingCallable() = hashCodeMethod and
  castingExpr.getType().hasName("int") and
  boxedSourceType.hasName(["Float", "Double", "Long"]) and
  (
    exists(Expr castTarget |
      castTarget = castingExpr.(CastExpr).getExpr() and
      boxedSourceType.getPrimitiveType() = castTarget.getType() and
      exists(Member accessedMember |
        // Make sure cast expression is directly performed on field value
        accessedMember = getOwnAccessedMember(castTarget) and
        // and code is not manually performing lossless calculation with bit operations
        not exists(BinaryExpr shiftExpr, Expr shifted |
          (shiftExpr instanceof RightShiftExpr or shiftExpr instanceof UnsignedRightShiftExpr) and
          shiftExpr.getEnclosingCallable() = hashCodeMethod and
          shifted = shiftExpr.getLeftOperand()
        |
          accessedMember = getOwnAccessedMember(shifted)
        )
      )
    )
    or
    exists(MethodAccess intValueCall | intValueCall = castingExpr |
      intValueCall.getMethod().hasName("intValue") and
      boxedSourceType = intValueCall.getQualifier().getType()
    )
  )
select castingExpr, "Should use " + boxedSourceType.getName() + "#hashCode instead"

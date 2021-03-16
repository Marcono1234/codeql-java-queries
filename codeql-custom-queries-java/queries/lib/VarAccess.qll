import java

private predicate accessSameVar(VarAccess a, VarAccess b) {
  a.getVariable() = b.getVariable() and
  (
    a.getVariable().isStatic()
    or
    a.isLocal() and b.isLocal()
    or
    exists(RefType enclosing |
      a.(FieldAccess).isEnclosingFieldAccess(enclosing) and
      b.(FieldAccess).isEnclosingFieldAccess(enclosing)
    )
    or
    accessSameVarOfSameOwner(a.getQualifier(), b.getQualifier())
  )
}

/**
 * Holds if both expressions refer to the same variable or array element and the
 * receiver object (if any) whose variable or array is accessed is the same.
 * The result of this predicate is only accurate when no assignments occur between
 * the two accesses.
 */
predicate accessSameVarOfSameOwner(Expr a, Expr b) {
  accessSameVar(a, b)
  or
  exists(ArrayAccess arrayA, ArrayAccess arrayB | arrayA = a and arrayB = b |
    accessSameVarOfSameOwner(arrayA.getArray(), arrayB.getArray()) and
    (
      arrayA.getIndexExpr().(IntegerLiteral).getIntValue() =
        arrayB.getIndexExpr().(IntegerLiteral).getIntValue()
      or
      accessSameVarOfSameOwner(arrayA.getIndexExpr(), arrayB.getIndexExpr())
    )
  )
}

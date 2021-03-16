import java

/**
 * Holds if both variable accesses refer to the same variable and the receiver object
 * (if any) whose variable is accessed is the same. The result of this predicate is
 * only accurate when no assignments occur between the two variable accesses.
 */
predicate accessSameVarOfSameOwner(VarAccess a, VarAccess b) {
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
    accessSameOwner(a.getQualifier(), b.getQualifier())
  )
}

private predicate accessSameOwner(Expr qualifierA, Expr qualifierB) {
  accessSameVarOfSameOwner(qualifierA, qualifierB)
  or
  exists(ArrayAccess arrayA, ArrayAccess arrayB | arrayA = qualifierA and arrayB = qualifierB |
    accessSameOwner(arrayA.getArray(), arrayB.getArray()) and
    (
      arrayA.getIndexExpr().(IntegerLiteral).getIntValue() =
        arrayB.getIndexExpr().(IntegerLiteral).getIntValue()
      or
      accessSameVarOfSameOwner(arrayA.getIndexExpr(), arrayB.getIndexExpr())
    )
  )
}

/**
 * Finds calls to `Character#digit` and `Character#getNumericValue` which do not check for
 * the return value `-1`. This return value is used when the character does not represent
 * a digit. Erroneously consuming the -1 as digit can therefore lead to incorrect results.
 *
 * @kind problem
 * @id TODO
 */

import java
import semmle.code.java.dataflow.DataFlow

import lib.Expressions

from MethodCall call, Method m
where
  call.getMethod() = m and
  m.getDeclaringType().hasQualifiedName("java.lang", "Character") and
  m.hasName(["digit", "getNumericValue"]) and
  // And does not check for -1
  not exists(Expr compOp |
    DataFlow::localExprFlow(call, compOp) and
    (
      comparesWithConstant(_, compOp, 0, _)
      or
      // `== -1` or `!= -1`
      exists(EqualityTest eq |
        eq.getAnOperand().(CompileTimeConstantExpr).getIntValue() = -1 and
        eq.getAnOperand() = compOp
      )
    )
  )
select call, "Does not check for -1 result"

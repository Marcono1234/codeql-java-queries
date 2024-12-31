/**
 * Finds cases of switched arguments based on argument and parameter names.
 *
 * For example:
 * ```java
 * void addUser(String firstName, String lastName) {
 *     ...
 * }
 *
 * ...
 *
 * String firstName = ...;
 * String lastName = ...;
 * // Provides arguments in wrong order
 * addUser(lastName, firstName);
 * ```
 *
 * @id TODO
 * @kind problem
 * @precision medium
 */

import java
import semmle.code.java.dataflow.DataFlow

predicate isAssignable(Parameter param, Variable argVar) {
  exists(Type paramType, Type argType | paramType = param.getType() and argType = argVar.getType() |
    paramType = argType or
    paramType = argType.(RefType).getAnAncestor() or
    paramType.(BoxedType).getPrimitiveType() = argType or
    paramType = argType.(BoxedType).getPrimitiveType() or
    // Note: This might be too lenient
    paramType.getErasure() = argType.getErasure()
  )
}

// CodeQL seems to generate param names in the form p0, p1, ... for external classes
predicate areParamNamesKnown(Callable c) {
  c.fromSource()
  or
  // Or there is a param name which is not `p<N>`
  exists(string paramName | paramName = c.getAParameter().getName() |
    not paramName.regexpMatch("p\\d+")
  )
}

bindingset[s, prefix]
predicate startsWith(string s, string prefix) { s.indexOf(prefix) = 0 }

bindingset[s, suffix]
predicate endsWith(string s, string suffix) { s.indexOf(suffix) = s.length() - suffix.length() }

predicate matchesParamName(Parameter param, Variable argVar) {
  exists(string paramName, string varName |
    // Compare case insensitively
    paramName = param.getName().toLowerCase() and
    varName = argVar.getName().toLowerCase()
  |
    paramName = varName or
    startsWith(varName, paramName) or
    endsWith(varName, paramName)
  )
}

class ComparableCompareToMethod extends Method {
  ComparableCompareToMethod() {
    getDeclaringType().hasQualifiedName("java.lang", "Comparable") and
    hasName("compareTo")
  }
}

class ComparatorCompareMethod extends Method {
  ComparatorCompareMethod() {
    getDeclaringType().hasQualifiedName("java.util", "Comparator") and hasName("compare")
  }
}

predicate isEnclosedByComparison(Call call, Variable var1, Variable var2) {
  exists(Expr condition |
    exists(IfStmt ifStmt |
      condition = ifStmt.getCondition() and
      call.getEnclosingStmt().getEnclosingStmt*() = [ifStmt.getThen(), ifStmt.getElse()]
    )
    or
    exists(ConditionalExpr e |
      condition = e.getCondition() and call.(MethodAccess).getParent*() = e.getABranchExpr()
    )
  |
    // Comparison expr
    exists(ComparisonExpr c | c.getParent*() = condition |
      c.getAnOperand() = var1.getAnAccess() and c.getAnOperand() = var2.getAnAccess()
    )
    or
    // Or `Comparable#compareTo` or `Comparator#compare` call
    exists(RValue varReadA, RValue varReadB |
      varReadA = var1.getAnAccess() and varReadB = var2.getAnAccess()
      or
      varReadA = var2.getAnAccess() and varReadB = var1.getAnAccess()
    |
      exists(MethodAccess compareToCall |
        compareToCall.getParent*() = condition and
        compareToCall.getMethod().getSourceDeclaration().getASourceOverriddenMethod*() instanceof
          ComparableCompareToMethod
      |
        compareToCall.getQualifier() = varReadA and
        compareToCall.getArgument(0) = varReadB
      )
      or
      exists(MethodAccess compareCall |
        compareCall.getParent*() = condition and
        compareCall.getMethod().getSourceDeclaration().getASourceOverriddenMethod*() instanceof
          ComparatorCompareMethod
      |
        compareCall.getArgument(0) = varReadA and
        compareCall.getArgument(1) = varReadB
      )
    )
  )
}

from
  Call call, Callable callee, int param1Index, Parameter param1, int param2Index, Parameter param2,
  RValue arg1, Variable var1, RValue arg2, Variable var2
where
  call.getCallee() = callee and
  areParamNamesKnown(callee) and
  // Enforce ordering, to avoid reporing switched arguments twice
  param1Index < param2Index and
  // Ignore if argument is part of varargs argument
  (
    call.getNumArgument() <= callee.getNumberOfParameters() or
    param2Index < callee.getNumberOfParameters() - 1
  ) and
  param1 = callee.getParameter(param1Index) and
  param2 = callee.getParameter(param2Index) and
  arg1 = call.getArgument(param1Index) and
  arg1.getVariable() = var1 and
  arg2 = call.getArgument(param2Index) and
  arg2.getVariable() = var2 and
  var1 != var2 and
  // And param names indicate that args are switched
  matchesParamName(param1, var2) and
  not matchesParamName(param1, var1) and
  matchesParamName(param2, var1) and
  not matchesParamName(param2, var2) and
  // And args can really be switched
  isAssignable(param1, var2) and
  isAssignable(param2, var1) and
  // And does not call the same enclosing method or own constructor, in that case the arguments might be intentionally switched
  not (
    callee = call.getEnclosingCallable()
    or
    arg1.(FieldRead).isOwnFieldAccess() and
    arg2.(FieldRead).isOwnFieldAccess() and
    callee.(Constructor).getDeclaringType() = call.getEnclosingCallable().getDeclaringType()
  ) and
  // Ignore if args are being compared, and are intentionally switched based on the result
  not isEnclosedByComparison(call, var1, var2) and
  // Ignore if part of a test assertion which might have intentionally switched args
  not (
    call.getEnclosingCallable().getDeclaringType() instanceof TestClass and
    exists(MethodAccess assertionCall | assertionCall.getMethod().getName().matches("assert%") |
      // Directly used as arg (possibly nested inside other expressions, e.g. comparison expr)
      call.(MethodAccess).getParent*() = assertionCall.getAnArgument()
      or
      // Or with dataflow
      DataFlow::localExprFlow(call, assertionCall.getAnArgument())
    )
  )
select arg1, "'" + param1.getName() + "' arg might be switched with $@ (index " + param2Index + ")",
  arg2, "'" + param2.getName() + "' arg"

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
 * @precision low
 */

// Note: This query has rather low precision; a more precise variant is `switched-arguments-precise.ql`
// (but that might have more false negatives)
import java
import semmle.code.java.dataflow.DataFlow

// TODO: Might be wrong for generics
predicate isAssignable(Type paramType, Type argType) {
  paramType = argType or
  paramType = argType.(RefType).getAnAncestor() or
  paramType.(BoxedType).getPrimitiveType() = argType or
  paramType = argType.(BoxedType).getPrimitiveType()
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

bindingset[s, suffix]
predicate endsWithIgnoreCase(string s, string suffix) {
  s.toLowerCase().indexOf(suffix.toLowerCase()) = s.length() - suffix.length()
}

from
  Call call, Callable callee, int paramIndex, Parameter otherParam, int otherParamIndex,
  string otherParamName, Variable var, RValue callArg
where
  call.getCallee() = callee and
  areParamNamesKnown(callee) and
  callArg = call.getArgument(paramIndex) and
  // Ignore if argument is part of varargs argument
  (
    call.getNumArgument() <= callee.getNumberOfParameters() or
    paramIndex < callee.getNumberOfParameters() - 1
  ) and
  // Find a parameter with the same name as the argument, but at a different index
  otherParam = callee.getParameter(otherParamIndex) and
  otherParamIndex != paramIndex and
  var = callArg.getVariable() and
  otherParamName = otherParam.getName() and
  otherParamName = var.getName() and
  isAssignable(otherParam.getType(), var.getType()) and
  // Var might be used as multiple args, verify that it is not also used for the expected parameter
  not var.getAnAccess() = call.getArgument(otherParamIndex) and
  // And the other param does not have a variable with matching name as argument
  not exists(string otherArgVarName |
    otherArgVarName = call.getArgument(otherParamIndex).(RValue).getVariable().getName()
  |
    otherArgVarName = otherParamName or
    otherArgVarName.indexOf(otherParamName) = 0 or
    endsWithIgnoreCase(otherArgVarName, otherParamName)
  ) and
  // And does not call the same enclosing method, in that case the arguments might be intentionally switched
  not callee = call.getEnclosingCallable()
select callArg,
  "Argument might be used at wrong position; should probably be for $@ at index " + otherParamIndex,
  otherParam, "this parameter"

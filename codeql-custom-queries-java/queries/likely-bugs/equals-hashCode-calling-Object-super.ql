/**
 * Finds classes which call `super.equals` or `super.hashCode` in their
 * `equals` / `hashCode` implementation, but for which no superclass
 * overrides these methods, therefore effectively calling `Object.equals` or
 * `Object.hashCode`.
 * This defeats the purpose of implementing own equality criteria, because
 * the implementation by `Object` only checks for identity.
 *
 * If the intention is to check `obj == this` by calling `Object.equals`,
 * then it is better to write that explicitly. Otherwise one might wonder
 * (without checking which parent classes a class has) why the `super.equals`
 * check is not at the beginning of the method and why the method does not
 * return fast if the result is `false`.
 *
 * For example:
 * ```java
 * class MyClass {
 *     int i;
 * 
 *     @Override
 *     public boolean equals(Object o) {
 *         if (!(o instanceof MyClass)) {
 *             return false;
 *         }
 * 
 *         MyClass other = (MyClass) o;
 *         // Bug: super.equals call here is wrong; will prevent two separate
 *         // instances with same data from being considered equal
 *         return super.equals(other) && i == other.i;
 *     }
 * }
 * ```
 *
 * @kind problem
 */

import java

predicate delegatesToParent(Method m, MethodAccess superCall) {
  m.getBody().(SingletonBlock).getStmt().(ReturnStmt).getResult() = superCall
}

from Method enclosingMethod, MethodAccess superCall, Method calledMethod
where
  superCall.getQualifier() instanceof SuperAccess and
  superCall.getMethod() = calledMethod and
  // Called method is not overridden; directly calls Object method
  calledMethod.getDeclaringType() instanceof TypeObject and
  superCall.getEnclosingCallable() = enclosingMethod and
  // Check that calls occur in same method, e.g. `equals` call in `equals` method,
  // otherwise call might be intentional
  (
    enclosingMethod instanceof EqualsMethod and
    calledMethod instanceof EqualsMethod
    or
    enclosingMethod instanceof HashCodeMethod and
    calledMethod instanceof HashCodeMethod
  ) and
  // Ignore implementations which simply delegate to the parent
  // E.g. to change the method javadoc
  not delegatesToParent(enclosingMethod, superCall)
select superCall, "Calls `Object." + calledMethod.getName() + "`"

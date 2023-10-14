/**
 * Finds code which calls `StringBuilder.toString()` and then calls a method on
 * the resulting `String` which could have directly been called on the `StringBuilder`
 * instead, avoiding the intermediate `String` object.
 *
 * For example:
 * ```java
 * StringBuilder builder = ...;
 * int i = builder.toString().indexOf("substr");
 * // can be simplified:
 * int i = builder.indexOf("substr");
 * ```
 *
 * @kind problem
 */

// Slightly related to `avoidable-String-operation-before-StringBuilder-append.ql`

import java

predicate haveSameSignature(Method m1, Method m2) {
  m1.getReturnType() = m2.getReturnType() and
  m1.getSignature() = m2.getSignature()
}

from
  StringBuildingType stringBuildingType, MethodAccess toStringCall, MethodAccess callOnString,
  Method calledMethod
where
  stringBuildingType = toStringCall.getReceiverType() and
  toStringCall.getMethod().hasStringSignature("toString()") and
  callOnString.getQualifier() = toStringCall and
  calledMethod = callOnString.getMethod() and
  // There is a StringBuilder method with the same signature
  exists(Method stringBuilderMethod |
    // Declared by StringBuilder or internal superclass
    stringBuilderMethod.getDeclaringType() = stringBuildingType.getASourceSupertype*() and
    haveSameSignature(calledMethod, stringBuilderMethod)
  ) and
  // But ignore if method is declared by Object, e.g. equals(Object)
  not exists(Method objectMethod |
    objectMethod.getDeclaringType() instanceof TypeObject and
    haveSameSignature(objectMethod, calledMethod)
  )
select toStringCall,
  "Instead of first creating String, should directly call `" + stringBuildingType.getName() + "." +
    calledMethod.getName() + "`"

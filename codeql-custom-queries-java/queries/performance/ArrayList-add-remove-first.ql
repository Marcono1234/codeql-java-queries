/**
 * Finds calls to methods of `java.util.ArrayList` which add or remove elements at
 * index 0. If this is performed often, it is quite inefficient because subsequent
 * elements have to be shifted.
 *
 * Instead either add and remove elements at the end of the list (if possible for
 * the use case, e.g. when using it as "stack"), or use another collection implementation
 * such as `java.util.ArrayDeque` which potentially supports more efficient addition
 * and removal also at the start.\
 * However, you should profile your application to verify that the changes really
 * improved performance.
 *
 * @kind problem
 * @id TODO
 */

// TODO: Try to reduce findings to cases where this really makes a performance difference?

// Note: Actually not just adding / removing the first element of an ArrayList is inefficient; adding / removing
// any element other than the last one is inefficient, but detecting that is more difficult

import java

class ClassArrayList extends Class {
  ClassArrayList() { hasQualifiedName("java.util", "ArrayList") }
}

from MethodCall methodCall, Method m
where
  m = methodCall.getMethod() and
  (
    m.hasStringSignature("removeFirst()")
    or
    // Note: Don't try to match method signature; due to generic parameter (possibly even different one
    // in subclasses) this can become error-prone
    m.hasName("addFirst")
    or
    (
      m.hasStringSignature("remove(int)")
      or
      // Note: For the suggested replacement with `ArrayDeque`, `addAll` is currently always (?) less
      // efficient there because it copies elements one by one
      m.hasName(["add", "addAll"]) and
      // Check param type to avoid confusing element with index, e.g. `add(0)` adding element with value 0
      m.getParameterType(0).hasName("int")
    ) and
    methodCall.getArgument(0).(CompileTimeConstantExpr).getIntValue() = 0
  ) and
  (
    // Call occurs on expression of type ArrayList (or subtype)
    methodCall.getReceiverType().getSourceDeclaration().getASourceSupertype*() instanceof
      ClassArrayList
    or
    // Or call occurs on variable which was assigned an ArrayList (or subtype)
    methodCall
        .getQualifier()
        .(VarAccess)
        .getVariable()
        .getAnAssignedValue()
        .getType()
        .(RefType)
        .getSourceDeclaration()
        .getASourceSupertype*() instanceof ClassArrayList
  )
select methodCall, "Adding or removing first element of ArrayList is inefficient"

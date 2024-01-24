/**
 * Finds usage of `Gson.fromJson(..., Type)` where the type specified through the `Type`
 * argument does not match the desired type used for the result. This can lead to a
 * `ClassCastException` at runtime, or might accidentally rely on Gson imlementation details.
 *
 * The `fromJson(..., Type)` overloads are not type-safe, the return type is not bound.
 * Prefer the `T fromJson(..., TypeToken<T>)` overloads which are type-safe; they were
 * added in Gson 2.10.
 *
 * For example:
 * ```java
 * // Bug: Type mismatch `OtherClass != MyClass`, but no compilation warning or error
 * List<OtherClass> l = gson.fromJson(..., new TypeToken<List<MyClass>>() {}.getType());
 *
 * // Instead prefer `fromJson(..., TypeToken)`, note the missing `.getType()` call
 * // This causes a compilation error, as desired, requiring to fix the incorrect types
 * List<OtherClass> l = gson.fromJson(..., new TypeToken<List<MyClass>>() {});
 * ```
 *
 * @id todo
 * @kind problem
 */

import java
import semmle.code.java.dataflow.DataFlow

/** Get `T` from `TypeToken<T>` */
RefType getTypeTokenArg(RefType t) {
  result = t.(ParameterizedType).getTypeArgument(0)
  or
  // Or obtain it from `new TypeToken<T> () {}`, where the supertype is `TypeToken<T>`
  result = t.(AnonymousClass).getASupertype().(ParameterizedType).getTypeArgument(0)
}

predicate isValidDesiredType(RefType desiredType, RefType specifiedType) {
  specifiedType.getASupertype*() = desiredType
  or
  // Or they are not subtypes but the type arguments of the 'desired' type are less specific
  // than the ones of the 'specified' type, e.g. `List<BaseClass>` vs. `List<SubClass>`
  // Note: This does not cover all false positives though, e.g. `List<BaseClass>` vs. `ArrayList<SubClass>`,
  // but that is probably rather rare and handling this would require resolving type variables
  exists(ParameterizedType dParamType, ParameterizedType sParamType |
    dParamType = desiredType and sParamType = specifiedType
  |
    dParamType.getSourceDeclaration() = sParamType.getSourceDeclaration() and
    forex(int typeArgIndex, RefType dTypeArg, RefType sTypeArg |
      dTypeArg = dParamType.getTypeArgument(typeArgIndex) and
      sTypeArg = sParamType.getTypeArgument(typeArgIndex)
    |
      // TODO: Maybe can make this more performant by just checking `sTypeArg.getASupertype*() = dTypeArg`,
      // that should suffice for most cases
      isValidDesiredType(dTypeArg, sTypeArg)
    )
  )
}

from
  MethodAccess deserializationCall, Expr typeArg, RefType desiredType, Expr typeTokenExpr,
  RefType specifiedType
where
  exists(Method calledMethod | calledMethod = deserializationCall.getMethod() |
    exists(Method deserializeMethod |
      deserializeMethod
          .getDeclaringType()
          .hasQualifiedName("com.google.gson", "JsonDeserializationContext") and
      deserializeMethod.hasName("deserialize") and
      calledMethod.getSourceDeclaration().getASourceOverriddenMethod*() = deserializeMethod and
      typeArg = deserializationCall.getArgument(1)
    )
    or
    calledMethod.getDeclaringType().hasQualifiedName("com.google.gson", "Gson") and
    calledMethod.hasName("fromJson") and
    calledMethod.getParameterType(1).(RefType).hasQualifiedName("java.lang.reflect", "Type") and
    typeArg = deserializationCall.getArgument(1)
  ) and
  // Result type of generic method call is the desired type
  desiredType = deserializationCall.getType() and
  // Determine the `specifiedType`
  exists(MethodAccess getTypeCall, Method getTypeMethod |
    getTypeMethod = getTypeCall.getMethod() and
    getTypeMethod
        .getSourceDeclaration()
        .getDeclaringType()
        .hasQualifiedName("com.google.gson.reflect", "TypeToken") and
    getTypeMethod.hasName("getType") and
    specifiedType = getTypeTokenArg(typeTokenExpr.getType())
  |
    // Locally created `TypeToken`
    typeTokenExpr = getTypeCall.getQualifier() and
    DataFlow::localExprFlow(getTypeCall, typeArg)
    or
    exists(Field f |
      // Or `TypeToken` stored in field (but possibly with field type `TypeToken<?>`); try to get
      // type from assigned value
      f.getAnAssignedValue() = typeTokenExpr and
      getTypeCall.getQualifier() = f.getAnAccess() and
      DataFlow::localExprFlow(getTypeCall, typeArg)
      or
      // Or `TypeToken.getType()` stored in field
      f.getAnAssignedValue() = getTypeCall and
      typeTokenExpr = getTypeCall.getQualifier() and
      typeArg = f.getAnAccess()
    )
  ) and
  // Ignore `TypeToken<?>`; can't know if `desiredType` is correct then
  not specifiedType instanceof Wildcard and
  not isValidDesiredType(desiredType, specifiedType)
select deserializationCall, "Specified type '$@' differs from desired type '" + desiredType + "'",
  typeTokenExpr, specifiedType.toString()

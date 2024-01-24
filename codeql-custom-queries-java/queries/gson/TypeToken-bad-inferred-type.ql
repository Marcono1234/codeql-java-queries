/**
 * Finds creation of `TypeToken` using the diamond syntax `<>`, but where the inferred
 * type seems to be undesired.
 *
 * For example:
 * ```java
 * // Inferred type is `TypeToken<Object>`
 * gson.fromJson(..., new TypeToken<>() {}.getType());
 * ```
 *
 * Often this issue can also be detected by using the type-safe `Gson.fromJson(..., TypeToken)`
 * overloads (instead of `fromJson(..., Type)`) introduced in Gson 2.10.
 *
 * @id todo
 * @kind problem
 */

import java

// Workaround because `ClassInstanceExpr::isDiamond` does not work for anonymous
// classes yet, see https://github.com/github/codeql/pull/15429
predicate isDiamond(ClassInstanceExpr e) {
  e.isDiamond()
  or
  e.getAnonymousClass().getASupertype() instanceof ParameterizedType and
  not exists(e.getATypeArgument())
}

from ClassInstanceExpr newExpr, ParameterizedType resolvedTypeTokenType
where
  isDiamond(newExpr) and
  resolvedTypeTokenType = newExpr.getType().(AnonymousClass).getASupertype() and
  resolvedTypeTokenType
      .getSourceDeclaration()
      .hasQualifiedName("com.google.gson.reflect", "TypeToken") and
  resolvedTypeTokenType.getTypeArgument(0) instanceof TypeObject
select newExpr, "Accidentally creates a `TypeToken<Object>`"

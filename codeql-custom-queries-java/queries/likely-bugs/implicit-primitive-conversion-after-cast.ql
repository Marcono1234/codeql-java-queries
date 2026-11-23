/**
 * Finds implicit conversions from one primitive type to another one, right after
 * a cast had been performed. This can indiciate that the cast has no effect and
 * is redundant.
 *
 * For example:
 * ```java
 * public long getResult() {
 *   // Potentially redundant cast to `int` because return implicitly converts
 *   // to `long`
 *   return (int) calculateResult();
 * }
 * ```
 *
 * **Important:** In some cases the cast does have an effect (e.g. intentionally
 * truncating the value) or is intended to make the intention of the code clearer.
 * Carefully review the findings of this query.
 *
 * @kind problem
 * @id TODO
 */

import java
import semmle.code.java.Conversions

from ConversionSite conversionSite, PrimitiveType sourceType, PrimitiveType targetType
where
  conversionSite.isImplicit() and
  not conversionSite.isTrivial() and
  sourceType = conversionSite.getConversionSource() and
  targetType = conversionSite.getConversionTarget() and
  conversionSite instanceof CastExpr and
  // Ignore if calling a method which has an `int` parameter for convenience, but actually
  // expects a smaller numeric type, e.g. `writeByte(int)`
  not (
    targetType.hasName("int") and
    exists(MethodCall enclosingCall |
      enclosingCall.getAnArgument() = conversionSite and
      enclosingCall.getMethod().getName().toLowerCase().contains(sourceType.getName())
    )
  )
select conversionSite, "Implicit conversion after cast, from " + sourceType + " to " + targetType

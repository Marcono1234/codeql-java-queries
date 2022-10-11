/**
 * Finds cast expressions which cast a value of type `Number` to a numeric primitive type.
 * The compiler converts this to a cast to the corresponding boxed type and then obtains the
 * primitive value. This means no numeric conversion is performed before the cast.
 * 
 * Consider this example method:
 * ```java
 * public static long square(Number n) {
 *     long v = (long) n;
 *     return v * v;
 * }
 * ```
 * Calling this method with `Integer.valueOf(1)` will cause a `ClassCastException`.
 * 
 * It should be verified whether that behavior is desired; if not then one of the `...Value()`
 * of `Number` could be used, for example `Number.longValue()`. These methods also work for
 * other subclasses of `Number`.
 * 
 * @kind problem
 * @precision low
 */

import java

from CastExpr castExpr, PrimitiveType targetType
where
    castExpr.getExpr().getType().(RefType).hasQualifiedName("java.lang", "Number")
    and castExpr.getType().(NumericType) = targetType
    and not castExpr.getEnclosingCallable().getDeclaringType() instanceof TestClass
    // Ignore if cast is guarded by instanceof check
    and not exists(InstanceOfExpr instanceOfCheck, LocalScopeVariable variable |
        instanceOfCheck.getExpr() = variable.getAnAccess()
        and castExpr.getExpr() = variable.getAnAccess()
        and instanceOfCheck.getCheckedType() = targetType.getBoxedType()
        // Note: Checking `dominates` might suffice for now, but would be more accurate to check for guard
        and dominates(instanceOfCheck, castExpr)
    )
select castExpr, "This cast to primitive type does not perform numeric conversion"

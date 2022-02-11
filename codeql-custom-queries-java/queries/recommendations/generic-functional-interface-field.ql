/**
 * Finds fields whose type is a generic functional interface, such as `Function`, and which are
 * initialized with a lambda expression. Such fields should be converted to a method instead,
 * because the field type makes it difficult for the user of the field to understand its behavior.
 * Having a dedicated method makes it clearer for users what the method will do (parameters and
 * return value can for example easily be documented), but at the same time it can still be
 * used where a functional interface is required by using a method reference expression.
 * 
 * For example:
 * ```java
 * Function<String, String> NAME_TRANSFORMER = name -> {
 *     ...
 * };
 * ```
 * Could be converted to a method like this:
 * ```java
 * static String transformName(String name) {
 *     ...
 * }
 * ```
 */

import java

from Field f, MethodAccess call
where
    (
        f.getInitializer() instanceof LambdaExpr
        or f.getInitializer().(CastExpr).getExpr() instanceof LambdaExpr
    )
    // Make results more precise by requiring that method is called for field value, and
    // that a generic functional interface is used
    and call.getQualifier() = f.getAnAccess()
    and exists (RefType fieldType |
        fieldType = f.getType().(RefType).getSourceDeclaration().getASourceSupertype*()
    |
        fieldType.hasQualifiedName("java.lang", "Runnable")
        or fieldType.hasQualifiedName("java.util.concurrent", "Callable")
        or fieldType.getPackage().getName() = "java.util.function"
    )
select f, "Should replace this field with a method with corresponding parameters and return type"

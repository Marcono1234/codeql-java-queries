/**
 * Finds calls of `java.lang.Class` methods on a primitive type literal
 * which make no sense because they always behave the same regardless of
 * which arguments are provided, or because their result is predictable, e.g.:
 * ```
 * // Will always throw an exception, even for Integer object
 * int.class.cast(value);
 *
 * // Will return false
 * boolean.class.isEnum()
 * ```
 */

import java

/**
 * java.lang.Class method which cannot be used for primitive classes,
 * or which makes no sense.
 *
 * Based on JDK 15 methods, including preview features.
 */
class PrimitiveIllogicalClassMethod extends Method {
    PrimitiveIllogicalClassMethod() {
        getDeclaringType() instanceof TypeClass
        and hasName([
          "asSubclass",
          // Object cannot be cast to primitive
          "cast",
          "componentType",
          "getAnnotatedInterfaces",
          "getAnnotatedSuperclass",
          "getAnnotation",
          "getAnnotations",
          "getAnnotationsByType",
          "getClasses",
          "getComponentType",
          "getConstructor",
          "getConstructors",
          "getDeclaredAnnotations",
          "getDeclaredClasses",
          "getDeclaredConstructor",
          "getDeclaredConstructors",
          "getDeclaredField",
          "getDeclaredFields",
          "getDeclaredMethod",
          "getDeclaredMethods",
          "getDeclaringClass",
          "getEnclosingClass",
          "getEnclosingConstructor",
          "getEnclosingMethod",
          "getEnumConstants",
          "getField",
          "getGenericInterfaces",
          "getGenericSuperclass",
          "getInterfaces",
          "getMethod",
          "getMethods",
          "getNestHost",
          "getNestMembers",
          "getPackage",
          "getPackageName",
          "getRecordComponents",
          "getSuperclass",
          "getTypeParameters",
          "isAnnotation",
          "isAnnotationPresent",
          "isAnonymousClass",
          "isArray",
          "isEnum",
          "isHidden",
          // Object can never be instance of primitive
          "isInstance",
          "isInterface",
          "isLocalClass",
          "isMemberClass",
          "isNestmateOf",
          "isPrimitive",
          "isRecord",
          "isSealed",
          "isSynthetic",
          // Cannot create instances of primitives
          "newInstance",
          "permittedSubclasses"
        ])
    }
}

from MethodAccess illogicalCall
where
    exists (PrimitiveIllogicalClassMethod m | illogicalCall.getMethod().getSourceDeclaration().overridesOrInstantiates*(m))
    and illogicalCall.getQualifier().(TypeLiteral).getType() instanceof PrimitiveType
select illogicalCall, "Illogical call of primitive type literal method."

/**
 * Finds creation of a 'type token' with a non-parameterized type as type
 * argument. Serialization frameworks often provide 'type token' classes
 * with a single type variable intended to be subclassed (as anonymous class)
 * to provide a parameterized type, such as `List<String>`, as type argument
 * making it available at runtime (which would otherwise not be possible due
 * to type erasure).
 * These type token classes are only intended to capture parameterized types,
 * for non-parameterized type there is no point in using a type token since
 * they are not affected by type erasure. The framework providing the type
 * token class usually provides method overloads directly taking a `Class`
 * argument as well. E.g.:
 * ```java
 * class TypeToken<T> { ... }
 * interface Deserializer {
 *     <T> T deserialize(TypeToken<T> t);
 *     <T> T deserialize(Class<T> t);
 * }
 * 
 * ...
 * 
 * // Should instead use `deserialize(Class)` overload
 * TypeToken<String> token = new TypeToken<String>() {};
 * String result = deserializer.deserialize(token);
 * ```
 */

import java

// TODO: Reduce code duplication; already declared in empty-anonymous-class.ql
/**
 * Class which appears to be intended to be subclassed by anonymous classes to make
 * the generic type argument available at compile-time. E.g. Gson's or Guava's `TypeToken`.
 */
class TypeToken extends GenericType {
    TypeToken() {
        // Make sure there is only one type variable, otherwise it might not
        // be a type token
        count(getATypeParameter()) = 1
        and exists (Method m |
            m = getAMethod()
            and not m.isStatic()
            and m.getNumberOfParameters() = 0
            and m.getReturnType().(RefType).hasQualifiedName("java.lang.reflect", "Type")
        )
    }
}

from AnonymousClass c, ParameterizedClass parameterizedTypeToken, TypeToken typeToken, RefType capturedType
where
    c.getASupertype() = parameterizedTypeToken
    and typeToken = parameterizedTypeToken.getSourceDeclaration()
    and capturedType = parameterizedTypeToken.getTypeArgument(0)
    and capturedType instanceof ClassOrInterface
    and not capturedType instanceof ParameterizedType
select c, "Captures non-parameterized type " + capturedType.getName() + "; should instead directly use that type and not use " + typeToken.getName()

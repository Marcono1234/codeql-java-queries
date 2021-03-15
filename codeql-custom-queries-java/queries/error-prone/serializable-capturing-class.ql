/**
 * Finds capturing classes (inner, anonymous or local) which are
 * serialized or directly implement `Serializable`.
 *
 * It is discouraged to serialize them because synthetic constructs
 * have to be added by the compiler which are compiler dependent and
 * could prevent deserializing a serialized instance after upgrading
 * or changing the compiler.
 * See also https://docs.oracle.com/javase/tutorial/java/javaOO/nested.html#serialization
 */

import java

class CapturingClass extends Class {
    CapturingClass() {
        // Ignore enums, which support anonymous subclasses, but
        // are always safe to serialize
        not this instanceof EnumType
        and (
            isAnonymous()
            or isLocal()
            or (
                not isTopLevel()
                and not isStatic()
            )
        )
    }
}

from CapturingClass capturingClass, Top reason
where
    (
        capturingClass.getASupertype() instanceof TypeSerializable
        and reason = capturingClass
    )
    or (
        exists (MethodAccess call, Method method |
            method = call.getMethod()
            and method.getAnOverride*() instanceof WriteObjectMethod
            and call.getArgument(0).getType().(RefType).getAnAncestor() = capturingClass
            and reason = call
        )
    )
select capturingClass, reason

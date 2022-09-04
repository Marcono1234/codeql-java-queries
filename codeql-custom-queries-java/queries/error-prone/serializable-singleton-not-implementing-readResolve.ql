/**
 * Finds singleton classes implementing `Serializable` which do not implement `readResolve()`.
 * `readResolve()` should be implemented to return the singleton instance, to make sure that
 * always only the singleton instance is used, and deserialization does not expose any
 * additional instances.
 * 
 * @kind problem
 */

import java

import lib.JavaSerialization

from Class c
where
    c.fromSource()
    and c.getASourceSupertype+() instanceof TypeSerializable
    // Seems to be singleton class because all constructors are not publicly visible and only called from
    // own initializer methods
    and forex(Constructor constructor | constructor = c.getAConstructor() |
        (
            constructor.isPrivate()
            or constructor.isPackageProtected()
        )
        and forex(ClassInstanceExpr newExpr | newExpr.getConstructor().getSourceDeclaration() = constructor |
            newExpr.getEnclosingCallable().(InitializerMethod).getDeclaringType() = constructor.getDeclaringType()
        )
    )
    // Ignore enums because they have special serialization logic
    and not c instanceof EnumType
    and not any(ReadResolveSerializableMethod m).getDeclaringType() = c
    // And does not implement a readObject method which might prevent deserialization or have any other
    // special logic
    and not any(ReadObjectSerializableMethod m).getDeclaringType() = c
select c, "Serializable singleton class does not implement readResolve()"

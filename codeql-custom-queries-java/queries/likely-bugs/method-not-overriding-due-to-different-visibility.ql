/**
 * Finds methods which have the same signature as a method in a supertype but which do not
 * override that method due to visibility issues, e.g. both being package-private but being
 * declared in different packages. This can be an unintentional side-effect of refactoring and
 * the intention might have been for the method to override the other one.
 * 
 * In general it recommended to use `@Override` which would allow spotting this and similar
 * errors.
 * 
 * This query is based on Eclipse IDE's warning "Method does not override package visible method".
 * 
 * @kind problem
 */

import java

from SrcMethod baseMethod, ClassOrInterface baseDeclType, SrcMethod subMethod, ClassOrInterface subDeclType
where
    subMethod.fromSource()
    and baseMethod.getSignature() = subMethod.getSignature()
    and baseDeclType = baseMethod.getDeclaringType()
    and subDeclType = subMethod.getDeclaringType()
    and subDeclType.getASourceSupertype+() = baseDeclType
    and (
        baseMethod.isPackageProtected()
        // If method in subtype is private it is unlikely that this was an accident
        and not subMethod.isPrivate()
        or
        // If method in supertype is private and both methods are in same compilation unit
        // user might erroneously think that private methods can be overriden
        baseMethod.isPrivate()
        and baseDeclType.getCompilationUnit() = subDeclType.getCompilationUnit()
    )
    and not (baseMethod.isStatic() or subMethod.isStatic())
    and not (baseMethod instanceof InitializerMethod)
    // Ignore serialization related methods
    and not baseMethod.hasStringSignature([
        "readObject(ObjectInputStream)",
        "readResolve()",
        "writeObject(ObjectOutputStream)",
        "writeReplace()",
    ])
    and not subMethod.getASourceOverriddenMethod+() = baseMethod
    // Report the method in the closest supertype; avoid reporting multiple overridden methods
    and not exists(Method overriding |
        overriding.getASourceOverriddenMethod+() = baseMethod
        and overriding.getDeclaringType() = subDeclType.getASourceSupertype+()
    )
    and not exists(Method overridden |
        subMethod.getASourceOverriddenMethod+() = overridden
    )
select subMethod, "Has the same signature as $@ in a supertype, but does not override it", baseMethod, "this method"

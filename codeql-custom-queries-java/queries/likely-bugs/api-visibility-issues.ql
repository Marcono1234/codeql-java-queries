/**
 * Finds public API which exposes internal non-public types. This can be confusing for users
 * and might leak internal implementation details.
 * 
 * @kind problem
 * @precision high
 * @problem.severity warning
 */

import java
import lib.Visibility
import lib.TopLevelVisibility

// TODO: RefType has currently no predicate for getting source ancestor, see
// https://github.com/github/codeql/issues/5595
private RefType getASourceAncestor(RefType t) {
    result = t.getASupertype() and result.getSourceDeclaration() != t.getSourceDeclaration()
    or result = getASourceAncestor(t.getASupertype().getSourceDeclaration())
}

private RefType resolveTypeVariable(RefType context, TypeVariable v) {
    exists(ParameterizedType contextOrSupertype, GenericType genericType, int typeVarIndex, RefType tempResolved |
        (
            contextOrSupertype = context
            or contextOrSupertype = getASourceAncestor(context)
        )
        // Only have to resolve variables of generic types, but not of generic callables
        and genericType = v.getGenericType()
        and v = genericType.getTypeParameter(typeVarIndex)
        and genericType = contextOrSupertype.getGenericType()
    |
        tempResolved = contextOrSupertype.getTypeArgument(typeVarIndex)
        and if tempResolved instanceof TypeVariable
        then result = resolveTypeVariable(context, tempResolved)
        else result = tempResolved
    )
}

// TODO: This is one of the deepest nested predicate calls, but it cannot be inlined due to recursion,
// making it pretty inefficient (?)
private RefType getAnExposedType(ClassOrInterface exposingContext, RefType exposed) {
    if exposed instanceof TypeVariable then exists(RefType resolved |
        resolved = resolveTypeVariable(exposingContext, exposed)
    |
        // If resolution failed, then has no result; bound of type variable (if any) will already
        // have been reported at declaration
        if resolved = exposed then none()
        // Otherwise get types from resolved type
        else result = getAnExposedType(exposingContext, resolved)
    )
    else if exposed instanceof Array then result = getAnExposedType(exposingContext, exposed.(Array).getElementType())
    else if exposed instanceof ParameterizedType then exists(ParameterizedType p | p = exposed |
        result = p.getGenericType()
        or result = getAnExposedType(exposingContext, p.getATypeArgument())
    )
    else if exposed instanceof RawType then result = exposed.(RawType).getErasure()
    else if exposed instanceof Wildcard then exists(Wildcard w | w = exposed |
        result = getAnExposedType(exposingContext, w.getLowerBoundType())
        or result = getAnExposedType(exposingContext, w.getUpperBoundType())
    )
    else result = exposed
}

private Element getATypeExposingCallableElement(Callable c, string locationMessage, RefType exposed) {
    (
        c instanceof Method
        and result = c
        and exposed = c.getReturnType()
        and locationMessage = "return type"
    )
    or exists(Parameter p | p = c.getAParameter() |
        result = p
        and exposed = p.getType()
        and locationMessage = "parameter '" + p.getName() + "'"
    )
    or exists(Exception e | e = c.getAnException() |
        result = e
        and exposed = e.getType()
        and locationMessage = "thrown exception"
    )
    or exists(TypeVariable typeVar | typeVar = c.(GenericCallable).getATypeParameter() |
        result = typeVar and exposed = typeVar.getUpperBoundType()
        and locationMessage = "type variable '" + typeVar.getName() + "'"
    )
}

private Method getAnInheritedMethod(ClassOrInterface t) {
    // Don't include method declared by `t`
    result.getDeclaringType() = t.getASourceSupertype+()
    // And there is no override
    and not exists(Method override |
        override.getDeclaringType() = t.getASourceSupertype*()
        and override.getSourceDeclaration().overridesOrInstantiates(result)
    )
}

private Element getAnElementExposedByMember(ClassOrInterface exposingContext, Member m, string locationMessage, RefType exposed) {
    exists(Field f, RefType declaringType |
        f = m
        and declaringType = f.getDeclaringType()
    |
        result = f
        and (
            declaringType = exposingContext and locationMessage = "type of field '" + f.getName() + "'"
            or declaringType = exposingContext.getASourceSupertype+() and locationMessage = "type of inherited field " + declaringType.getName() + "." + f.getName()
        )
        and exposed = f.getType()
    )
    or exists(Method method, RefType declaringType, string locationMessagePrefix, string locationMessageSuffix |
        method = m
        and declaringType = method.getDeclaringType()
    |
        (
            declaringType = exposingContext and locationMessageSuffix = " of method " + method.getStringSignature()
            or method = getAnInheritedMethod(exposingContext) and locationMessageSuffix = " of inherited method " + declaringType.getName() + "." + method.getStringSignature()
        )
        and result = getATypeExposingCallableElement(method, locationMessagePrefix, exposed)
        and locationMessage = locationMessagePrefix + locationMessageSuffix
    )
    or exists(Constructor c, string locationMessagePrefix | c = m |
        c.getDeclaringType() = exposingContext
        and result = getATypeExposingCallableElement(c, locationMessagePrefix, exposed)
        and locationMessage = locationMessagePrefix + " of constructor " + c.getStringSignature()
    )
    /*
     * TODO: Missing inherited member type whose member exposes a type, e.g.:
     * ```java
     * private static class InheritanceBase {
     *     public static class Nested {
     *         public PrivateClass exposingMethod() {
     *             return null;
     *         }
     *     }
     * }
     * 
     * // Inherits member type Nested which exposes PrivateClass through its methods
     * public static class InheritingClass extends InheritanceBase {
     * }
     * ```
     * However, implementing this would prevent inlining predicate. Additionally would require
     * predicate changes because exposingContext would still be the same (e.g. to resolve type
     * variables used by nested inner classes), but declaring type of member would now not be
     * directly related to exposingContext.
     * Additionally would have to adjust type variable resolution logic to account for subclasses
     * of enclosing types, in case type variable comes from enclosing type.
     */
}

// Always use descriptive locationMessage in case exposing element does not exist in source
// (i.e. it is inherited)
private Element getATypeExposingElement(ClassOrInterface exposingContext, Visibility exposingContextVisibility, string locationMessage, RefType exposed, Visibility exposingVisibility, boolean exposedByMember) {
    exists(Member m, Visibility memberVisibility |
        memberVisibility = getMemberVisibility(m)
        and memberVisibility.isProtectedOrHigher()
        and exposedByMember = true
    |
        result = getAnElementExposedByMember(exposingContext, m, locationMessage, exposed)
        // Get the effective visibility last because that appears to be best for performance
        // Use predicate on member visibility to get it as result in case both are protected
        // (but have different declaring types)
        and exposingVisibility = memberVisibility.getLower(exposingContextVisibility)
    )
    or exists(TypeVariable v | v = exposingContext.(GenericType).getATypeParameter() |
        result = v
        and exposed = v.getUpperBoundType()
        and exposingVisibility = exposingContextVisibility
        and exposedByMember = false
        and locationMessage = "type variable '" + v.getName() + "'"
    )
}

bindingset[exposedByMember]
private string getMessage(TopLevelVisibility topLevelVisibilityExposingContext, ClassOrInterface exposed, Visibility exposingVisibility, boolean exposedByMember) {
    exists(Visibility exposedVisibility, string exposingVisibilityMessage, string exposedVisibilityMessage |
        exposedVisibility = getEffectiveVisibility(exposed)
    |
        // Exposed has lower visibility
        if not exposingVisibility.canSee(exposedVisibility)
        then exists(string tempExposingVisibilityMessage |
            tempExposingVisibilityMessage = "visibility '" + exposingVisibility.toString() + "'"
        |
            // When exposed by member, visibility represents the 'effective' visibility, e.g. `public`
            // field of `protected` nested class has effective visibility of `protected`
            if exposedByMember = true then exposingVisibilityMessage = "effective " + tempExposingVisibilityMessage
            else exposingVisibilityMessage = tempExposingVisibilityMessage
            and exposedVisibilityMessage = "visibility '" + exposedVisibility.toString() + "'"
        )
        // Modifier visibility allows access, now check top level visibility
        else exists(TopLevelVisibility topLevelVisibilityExposed |
            topLevelVisibilityExposed = getTopLevelVisibility(exposed)
            and not topLevelVisibilityExposingContext.canSee(topLevelVisibilityExposed)
        |
            exposingVisibilityMessage = "module visibility '" + topLevelVisibilityExposingContext.toString() + "'"
            and exposedVisibilityMessage = "module visibility '" + topLevelVisibilityExposed.toString() + "'"
        )
        and if exposedByMember = true then result = "Exposes type $@ with lower " + exposedVisibilityMessage + " through $@ with " + exposingVisibilityMessage
        else result = "Type with " + exposingVisibilityMessage + " exposes type $@ with lower " + exposedVisibilityMessage + " through $@"
    )
}

/*
 * Don't use TypeAccess for exposingElement (even though it might be more accurate), because:
 * - CodeQL does not provide predicates for getting relevant TypeAccess in all situations,
 *     would have to perform error-prone child checks
 * - Code without source does not appear to have TypeAccess for all situations (would be a
 *     problem for inherited fields or methods)
 */
from ClassOrInterface exposingContext, TopLevelVisibility topLevelVisibilityExposingContext, Visibility exposingContextVisibility, Element exposingElement, string locationMessage, ClassOrInterface exposed, Visibility exposingVisibility, boolean exposedByMember, string message
where
    exposingContext.fromSource()
    and topLevelVisibilityExposingContext = getTopLevelVisibility(exposingContext)
    // `exposingContext` is explicitly or implicitly (as part of unnamed module) exported
    and topLevelVisibilityExposingContext.isVisibleToOtherModules()
    // Ignore test classes (or classes enclosed by test classes)
    and not exposingContext instanceof TestClass
    and exposingContextVisibility = getEffectiveVisibility(exposingContext)
    and exposingContextVisibility.isProtectedOrHigher()
    and exists(RefType exposedTemp |
        exposingElement = getATypeExposingElement(exposingContext, exposingContextVisibility, locationMessage, exposedTemp, exposingVisibility, exposedByMember)
    |
        // Evaluate `getAnExposedType` at highest nesting depth as possible (i.e. in `where` clause)
        // because it is rather expensive and due to being recursive cannot be inlined
        // Because CodeQL evaluates predicates depth-first, this improves performance
        exposed = getAnExposedType(exposingContext, exposedTemp)
    )
    and message = getMessage(topLevelVisibilityExposingContext, exposed, exposingVisibility, exposedByMember)
select exposingContext, message, exposed, exposed.getName(), exposingElement, locationMessage

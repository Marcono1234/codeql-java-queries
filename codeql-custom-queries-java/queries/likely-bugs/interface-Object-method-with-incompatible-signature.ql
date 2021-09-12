/**
 * Finds methods declared by interfaces which have the same signature as a `protected`
 * method of `java.lang.Object` but which has a different return type or exception
 * listed in the `throws` clause. These differences make it impossible to implement
 * the interface because an implementing class would have to satify both the signature
 * of the `Object` method as well as the signature of the interface method, which are
 * incompatible.
 */

 /*
  * Eclipse detects this as:
  * - IncompatibleExceptionInThrowsClauseForNonInheritedInterfaceMethod
  * - IncompatibleReturnTypeForNonInheritedInterfaceMethod
  */

import java

from Interface interface, Method method, Method objectMethod, string problem
where
    interface.fromSource()
    and method.getDeclaringType() = interface
    // Ignore private methods, they don't cause issues
    and method.isPublic()
    and not method.isStatic()
    and objectMethod.getDeclaringType() instanceof TypeObject
    // Ignore public methods, they cannot cause issues
    and not objectMethod.isPublic()
    and method.getSignature() = objectMethod.getSignature()
    and (
        exists(RefType thrownException |
            thrownException = method.getAThrownExceptionType()
            and not thrownException instanceof UncheckedThrowableType
            and not thrownException.getASourceSupertype*() = objectMethod.getAThrownExceptionType()
            and problem = "Declares incompatible thrown exception type " + thrownException.getName()
        )
        or exists(Type returnType, Type objectMethodReturnType |
            returnType = method.getReturnType()
            and objectMethodReturnType = objectMethod.getReturnType()
        |
            returnType != objectMethodReturnType
            and (returnType instanceof RefType implies (
                not returnType.(RefType).getSourceDeclaration().getASourceSupertype*() = objectMethodReturnType
            ))
            and problem = "Declares incompatible return type " + returnType.getName()
        )
        /*
         * Ignored cases:
         * - No `throws` clause, fewer exceptions or more specific exceptions
         * - More specific return type
         */
    )
select method, "Method is incompatible with method declared by Object: " + problem

/**
 * Finds classes which are apparently designed to register a listener (or a
 * similar class) somewhere, but instead of creating an anonmyous class or
 * using a lambda for this, they instead implement the target interface.
 * E.g.:
 * ```java
 * // Bad: Implements Listener interface
 * class Application implements Listener {
 *     public void start() {
 *         component.registerListener(this);
 *     }
 * 
 *     ...
 * }
 * ```
 * This is error-prone and misleading because the class itself does not
 * actually represent a listener and might therefore be misused by other
 * classes. Instead an anonymous class or lambda should be used:
 * ```java
 * class Application {
 *     public void start() {
 *         component.registerListener(new Listener() {
 *             ...
 *         });
 *     }
 * 
 *     ...
 * }
 * ```
 */

/*
 * Note: Query is not very accurate, yields many false positives, and possibly also
 * has some false negatives due to already being rather restrictive
 */

import java

int getAbstractMethodsCount(Interface i) {
    result = count(Method m |
        m.isAbstract()
        and m.getDeclaringType() = i.getASourceSupertype*()
        // Don't count methods multiple times in case they are overridden
        and not exists(Method overriding |
            overriding.getDeclaringType() = i.getASourceSupertype*()
            and overriding.getASourceOverriddenMethod+() = m
        )
    )
}

// Only consider interfaces for listeners to reduce false positives, even though there are
// also listener or 'adapter' classes implementing the methods with no-op behavior
class ListenerInterface extends Interface {
    ListenerInterface() {
        // Assume that only interface with few abstract methods is a listener interface
        getAbstractMethodsCount(this) <= 2
    }
}

// Only consider classes for application classes, don't consider interfaces
from Class applicationClass, ListenerInterface listenerInterface, MethodAccess listenerRegisteringCall, Method listenerRegisteringMethod, Parameter listenerParameter
where
    applicationClass.getASupertype().getSourceDeclaration() = listenerInterface
    // Listener registering call happens in class implementing the listener interface
    and listenerRegisteringCall.getEnclosingCallable().getDeclaringType() = applicationClass
    and listenerRegisteringMethod = listenerRegisteringCall.getMethod()
    // Reduce false positives by only consider methods with one parameter
    and listenerRegisteringMethod.getNumberOfParameters() = 1
    and listenerParameter = listenerRegisteringMethod.getAParameter()
    // `this` is provided as listener
    and exists(ThisAccess thisAccess |
        // Check argument for parameter like this to cover varargs as well
        thisAccess = listenerParameter.getAnArgument() 
        and thisAccess = listenerRegisteringCall.getAnArgument()
        and thisAccess.isOwnInstanceAccess()
    )
    // To reduce false positives make sure that class explicitly implements the
    // interface of the method call parameter
    and listenerParameter.getType().(RefType).getSourceDeclaration() = listenerInterface
select applicationClass, "Implements interface $@ which appears to be a listener interface required for $@ call",
    listenerInterface, listenerInterface.getName(), listenerRegisteringCall, "this"

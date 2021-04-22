/**
 * Finds usage of the `Map` methods of `java.util.Properties` instead of
 * using the specialized methods `getProperty` and `setProperty`.
 * To remain backward compatible `Properties` implements `Map<Object, Object>`.
 * Therefore the Map methods `get` and `put` do not provide any type safety.
 * It would therefore be better to use the specialized `Properties` methods
 * which only allow `String`s.
 *
 * Note however that the `getProperty` method considers the `defaults`
 * Properties (if any) which the `get` method does not.
 */

import java

class TypeProperties extends Class {
    TypeProperties() {
        hasQualifiedName("java.util", "Properties")
    }
}

abstract class PropertiesMethodCallWithAlternative extends MethodAccess {
    PropertiesMethodCallWithAlternative() {
        getReceiverType().getSourceDeclaration().getASourceSupertype*() instanceof TypeProperties
    }

    abstract string getAlternative();
}

class PropertiesGetterMethodCall extends PropertiesMethodCallWithAlternative {
    PropertiesGetterMethodCall() {
        exists(Method m | m = getMethod() |
            m.hasName(["get", "getOrDefault"])
        )
        // Make sure Properties are not misused to store non-String objects
        and forall(Expr arg | arg = getAnArgument() | arg.getType() instanceof TypeString)
    }

    override
    string getAlternative() { result = "Properties.getProperty(...)" }
}

class PropertiesSetterMethodCall extends PropertiesMethodCallWithAlternative {
    PropertiesSetterMethodCall() {
        exists(Method m | m = getMethod() |
            m.hasName("put")
        )
        and getNumArgument() = 2
        // Make sure Properties are not misused to store non-String objects
        and forall(Expr arg | arg = getAnArgument() | arg.getType() instanceof TypeString)
    }

    override
    string getAlternative() { result = "Properties.setProperty(...)" }
}

from PropertiesMethodCallWithAlternative propertiesCall
select propertiesCall, "Should use " + propertiesCall.getAlternative() + " instead"

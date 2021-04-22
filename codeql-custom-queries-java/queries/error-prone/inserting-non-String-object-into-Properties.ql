/**
 * Finds calls to `Map` methods inherited by `java.util.Properties` which are
 * called with non-`String` key or value arguments to insert. The `Properties`
 * class only supports non-`String` keys and values for backward compatibility.
 * It is recommended to avoid non-`String` keys and values because not all
 * libraries might handle them correctly.
 */

import java

class TypeProperties extends Class {
    TypeProperties() {
        hasQualifiedName("java.util", "Properties")
    }
}

class PropertiesInsertingMethod extends Method {
    int insertedParamIndex;
   
    PropertiesInsertingMethod() {
        getDeclaringType().getSourceDeclaration().getASourceSupertype*() instanceof TypeProperties
        and (
            hasName(["compute", "computeIfAbsent", "computeIfPresent"]) and insertedParamIndex = 0 // key
            or hasName("merge") and insertedParamIndex = [0, 1] // key, value
            or hasName(["put", "putIfAbsent"]) and insertedParamIndex = [0, 1] // key, value
            or hasName("replace") and insertedParamIndex = [0, 1, 2] // key, value, new value
        )
    }

    /**
     * Gets the index of the parameter (either map key or value) whose value is inserted
     * into the Properties.
     */
    int getInsertedParamIndex() { result = insertedParamIndex }
}

from MethodAccess insertingCall, PropertiesInsertingMethod insertingMethod, Expr inserted
where
    insertingCall.getMethod() = insertingMethod
    and inserted = insertingCall.getArgument(insertingMethod.getInsertedParamIndex())
    and not inserted.getType() instanceof TypeString
select insertingCall, "Inserts $@ non-String argument into Properties", inserted, "this"

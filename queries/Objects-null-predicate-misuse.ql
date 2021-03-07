/**
 * Finds calls to the `java.util.Objects` methods `isNull` and `nonNull`.
 * These methods only exist to be used as method reference expression,
 * they provide no additional advantage compared to regular null checks
 * using `==` or `!=`.
 */

import java

class TypeObjects extends Class {
    TypeObjects() {
        hasQualifiedName("java.util", "Objects")
    }
}

class MisusedObjectsNullCheckMethod extends Method {
    MisusedObjectsNullCheckMethod() {
        getDeclaringType() instanceof TypeObjects
    }
    
    string getAlternative() {
        hasStringSignature("isNull(Object)") and result = "== null"
        or hasStringSignature("nonNull(Object)") and result = "!= null"
    }
}

from MethodAccess nullCheckCall, MisusedObjectsNullCheckMethod nullCheckMethod
where
    nullCheckCall.getMethod() = nullCheckMethod
    // Ignore method calls reported for method ref expressions
    and not any(MemberRefExpr m).asMethod() = nullCheckCall.getEnclosingCallable()
select nullCheckCall, "Should use `" + nullCheckMethod.getAlternative() + "`"

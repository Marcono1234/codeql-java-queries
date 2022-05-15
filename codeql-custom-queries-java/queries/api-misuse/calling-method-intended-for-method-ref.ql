/**
 * Finds calls to methods which mainly exist to be used by method reference
 * expressions. Calling these methods manually is more verbose than directly
 * performing the operation the method represents. For example instead of
 * calling `Objects.isNull` one should use `== null`.
 */

import java

class TypeObjects extends Class {
    TypeObjects() {
        hasQualifiedName("java.util", "Objects")
    }
}

abstract class MethodIntendedForMethodRef extends Method {
    abstract string getAlternative();
}

class ObjectsNullCheckMethod extends MethodIntendedForMethodRef {
    string alternative;

    ObjectsNullCheckMethod() {
        getDeclaringType() instanceof TypeObjects
        and (
            hasStringSignature("isNull(Object)") and alternative = "== null"
            or hasStringSignature("nonNull(Object)") and alternative = "!= null"
        )
    }

    override string getAlternative() {
        result = alternative
    }
}

class SumMethod extends MethodIntendedForMethodRef {
    SumMethod() {
        getDeclaringType().hasQualifiedName("java.lang", ["Integer", "Long", "Float", "Double"])
        and hasName("sum")
    }

    override string getAlternative() {
        result = "... + ..."
    }
}

class BooleanBinaryOpMethod extends MethodIntendedForMethodRef {
    string alternative;

    BooleanBinaryOpMethod() {
        getDeclaringType().hasQualifiedName("java.lang", "Boolean")
        and (
            // Recommends non-short-circuit alternative because calling Boolean method would also
            // have already evaluated both operands
            hasName("logicalAnd") and alternative = ".. & .."
            or hasName("logicalOr") and alternative = ".. | .."
            or hasName("logicalXor") and alternative = ".. ^ .."
        )
    }

    override string getAlternative() {
        result = alternative
    }
}

from MethodAccess call, MethodIntendedForMethodRef method
where
    call.getMethod() = method
    // Ignore method calls reported for method ref expressions
    and not any(MemberRefExpr m).asMethod() = call.getEnclosingCallable()
select call, "Should use `" + method.getAlternative() + "`"

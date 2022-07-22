/**
 * Finds calls to methods which take an alternative / default value in case the current
 * value does not fulfill certain requirements, for example because it is `null`. Since
 * the default value is not needed in all cases it is often possible to provide a `Supplier`
 * for the default value, to only calculate it when needed. This approach should be
 * preferred because it can be more efficient, especially when the calculation of the
 * default value is expensive. For example:
 * ```java
 * optional.orElse(expensiveCall())
 * // Should be replaced with:
 * optional.orElseGet(() -> expensiveCall())
 * ```
 * 
 * @kind problem
 */

import java

abstract class MethodWithSupplierAlternative extends Method {
    abstract int getArgumentIndex();
    abstract string getAlternative();
}

class OptionalOrElse extends MethodWithSupplierAlternative {
    OptionalOrElse() {
        getDeclaringType().hasQualifiedName("java.util", [
            "Optional",
            "OptionalDouble",
            "OptionalInt",
            "OptionalLong"
        ])
        and hasName("orElse")
    }

    override
    int getArgumentIndex() {
        result = 0
    }

    override
    string getAlternative() {
        result = "orElseGet"
    }
}

class GuavaOptionalOr extends MethodWithSupplierAlternative {
    GuavaOptionalOr() {
        getDeclaringType().hasQualifiedName("com.google.common.base", "Optional")
        and hasStringSignature("or(T)")
    }

    override
    int getArgumentIndex() {
        result = 0
    }

    override
    string getAlternative() {
        result = "or"
    }
}

class ObjectsNonNullElse extends MethodWithSupplierAlternative {
    ObjectsNonNullElse() {
        getDeclaringType().hasQualifiedName("java.util", "Objects")
        and hasName("requireNonNullElse")
    }

    override
    int getArgumentIndex() {
        result = 1
    }

    override
    string getAlternative() {
        result = "requireNonNullElseGet"
    }
}

predicate isCheapCall(MethodAccess call) {
    // Makes assumptions about which methods might be cheap
    exists(Method m | m = call.getMethod().getSourceDeclaration() |
        m.isStatic()
        and m.hasNoParameters()
        or
        m.getName().matches(["get%", "is%", "of"])
        and (
            m.isStatic()
            // Only consider cheap if method is directly called on variable or
            // is own method access, ignore if this is a long method call chain
            or (exists(call.getQualifier()) implies exists(Expr qualifier |
                qualifier = call.getQualifier()
            |
                qualifier instanceof RValue
                or qualifier instanceof InstanceAccess
            ))
        )
        or
        m.getDeclaringType().hasQualifiedName("java.util", "Collections")
    )
}

from MethodAccess c, MethodWithSupplierAlternative m, Expr arg
where
    m = c.getMethod().getSourceDeclaration()
    and arg = c.getArgument(m.getArgumentIndex())
    // Check if argument contains non-cheap expression
    and exists(Expr e |
        e.getParent*() = arg
    |
        e instanceof Call
        and not isCheapCall(arg)
        or
        e instanceof ArrayCreationExpr
        // Ignore creation of empty array
        and not e.(ArrayCreationExpr).getFirstDimensionSize() = 0
    )
select c, "Prefer using " + m.getAlternative() + " with a value supplier instead"

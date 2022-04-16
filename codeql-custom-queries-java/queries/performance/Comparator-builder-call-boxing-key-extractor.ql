/**
 * Finds usage of the `Comparator` building methods `Comparator.comparing(Function)` and
 * `Comparator.thenComparing(Function)` where the key extractor function has a primitive
 * type as result. To avoid unnecessary boxing, one of the specialized primitive builder
 * methods should be used, e.g. `comparingInt` or `thenComparingInt`.
 */

import java

abstract class ComparatorBuilderMethod extends Method {
    ComparatorBuilderMethod() {
        getDeclaringType().getSourceDeclaration().hasQualifiedName("java.util", "Comparator")
    }

    bindingset[resultType]
    abstract string getAlternative(string resultType);
}

class RootComparatorBuilderMethod extends ComparatorBuilderMethod {
    RootComparatorBuilderMethod() {
        isStatic()
        and hasStringSignature("comparing(Function<? super T,? extends U>)")
    }

    override
    bindingset[resultType]
    string getAlternative(string resultType) {
        result = "comparingDouble" and resultType = ["float", "double"]
        or result = "comparingInt" and resultType = ["byte", "short", "int", "char"]
        or result = "comparingLong" and resultType = "long"
    }
}

class ChainComparatorBuilderMethod extends ComparatorBuilderMethod {
    ChainComparatorBuilderMethod() {
        hasStringSignature("thenComparing(Function<? super T,? extends U>)")
    }

    override
    bindingset[resultType]
    string getAlternative(string resultType) {
        result = "thenComparingDouble" and resultType = ["float", "double"]
        or result = "thenComparingInt" and resultType = ["byte", "short", "int", "char"]
        or result = "thenComparingLong" and resultType = "long"
    }
}

from MethodAccess builderCall, ComparatorBuilderMethod builderMethod, Expr keyExtractor, string alternative
where
    builderCall.getMethod().getSourceDeclaration().getASourceOverriddenMethod*() = builderMethod
    and keyExtractor = builderCall.getArgument(0)
    and exists(PrimitiveType resultType |
        alternative = builderMethod.getAlternative(resultType.getName())
    |
        resultType = keyExtractor.(MemberRefExpr).getReferencedCallable().getReturnType()
        or
        // Or lambda expression in which all explicit or implicit return statements return the
        // same primitive numeric type
        // Don't need to consider mixed primitive types because widening boxing is not possible,
        // and also because there is no common supertype which is Comparable
        forex(ReturnStmt returnStmt |
            returnStmt.getEnclosingCallable() = keyExtractor.(LambdaExpr).asMethod()
        |
            resultType = returnStmt.getResult().getType()
        )
    )
select builderCall, "Should use '" + alternative + "' to avoid boxing"

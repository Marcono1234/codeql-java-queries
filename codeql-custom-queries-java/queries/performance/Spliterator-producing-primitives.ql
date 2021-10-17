/**
 * Finds `java.util.Spliterator` implementations whose `tryAdvance` method only produces
 * values of primitive types. To avoid boxing of these values one of the specialized
 * primitive type spliterators, such as `Spliterator.OfInt`, should be implemented
 * instead.
 */

import java

class TypeSpliterator extends Interface {
    TypeSpliterator() {
        hasQualifiedName("java.util", "Spliterator")
    }
}

class TypeAbstractSpliterator extends Class {
    TypeAbstractSpliterator() {
        hasQualifiedName("java.util", "Spliterators$AbstractSpliterator")
    }    
}

class SpliteratorTryAdvanceMethod extends Method {
    SpliteratorTryAdvanceMethod() {
        exists(Method overridden |
            overridden = getSourceDeclaration().getASourceOverriddenMethod*()
            and overridden.getDeclaringType() instanceof TypeSpliterator
            and overridden.hasName("tryAdvance")
        )
    }
}

class ConsumerAcceptMethod extends Method {
    ConsumerAcceptMethod() {
        getSourceDeclaration().getASourceOverriddenMethod*().hasQualifiedName("java.util.function", "Consumer", "accept")
    }
}

class NumericPrimitiveType extends PrimitiveType {
    NumericPrimitiveType() {
        not hasName("boolean")
    }
}

from SpliteratorTryAdvanceMethod tryAdvanceMethod, Parameter consumerParameter
where
    consumerParameter = tryAdvanceMethod.getParameter(0)
    and forex(VarAccess parameterAccess |
        parameterAccess = consumerParameter.getAnAccess()
    |
        // Parameter is only used for `accept(...)` calls with primitives
        exists(MethodAccess acceptCall |
            acceptCall.getMethod() instanceof ConsumerAcceptMethod
            and acceptCall.getQualifier() = parameterAccess
            // Note: Ignore `boolean` because there exists no good primitive iterator alternative for it
            and acceptCall.getArgument(0).getType() instanceof NumericPrimitiveType
        )
    )
    // Only consider direct Spliterator or AbstractSpliterator implementations, otherwise might not be possible to switch
    and exists(RefType supertype |
        supertype = tryAdvanceMethod.getDeclaringType().getASourceSupertype()
    |
        supertype instanceof TypeSpliterator
        or supertype instanceof TypeAbstractSpliterator
    )
select tryAdvanceMethod, "Only produces values of primitive type; should implement primitive type Spliterator instead"

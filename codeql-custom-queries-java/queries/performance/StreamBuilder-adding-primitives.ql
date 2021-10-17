/**
 * Finds usage of `java.util.stream.Stream.Builder` where only values of primitive
 * type added to the builder. To avoid boxing of these values one of the specialized
 * primitive type stream builders, such as `IntStream.Builder`, should be used
 * instead.
 */

import java

class TypeStreamBuilder extends Interface {
    TypeStreamBuilder() {
        hasQualifiedName("java.util.stream", "Stream$Builder")
    }
}

class StreamBuilderAddMethod extends Method {
    StreamBuilderAddMethod() {
        exists(Method overridden |
            overridden = getSourceDeclaration().getASourceOverriddenMethod*()
            and overridden.getDeclaringType() instanceof TypeStreamBuilder
            and overridden.hasName(["accept", "add"])
        )
    }
}

class StreamBuilderBuildMethod extends Method {
    StreamBuilderBuildMethod() {
        exists(Method overridden |
            overridden = getSourceDeclaration().getASourceOverriddenMethod*()
            and overridden.getDeclaringType() instanceof TypeStreamBuilder
            and overridden.hasStringSignature("build()")
        )
    }
}

class NumericPrimitiveType extends PrimitiveType {
    NumericPrimitiveType() {
        not hasName("boolean")
    }
}

from LocalVariableDecl builderVariable
where
    // Builder is only used for adding and building; no other methods are
    // called and builder is not used as argument for call
    forex(VarAccess varAccess | varAccess = builderVariable.getAnAccess() |
        exists(MethodAccess builderCall, Method builderMethod |
            builderCall.getQualifier() = varAccess
            and builderMethod = builderCall.getMethod()
            and (
                builderMethod instanceof StreamBuilderAddMethod
                or builderMethod instanceof StreamBuilderBuildMethod
            )
        )
    )
    and forex(MethodAccess addCall |
        addCall.getQualifier() = builderVariable.getAnAccess()
        and addCall.getMethod() instanceof StreamBuilderAddMethod
    |
        // Note: Ignore `boolean` because there exists no good primitive iterator alternative for it
        addCall.getArgument(0).getType() instanceof NumericPrimitiveType
    )
select builderVariable, "Only primitives are added to this builder; should use primitive type stream builder instead"

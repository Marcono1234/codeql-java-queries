import java

// TODO: Only using `getASourceSupertype*()` won't work for raw types, have to
// get erasure, see https://github.com/github/codeql/issues/5521
private RefType getDeclaringSourceOrASupertype(Member m) {
    result = m.getDeclaringType().getASourceSupertype*().getErasure()
}

/**
 * Class representing an optional value.
 */
abstract class Optional extends Class {
    /**
     * For display purposes only:
     * Gets the name of the method which allows retrieving the value of
     * the optional, or if not present using a supplier to provide the value.
     */
    abstract string getSupplierAlternativeName();
}

/**
 * Class representing an optional generic `Object` value.
 */
abstract class OptionalObject extends Optional {
    /**
     * For display purposes only:
     * Gets the name of the callable which allows creating empty optional instances.
     */
    abstract string getEmptyOptionalCallableName();

    /**
     * For display purposes only:
     * Gets the name of the callable which maps the value, if present.
     */
    abstract string getMapMethodName();
}

/**
 * Callable which creates a new optional from a nullable `Object`.
 */
abstract class NewNullableOptionalCallable extends Callable {
    OptionalObject getOptionalType() {
        result = getDeclaringSourceOrASupertype(this)
    }

    /**
     * Gets the index of the parameter which is used as value.
     */
    int getValueParamIndex() {
        result = 0
    }
}

/**
 * Method which returns a non-empty optional.
 */
class NewNonEmptyOptionalMethod extends Method {
    NewNonEmptyOptionalMethod() {
        exists(RefType declaringType |
            declaringType = getDeclaringType().getSourceDeclaration()
        |
            (
                declaringType instanceof JavaPrimitiveOptional
                or declaringType instanceof JavaObjectOptional
                or declaringType instanceof GuavaOptional
            )
            and hasName("of")
        )
    }
}

/**
 * Instance method which checks whether an optional object has a value.
 */
abstract class OptionalPresenceCheckMethod extends Method {
    /**
     * Result is `true` if the method checks whether the value is present;
     * `false` if it checks whether the value is absent.
     */
    abstract boolean polarity();

    Optional getOptionalType() {
        result = getDeclaringSourceOrASupertype(this)
    }
}

/**
 * Instance method which returns the value of the optional, throwing an
 * exception if no value is present.
 */
abstract class OptionalGetValueMethod extends Method {
}

/**
 * JDK class representing an optional value. This includes the `Object` reference
 * storing `java.util.Optional` as well as the primitive value variants, such as
 * `OptionalInt`.
 */
abstract class JavaOptional extends Optional {
}

/**
 * Instance method of an optional storing an `Object` reference, which either
 * returns the value, or `null` is no value is present.
 */
abstract class OptionalObjectOrNullCall extends MethodAccess {
    OptionalObject getOptionalType() {
        result = getDeclaringSourceOrASupertype(getMethod())
    }
}

/**
 * Class `java.util.Optional`.
 */
class JavaObjectOptional extends JavaOptional, OptionalObject {
    JavaObjectOptional() {
        hasQualifiedName("java.util", "Optional")
    }

    override
    string getEmptyOptionalCallableName() {
        result = "Optional.empty()"
    }

    override
    string getSupplierAlternativeName() {
        result = "Optional.orElseGet(...)"
    }

    override
    string getMapMethodName() {
        result = "Optional.map(...)"
    }
}

class JavaObjectOptionalOfNullableMethod extends NewNullableOptionalCallable, Method {
    JavaObjectOptionalOfNullableMethod() {
        getDeclaringSourceOrASupertype(this) instanceof JavaObjectOptional
        and hasName("ofNullable")
    }
}

class JavaObjectOptionalGetMethod extends OptionalGetValueMethod {
    JavaObjectOptionalGetMethod() {
        getDeclaringSourceOrASupertype(this) instanceof JavaObjectOptional
        and hasStringSignature([
            "get()",
            "orElseThrow()" // Equivalent to get()
        ])
    }
}

class JavaObjectOptionalOrNullCall extends OptionalObjectOrNullCall {
    JavaObjectOptionalOrNullCall() {
        exists(Method m | m = getMethod() |
            getDeclaringSourceOrASupertype(m) instanceof JavaObjectOptional
            and m.hasName("orElse")
        )
        and getArgument(0) instanceof NullLiteral
    }
}

/**
 * JDK class representing an optional primitive value, e.g. `OptionalInt`.
 */
class JavaPrimitiveOptional extends JavaOptional {
    JavaPrimitiveOptional() {
        hasQualifiedName("java.util", [
            "OptionalDouble",
            "OptionalInt",
            "OptionalLong"
        ])
    }

    override
    string getSupplierAlternativeName() {
        result = "Optional.orElseGet(...)"
    }
}

class JavaOptionalPresenceCheckMethod extends OptionalPresenceCheckMethod {
    boolean polarity;

    JavaOptionalPresenceCheckMethod() {
        getDeclaringSourceOrASupertype(this) instanceof JavaOptional
        and (
            hasStringSignature("isEmpty()") and polarity = false
            or hasStringSignature("isPresent()") and polarity = true
        )
    }

    override
    boolean polarity() { result = polarity }
}

class JavaPrimitiveOptionalGetMethod extends OptionalGetValueMethod {
    JavaPrimitiveOptionalGetMethod() {
        getDeclaringType() instanceof JavaPrimitiveOptional
        and hasStringSignature([
            "orElseThrow()", // Exists for all Optional types and is equivalent to their specific methods
            "getAsDouble()", // OptionalDouble
            "getAsInt()", // OptionalInt
            "getAsLong()" // OptionalLong
        ])
    }
}

class GuavaOptional extends Optional, OptionalObject {
    GuavaOptional() {
        hasQualifiedName("com.google.common.base", "Optional")
    }

    override
    string getEmptyOptionalCallableName() {
        result = "Optional.absent()"
    }

    override
    string getSupplierAlternativeName() {
        result = "Optional.or(Supplier)"
    }

    override
    string getMapMethodName() {
        // Note: Not completely identical to Java's Optional; for Guava function must not return null
        result = "Optional.transform(...)"
    }
}

class GuavaOptionalFromNullableMethod extends NewNullableOptionalCallable, Method {
    GuavaOptionalFromNullableMethod() {
        getDeclaringSourceOrASupertype(this) instanceof GuavaOptional
        and hasName("fromNullable")
    }
}

class GuavaOptionalIsPresentMethod extends OptionalPresenceCheckMethod {
    GuavaOptionalIsPresentMethod() {
        getDeclaringSourceOrASupertype(this) instanceof GuavaOptional
        and hasStringSignature("isPresent()")
    }

    override
    boolean polarity() { result = true }
}

class GuavaOptionalOrNullCall extends OptionalObjectOrNullCall {
    GuavaOptionalOrNullCall() {
        exists(Method m | m = getMethod() |
            getDeclaringSourceOrASupertype(m) instanceof GuavaOptional
            and m.hasStringSignature("orNull()")
        )
    }
}

/**
 * Call of a method declared on an optional type, which when invoked on a non-empty
 * optional will have a non-empty optional as result.
 */
class PresentStatePreservingOptionalCall extends MethodAccess {
    Expr inputOptional;

    PresentStatePreservingOptionalCall() {
        exists(Method m | m = getMethod() |
            // Instance methods
            inputOptional = getQualifier()
            and (
                getDeclaringSourceOrASupertype(m) instanceof GuavaOptional
                and (
                    // or(Optional)
                    m.hasName("or") and m.getParameterType(0).(RefType).getSourceDeclaration() instanceof GuavaOptional
                    // transform(Function); unlike JDK's Optional this requires that function result is non-null
                    or m.hasName("transform")
                    or m.hasStringSignature("toJavaUtil()")
                )
                or
                getDeclaringSourceOrASupertype(m) instanceof JavaObjectOptional
                // or(Supplier)
                and m.hasName("or") and m.getParameterType(0).(RefType).getSourceDeclaration().hasName("Supplier")
            )
            // Static methods
            or
            inputOptional = getArgument(0)
            and m.isStatic()
            and m.getDeclaringType() instanceof GuavaOptional
            and m.hasName("toJavaUtil")
        )
    }

    /**
     * Gets the expression representing the optional which is transformed.
     */
    Expr getInputOptional() {
        result = inputOptional
    }
}

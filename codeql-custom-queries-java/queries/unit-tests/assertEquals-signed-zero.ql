/**
 * Finds calls to `assertEquals` methods where one argument is a floating point zero with
 * explicit sign, that is `-0` or `+0`, but where the `assertEquals` method ignores the
 * sign of zero.
 * 
 * Take for example this usage of a JUnit assertion method:
 * ```java
 * assertEquals(-0.0, value, 0.0);
 * ```
 * Here the intention might have been to verify that the value is `-0` (and not `+0`),
 * however this assertion method with additional 'delta' parameter ignores the sign of
 * zero, so it would pass even if the value is unexpectedly `+0`.
 * 
 * @kind problem
 */

 import java

/**
 * `float` or `double` literal 0 with explicit `-` or `+` sign.
 */
class SignedZeroExpr extends UnaryExpr {
    SignedZeroExpr() {
        (
            this instanceof MinusExpr
            or this instanceof PlusExpr
        )
        and (
            this.getExpr().(FloatLiteral).getFloatValue() = 0
            or this.getExpr().(DoubleLiteral).getDoubleValue() = 0
        )
    }
}

// TODO: Maybe use classes from AssertLib.qll?
from MethodAccess assertCall, Method assertMethod, SignedZeroExpr signedZero, int floatingPointParamCount
where
    assertMethod = assertCall.getMethod()
    and assertMethod.hasName("assertEquals")
    and floatingPointParamCount = count(Parameter p | p = assertMethod.getAParameter() and p.getType() instanceof FloatingPointType)
    and (
        assertMethod.getDeclaringType().getQualifiedName() = [
            "org.junit.Assert", // JUnit 4
            "org.junit.jupiter.api.Assertions", // JUnit 5
        ]
        // For JUnit only assertion methods with additional 'delta' parameter are affected (i.e. 3 floating point parameters)
        // Note: JUnit 4 has undocumented behavior where a negative delta causes exact equality check considering the sign,
        // but not going to check for this here
        and floatingPointParamCount = 3
        or
        // TestNG
        assertMethod.getDeclaringType().hasQualifiedName("org.testng", "Assert")
        // For TestNG both regular 2 param method and method with additional 'delta' parameter are affected
        and floatingPointParamCount >= 2
    )
    // Ideally verify that this is the 'actual' or 'expected' parameter, but rather unlikely that signed zero is used as 'delta'
    and assertCall.getAnArgument() = signedZero
select assertCall, "Assertion method ignores sign of $@", signedZero, "this expression"

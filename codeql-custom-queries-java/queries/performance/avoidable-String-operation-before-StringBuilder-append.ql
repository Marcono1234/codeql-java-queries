/**
 * Finds avoidable method calls on `CharSequence` and `String` values before they are appended
 * to a `StringBuilder`. `StringBuilder` offers mutliple convenience methods which avoid creating
 * temporary subsequences or substrings, or which are less verbose to use. If possible, these
 * methods should be preferred.
 *
 * @kind problem
 */

import java
import semmle.code.java.dataflow.DataFlow

abstract class ExprWithAppendAlternative extends Expr {
    abstract Expr getConvertedExpr();
}

class CharSequenceCall extends ExprWithAppendAlternative, MethodAccess {
    CharSequenceCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType().getASourceSupertype*().hasQualifiedName("java.lang", "CharSequence")
        |
            m.hasName([
                // StringBuilder.append alternative with start and end parameters exists
                "subSequence",
                "toString"
            ])
        )
    }

    override
    Expr getConvertedExpr() {
        result = getQualifier()
    }
}

class StringCall extends ExprWithAppendAlternative, MethodAccess {
    boolean isConvertingQualifier;

    StringCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType() instanceof TypeString
        |
            isConvertingQualifier = true and m.hasName([
                "concat",
                "subSequence",
                "substring",
                "toCharArray"
                // Don't consider String.toString(), that is already detected by a built-in CodeQL query
            ])
            or isConvertingQualifier = false and m.hasName([
                "copyValueOf",
                "valueOf"
            ])
        )
    }

    override
    Expr getConvertedExpr() {
        isConvertingQualifier = true and result = getQualifier()
        or isConvertingQualifier = false and result = getArgument(0)
    }
}

class BoxedToStringCall extends ExprWithAppendAlternative, MethodAccess {
    BoxedToStringCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType() instanceof BoxedType
        |
            // Only consider static methods, for instance methods there is no difference
            // in calling it manually or having StringBuilder call it internally
            m.isStatic()
            // Also covers Character.toString(int) (in addition to `toString(char)`)
            and m.hasName([
                "toString",
                // Character.toChars(int)
                "toChars"
            ])
            and m.getNumberOfParameters() = 1
        )
    }

    override
    Expr getConvertedExpr() {
        result = getArgument(0)
    }
}

class StringBuildingCall extends MethodAccess {
    StringBuildingType stringBuildingType;
    int paramIndex;

    StringBuildingCall() {
        exists(Method m |
            m = getMethod()
            and stringBuildingType = m.getDeclaringType()
        |
            m.hasName("append") and paramIndex = 0
            or
            m.hasName("insert") and paramIndex = 1
        )
    } 

    Expr getAppendedArg() {
        result = getArgument(paramIndex)
    }

    string getStringBuildingTypeName() {
        result = stringBuildingType.getName()
    }
}

from ExprWithAppendAlternative expr, Expr convertedExpr, StringBuildingCall stringBuildingCall
where
    DataFlow::localExprFlow(expr, stringBuildingCall.getAppendedArg())
    and convertedExpr = expr.getConvertedExpr()
select expr, "Instead of converting $@ expression and then appending it $@, should instead use specialized " + stringBuildingCall.getStringBuildingTypeName() + " method directly appending its value",
    convertedExpr, "this", stringBuildingCall, "here"

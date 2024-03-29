import java
import semmle.code.java.dataflow.DataFlow

/** An `int` or a `long` literal. */
class IntegralLiteral extends Literal {
    IntegralLiteral() {
        this instanceof IntegerLiteral
        or this instanceof LongLiteral
    }

    /**
     * Gets the value this literal represents. Has no result for `long` literals whose
     * values exceeds the CodeQL int value range.
     */
    int getIntValue() {
        result = this.(IntegerLiteral).getIntValue()
        or result = this.(LongLiteral).getValue().toInt()
    }

    /**
     * Holds if the value of this literal is positive or 0.
     */
    predicate isPositive() {
        this.(IntegerLiteral).getIntValue() >= 0
        // LongLiteral does not have predicate for getting integral value
        or this.(LongLiteral).getValue().toFloat() >= 0
    }
}

/**
 * An expression which performs a bitwise operation.
 */
class BitwiseExpr_ extends Expr {
    BitwiseExpr_() {
        this instanceof BitwiseExpr
        or this instanceof AssignAndExpr
        or this instanceof AssignOrExpr
        or this instanceof AssignXorExpr
        or this instanceof LeftShiftExpr
        or this instanceof AssignLeftShiftExpr
        or this instanceof RightShiftExpr
        or this instanceof AssignRightShiftExpr
        or this instanceof UnsignedRightShiftExpr
        or this instanceof AssignUnsignedRightShiftExpr
    }
}

/**
 * A text block (Java 15 feature).
 */
class TextBlock extends StringLiteral {
    // Detection does not cover all cases, but most cases
    // Ideally this would be part of the standard CodeQL classes, see https://github.com/github/codeql/issues/6619
    TextBlock() {
        // Literal contains line terminator; this is always the case behind the starting """
        // and it is not possible for regular string literals, there line terminator
        // would have to be escaped
        // Would not work if line terminator uses Unicode escape
        getLiteral().matches(["%\n%", "%\r%"])
    }

    /**
     * Gets the line of the literal at index `lineIndex` relative to the first line
     * (starting at 0) as it appeared in source. The opening line containing `"""`
     * followed by a line terminator is not part of the result set.
     * 
     * Trailing backslashes in lines (to continue in the next line) are not treated
     * specially because they are processed during regular escape sequence replacement,
     * after incidental whitespaces have been removed.
     */
    string getLiteralLine(int lineIndex) {
        // Note: Won't work correctly when closing """ uses Unicode escapes or when
        // line terminators use Unicode escapes
        exists(string literal, int index, string rawLine | literal = getLiteral() |
            // lineIndex + 1 because the first line contains no content, only the opening """
            rawLine = literal.regexpFind("(?m)^.*$", lineIndex + 1, index)
            and if (index + rawLine.length() = literal.length()) then (
                // Remove trailing """
                result = rawLine.prefix(rawLine.length() - 3)
            ) else (
                result = rawLine
            )
        )
        // Ignore line containing opening """
        and lineIndex != -1
    }
}

/**
 * An expression which increments or decrements a variable by a fixed value.
 */
class IncrOrDecrExpr extends Expr {
    VarAccess varAccess;
    boolean isIncrementing;
    
    IncrOrDecrExpr() {
        isIncrementing = true
        and varAccess = [
            this.(PreIncExpr).getExpr(),
            this.(PostIncExpr).getExpr()
        ]
        or
        isIncrementing = false
        and varAccess = [
            this.(PreDecExpr).getExpr(),
            this.(PostDecExpr).getExpr()
        ]
        or exists(AssignOp assignOp |
            assignOp = this
            and assignOp.getDest() = varAccess
            and assignOp.getRhs() instanceof Literal
        |
            assignOp instanceof AssignAddExpr and isIncrementing = true
            or assignOp instanceof AssignSubExpr and isIncrementing = false
        )
    }
    
    VarAccess getVarAccess() {
        result = varAccess
    }

    predicate isIncrementing() {
        isIncrementing = true
    }
}

/**
 * Expression which references a callable.
 */
class CallableReferencingExpr extends Expr {
    Callable callable;

    CallableReferencingExpr() {
        callable = this.(Call).getCallee()
        or callable = this.(MemberRefExpr).getReferencedCallable()
    }

    Callable getReferencedCallable() {
        result = callable
    }

    RefType getReceiverType() {
        result = [
            this.(MethodAccess).getReceiverType(),
            this.(MemberRefExpr).getReceiverType(),
            this.(ConstructorCall).getConstructedType(),
        ]
    }

    /**
     * Gets the qualifier of this expression on which the callable is used, if any.
     */
    Expr getQualifier() {
        result = [
            this.(MethodAccess).getQualifier(),
            this.(MemberRefExpr).getReceiverExpr(),
            this.(ClassInstanceExpr).getQualifier(),
        ]
    }
}

private class LeakingExpr extends Expr {
    LeakingExpr() {
        // Leaks by passing it as argument to call
        any(Call c).getAnArgument() = this
        // Leaks by assigning to field
        or any(FieldWrite w).getRhs() = this
        // Leaks by storing in array
        or exists(AssignExpr assign |
            assign.getRhs() = this
            and assign.getDest() instanceof ArrayAccess
        )
        // Leaks by putting in new array
        or any(ArrayInit a).getAnInit() = this
        // Leaks by returning
        or any(ReturnStmt r).getResult() = this
        // Leaks by being captured, e.g. in lambda, inner class, ...
        or exists(LocalScopeVariable var |
            this = var.getAnAssignedValue()
            and var.getAnAccess().getEnclosingCallable() != getEnclosingCallable()
        )
    }
}

/**
 * Holds if there is dataflow from the expression to another expression which might
 * make the value available outside the current callable.
 */
predicate isLeaked(Expr leaked) {
    DataFlow::localFlow(DataFlow::exprNode(leaked), DataFlow::exprNode(any(LeakingExpr e)))
}

/**
 * Holds if the comparison expression compares `operand` with a constant which:
 * - if `equalOrGreater = true`: makes sure that `operand >= value`
 * - if `equalOrGreater = false`: makes sure that `operand < value`
 */
predicate comparesWithConstant(ComparisonExpr compExpr, Expr operand, int value, boolean equalOrGreater) {
    // operand > value - 1
    (
        compExpr.isStrict()
        and compExpr.getGreaterOperand() = operand
        and compExpr.getLesserOperand().(CompileTimeConstantExpr).getIntValue() = value - 1
        and equalOrGreater = true
        // ignore floating point types because `1.5 >= 2` is not the same as `1.5 > 1`
        and not operand.getType() instanceof FloatingPointType
    )
    // operand >= value
    or (
        not compExpr.isStrict()
        and compExpr.getGreaterOperand() = operand
        and compExpr.getLesserOperand().(CompileTimeConstantExpr).getIntValue() = value
        and equalOrGreater = true
    )
    // operand < value
    or (
        compExpr.isStrict()
        and compExpr.getLesserOperand() = operand
        and compExpr.getGreaterOperand().(CompileTimeConstantExpr).getIntValue() = value
        and equalOrGreater = false
    )
    // operand <= value - 1
    or (
        not compExpr.isStrict()
        and compExpr.getLesserOperand() = operand
        and compExpr.getGreaterOperand().(CompileTimeConstantExpr).getIntValue() = value - 1
        and equalOrGreater = false
        // ignore floating point types because `1.5 < 2` is not the same as `1.5 <= 1`
        and not operand.getType() instanceof FloatingPointType
    )
}

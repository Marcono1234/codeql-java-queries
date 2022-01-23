import java

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
        or this instanceof LShiftExpr
        or this instanceof AssignLShiftExpr
        or this instanceof RShiftExpr
        or this instanceof AssignRShiftExpr
        or this instanceof URShiftExpr
        or this instanceof AssignURShiftExpr
    }
}

/**
 * A statement expression, as specified by [JLS 16 §14.8](https://docs.oracle.com/javase/specs/jls/se16/html/jls-14.html#jls-14.8).
 * The result value of a statement expression, if any, is discarded.
 *
 * Not to be confused with `ExprStmt`; while the child of an `ExprStmt` is always
 * a `StmtExpr` the opposite is not true, a `StmtExpr` occurs for example also
 * as 'init' of a `for` statement.
 */
class StmtExpr extends Expr {
    StmtExpr() {
        this = any(ExprStmt s).getExpr()
        or exists(ForStmt forStmt |
            this = forStmt.getAnInit()
            or this = forStmt.getAnUpdate()
        )
        // Only applies to SwitchStmt, but not to SwitchExpr
        or this = any(SwitchStmt s).getACase().getRuleExpression()
        // TODO: Workarounds for https://github.com/github/codeql/issues/3605
        or exists(LambdaExpr lambda |
            this = lambda.getExprBody()
            and lambda.asMethod().getReturnType() instanceof VoidType
        )
        or exists(MemberRefExpr memberRef, Method implicitMethod, Method overridden |
            implicitMethod = memberRef.asMethod()
        |
            this.getParent().(ReturnStmt).getEnclosingCallable() = implicitMethod
            // asMethod() has bogus method with wrong return type as result, e.g. `run(): String` (overriding `Runnable.run(): void`)
            // Therefore need to check the overridden method
            and implicitMethod.getSourceDeclaration().overridesOrInstantiates*(overridden)
            and overridden.getReturnType() instanceof VoidType
        )
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
            this.(MemberRefExpr).getQualifier(),
            this.(ClassInstanceExpr).getQualifier(),
        ]
    }
}

import java

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
        or exists(MemberRefExpr memberRef |
            this.getEnclosingStmt().(ReturnStmt).getEnclosingCallable() = memberRef.asMethod()
            and memberRef.asMethod().getReturnType() instanceof VoidType
        )
    }
}

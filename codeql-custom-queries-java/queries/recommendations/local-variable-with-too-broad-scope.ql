/**
 * Finds local variables which have a too broad scope, i.e. they are declared
 * in a block in which they are not used, but instead are only used in a
 * nested block. E.g.:
 * ```java
 * public String performAction(String name)
 *     // BAD: Variable is used only in block of `if` statement, should be
 *     // declared there
 *     String tempResult;
 * 
 *     if (!name.isEmpty()) {
 *         tempResult = name.trim();
 *         ...
 *     }
 * 
 *     return "";
 * }
 * ```
 * 
 * This can make code more difficult to read and makes IDE code completion
 * less effective because unrelated variables are suggested.
 * 
 * Note that this query might report false positives in cases where a
 * variable is initialized from the result of a method call with side effects,
 * or where the initialization value represents a 'previous value' which would
 * not be accessible otherwise at the location where the variable is read.
 * In such cases moving the variable declaration might not be an option.
 */

import java
import lib.Loops

// Need to use StmtParent instead of BlockStmt as result type because SwitchStmt
// and SwitchExpr do not have BlockStmt as body
StmtParent getScopeBlock(LocalVariableDecl var) {
    // For loop report the body as scope to detect variables declared in loop init
    // which are not used there or directly in loop body
    exists(ForStmt forStmt, LocalVariableDeclExpr varDecl |
        forStmt.getAnInit() = varDecl
        and varDecl.getVariable() = var
        and result = forStmt.getStmt()
    )
    or exists(LocalVariableDeclStmt declStmt |
        declStmt.getAVariable().getVariable() = var
        and result = declStmt.getParent()
        // Ignore try-with-resources variables because they cannot be moved
        and not any(TryStmt tryStmt).getAResourceDecl() = declStmt
    )
    // Don't cover other situations where local variables are declared (e.g. enhanced
    // `for` loop or `catch` clause) since variable cannot be moved in these cases
}

from LocalVariableDecl var, StmtParent scopeBlock, BlockStmt usageBlock
where
    scopeBlock = getScopeBlock(var)
    and usageBlock.getEnclosingStmt+() = scopeBlock
    // Use `forex` to ignore unused variables
    and forex(VarAccess varAccess | varAccess = var.getAnAccess() |
        varAccess.getAnEnclosingStmt() = usageBlock
    )
    and not exists(TryStmt tryStmt |
        tryStmt.getEnclosingStmt+() = scopeBlock
        and (
            /*
             * Ignore `try` statements where variable is declared in parent and
             * then only used in block of `try` statement
             * `try` block should include as few expressions as possible to prevent
             * catching unrelated exceptions
             */
            tryStmt.getBlock() = usageBlock.getEnclosingStmt*()
            // Ignore `try` statements which seem to use variable to restore state
            // in `finally` block
            or tryStmt.getFinally() = usageBlock.getEnclosingStmt*()
        )
    )
    // Ignore `synchronized` statements since they should contain as few
    // expressions as possible to release the lock faster again
    and not exists(SynchronizedStmt syncStmt |
        syncStmt.getBlock() = usageBlock.getEnclosingStmt*()
        and syncStmt.getEnclosingStmt+() = scopeBlock
    )
    // Ignore if usage only occurs in loop body, then for performance reasons
    // variable value should not be evaluated every iteration, or if variable
    // is reassigned in loop
    and not exists(LoopStmt loopStmt |
        loopStmt.getBody() = usageBlock.getEnclosingStmt*()
        and loopStmt.getEnclosingStmt+() = scopeBlock
        // TODO: Refactor with Loops lib
        // Only consider loop if there is a var access after which the loop does not terminate
        // (Ignore cases where variable is used to create return value or exception message)
        and exists(VarAccess varAccess | varAccess = var.getAnAccess() |
            varAccess.getControlFlowNode().getASuccessor+() = getLoopEntryNode(loopStmt)
        )
    )
select var, "Variable is only used in $@ block and should therefore be declared there", usageBlock, "this"

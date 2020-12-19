/**
 * Finds block statements (`{ ... }`) which are too close to other statements
 * which usually have a block statement as body and could therefore be
 * misleading, e.g.:
 * ```
 * if (isActive) performTask();
 * {
 *   System.out.println("Test");
 * }
 * ```
 * Here the reader might think that the block statement is the body of the
 * `if` statement, but it actually is a standalone block which is always
 * executed.
 */

import java

class StmtWithBody extends Stmt {
    Stmt body;
    
    StmtWithBody() {
        body = [
            this.(CatchClause).getBlock(),
            this.(IfStmt).getThen(),
            this.(IfStmt).getElse(),
            this.(LabeledStmt).getStmt(),
            this.(LoopStmt).getBody(),
            this.(SwitchCase).getRuleStatement(),
            this.(SwitchStmt).getAStmt(),
            this.(SynchronizedStmt).getBlock(),
            this.(TryStmt).getBlock()
        ]
    }
    
    Stmt getBody() {
        result = body
    }
}

from BlockStmt block, StmtWithBody other
where
    block.getParent() instanceof BlockStmt
    // Ignore initializer blocks
    and not exists (InitializerMethod init |
        block.getEnclosingStmt() = init.getBody()
    )
    and other != block
    and other.getBody() != block
    and other.getParent() = block.getParent()
    and other.getIndex() < block.getIndex()
    and other.getTotalNumberOfLines() = 1
    // Block statement starts in same line or line after other statement
    and block.getLocation().getStartLine() <= other.getLocation().getEndLine() + 1
select block, "Block statement is misleading because it appears too close to $@ statement", other, "this"

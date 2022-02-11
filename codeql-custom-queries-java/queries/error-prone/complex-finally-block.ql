/**
 * Finds `finally` blocks of `try` statements which are complex. `finally` blocks are
 * called even when exceptions occur; it is therefore often desired that `finally` blocks
 * complete fast to not hinder exception handling. Additionally with complex `finally`
 * blocks it is more likely that by accident the block is left abnormally, e.g. by throwing
 * an exception or using a `return` statement. In that case when an exception occurred
 * before the `finally` block was executed the exception will silently be discarded.
 * 
 * See also CodeQL's query `java/abnormal-finally-completion`.
 */

import java

from TryStmt tryStmt, BlockStmt finallyBlock
where
    finallyBlock = tryStmt.getFinally()
    and count(Stmt stmt | stmt.getEnclosingStmt+() = finallyBlock) > 15
select finallyBlock, "Complex `finally` block"

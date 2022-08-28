/**
 * Finds `if` statements with a long 'then' block but a short 'else' block. Such code can
 * decrease readability because the code of the 'else' block is rather far away from the
 * condition, making it more difficult to directly understand the logic of the code.
 * If possible (and the readability does not suffer), it might be good to invert the
 * condition of the `if` statement and switch the 'then' and 'else' blocks. For example:
 * ```java
 * if (i < 5) {
 *     ... many lines of code
 * } else {
 *     doSomething();
 * }
 * ```
 * Could be changed to:
 * ```java
 * if (i >= 5) {
 *     doSomething();
 * } else {
 *     ... many lines of code
 * }
 * ```
 * 
 * @kind problem
 */

import java

int getNumberOfLines(Stmt s) {
    exists(Location l | l = s.getLocation() |
        result = l.getEndLine() - l.getStartLine() + 1
    )
}

predicate isShortStatement(Stmt elseStmt) {
    if (elseStmt instanceof BlockStmt) then (
        getNumberOfLines(elseStmt) < 5
    )
    // Non block statement is short, except if this is an `if ... else if ...` chain
    else not elseStmt instanceof IfStmt
}

from IfStmt ifStmt
where
    getNumberOfLines(ifStmt.getThen()) >= 20
    and isShortStatement(ifStmt.getElse())
    // Ignore in case this is part of `if ... else if ...`
    and not any(IfStmt s).getElse() = ifStmt
select ifStmt, "Should switch 'then' and 'else' to make code easier to read"

/**
 * Finds statements which start on the same line as the end of a multi-line statement.
 * This might indicate broken formatting which can make the code difficult to read,
 * or it might indicate a logic error, e.g. a separate `if` statement instead of
 * `else if`:
 * ```java
 * if (conditionA()) {
 *     ...
 * } if (conditionB()) {
 * //^ was supposed to be `else if`
 *    ...
 * }
 * ```
 * 
 * @kind problem
 */

import java

from Stmt first, Location firstLocation, Stmt second, Location secondLocation
where
    // This also excludes implicit statements in lambdas which are compared without statement outside of it
    first.getEnclosingCallable() = second.getEnclosingCallable()
    and firstLocation = first.getLocation()
    and secondLocation = second.getLocation()
    // Make sure both are in the same file to prevent false positives when CodeQL has for some reason extracted
    // different files with the same classes
    and firstLocation.getFile() = secondLocation.getFile()
    and firstLocation.getEndLine() = secondLocation.getStartLine()
    and firstLocation.getEndColumn() < secondLocation.getStartColumn()
    // To reduce false positives only consider statements spanning over more than one line
    and firstLocation.getStartLine() < firstLocation.getEndLine()
    // Ignore all kinds of statements which intentionally start on the same line
    and not (
        first.getParent+() = second
        or second.getParent+() = first
        or first instanceof SwitchCase
        // Empty statement is already covered by other queries
        or second instanceof EmptyStmt
        // Ignore false positives caused implicit parent constructor invocations
        or second = any(Callable c).getBody()
        // Ignore implicit statements when declaring enum constants
        or any(EnumConstant c).getAnAccess().(FieldWrite).getAnEnclosingStmt() = second
        // Ignore if statements where both statements can be a block without either being the parent of the other
        or exists(IfStmt ifStmt |
            first = ifStmt.getThen()
            and (
                second = ifStmt.getElse()
                or second.getParent() = ifStmt.getElse()
            )
        )
        // Ignore try statements where both statements can be a block without either being the parent of the other
        or exists(TryStmt tryStmt |
            first = tryStmt.getBlock()
            or first = tryStmt.getACatchClause().getBlock()
        |
            second = tryStmt.getACatchClause()
            // Use getParent() to also consider catch block statements at the same line as catch clause
            or second.getParent*() = tryStmt.getACatchClause().getBlock()
            or second = tryStmt.getFinally()
        )
        // Ignore try resource variable declaration
        or exists(TryStmt tryStmt |
            first = tryStmt.getAResourceDecl()
        |
            second = tryStmt.getBlock()
            or second = tryStmt.getAResourceDecl()
        )
        // Ignore jump statments, they are probably not as irritating if one the same line
        or second instanceof JumpStmt
        // Ignore single statement in block
        or any(SingletonBlock s).getStmt() = second.(ExprStmt)
        // Avoid duplicate results for statements with block
        or any(IfStmt s).getThen() = second
        or any(LoopStmt s).getBody() = second
        or any(TryStmt s).getBlock() = second
    )
    // Ignore Kotlin source code for now, the cases to ignore defined above don't seem to work there properly
    and not first.getCompilationUnit().isKotlinSourceFile()
select second, "Starts on the same line as end of $@", first, "this statement"

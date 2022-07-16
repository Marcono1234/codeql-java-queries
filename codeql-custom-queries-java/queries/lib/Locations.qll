import java

/**
 * Holds if location `a` occurs before location `b` (assuming both are in the
 * same file).
 */
predicate isBefore(Location a, Location b) {
    a.getStartLine() < b.getStartLine()
    or (
        a.getStartLine() = b.getStartLine()
        and a.getStartColumn() < b.getStartColumn()
    )
}

/**
 * Finds access to the elements of a multidimensional array which might not be cache friendly.
 * CPUs cache data to speed up repeated access to the same memory region. When iterating over
 * a multidimensional array, it might therefore be faster to process rows as a whole to read
 * the consecutive data of the inner arrays before moving to the next column. For example:
 * ```java
 * int[][] values = ...;
 * 
 * // Possibly inefficient; array elements are accessed with [x][y], therefore for each
 * // iteration the contents of a separate array are accessed
 * for (int y = 0; y < maxY; y++) {
 *     for (int x = 0; x < maxX; x++) {
 *         int value = values[x][y];
 *         ...
 *     }
 * }
 * 
 * // Instead loops should first iterate over `x`, then over `y`:
 * for (int x = 0; x < maxX; x++) {
 *     for (int y = 0; y < maxY; y++) {
 *         int value = values[x][y];
 *         ...
 *     }
 * }
 * ```
 * 
 * However, in general it might be good to measure the performance to check the performance
 * impact this has.
 * 
 * @kind problem
 */

import java

Variable getLoopVariable(LoopStmt l) {
    l.getCondition().getAChildExpr+() = result.getAnAccess()
}

from LoopStmt outer, Variable outerVar, LoopStmt inner, Variable innerVar, ArrayAccess outerAccess, ArrayAccess innerAccess
where
    // Only consider if loops are directly nested to reduce false positives where loop order
    // cannot be easily changed
    (
        inner = outer.getBody()
        or inner = outer.getBody().(SingletonBlock).getStmt()
    )
    and outerVar = getLoopVariable(outer)
    and outerVar.getType() instanceof NumericType
    and innerVar = getLoopVariable(inner)
    and innerVar.getType() instanceof NumericType
    and outerAccess = innerAccess.getArray()
    and outerAccess.getAnEnclosingStmt() = inner.getBody()
    and outerAccess.getIndexExpr().getAChildExpr*() = innerVar.getAnAccess()
    and innerAccess.getIndexExpr().getAChildExpr*() = outerVar.getAnAccess()
select innerAccess, "This array access might not be cache friendly"

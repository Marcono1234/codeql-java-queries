/**
 * Finds double checked locking to initialize a non-`volatile` field
 * of type `double` or `long`:
 * ```
 * class LazyInitialized {
 *     private long value;
 *
 *     public long getValue() {
 *         if (value == 0) {
 *             synchronized (this) {
 *                 if (value == 0) {
 *                     value = ...;
 *                 }
 *             }
 *         }
 *         ...
 *     }
 * }
 * ```
 * This is not thread-safe because `double` and `long` values are
 * 64-bit large and therefore a write might not be atomic (see 
 * JLS 14 §17.7. "Non-Atomic Treatment of `double` and `long`").
 * It could therefore happen that a thread sees a partially initialized
 * value. To solve this the field should be made `volatile`.
 *
 * See https://docs.oracle.com/javase/specs/jls/se14/html/jls-17.html#jls-17.7
 */

import java

class DefaultValue extends Literal {
    DefaultValue() {
        this.(IntegerLiteral).getIntValue() = 0
        or this.(DoubleLiteral).getValue() = "0.0"
        or this.(LongLiteral).getValue() = "0"
    }
}

/**
 * Returns `true` if the condition checks for default value equality,
 * or `false` if it checks for default value inequality.
 */
boolean defaultValueCheck(Field field, EqualityTest conditionExpr) {
    conditionExpr.getAnOperand() = field.getAnAccess()
    and conditionExpr.getAnOperand() instanceof DefaultValue
    and result = conditionExpr.polarity()
}

from Field f, ConditionNode firstCheck, ConditionNode secondCheck, VariableAssign assign
where
    not f.isVolatile()
    and f.getType().hasName(["double", "long"])
    and assign.getDestVar() = f
    // Make sure they are not part of the same statement; assume there is some
    // kind of synchronization between them
    and firstCheck.getCondition().getEnclosingStmt() != secondCheck.getCondition().getEnclosingStmt()
    // Ignore loops because there check after assign is considered before assign in next iteration
    and not assign.getEnclosingStmt().getEnclosingStmt*() instanceof LoopStmt
    and firstCheck.getABranchSuccessor(defaultValueCheck(f, firstCheck.getCondition())).getANormalSuccessor*() = secondCheck
    and secondCheck.getABranchSuccessor(defaultValueCheck(f, secondCheck.getCondition())).getANormalSuccessor*() = assign
select f, firstCheck
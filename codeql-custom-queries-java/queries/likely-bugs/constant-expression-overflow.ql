/**
 * Finds constant expressions which overflow. Most likely this is a bug and the
 * value should be of type `long` to avoid overflow.
 * For example:
 * ```java
 * long timeout = 1000 * 1000 * 1000 * 1000; // Overflows, actual value is: -727379968
 * 
 * // Should instead convert one value to long (e.g. by adding `L`):
 * long timeout = 1000L * 1000 * 1000 * 1000;
 * ```
 * 
 * @kind problem
 */

// Currently only checks `int` constants but not `long` because CodeQL has no 64-bit integer type

import java

from BinaryExpr overflowingExpr
where
  // Positive to negative (addition): +a + +b = -c
  (
    overflowingExpr instanceof AddExpr
    and overflowingExpr.getLeftOperand().(CompileTimeConstantExpr).getIntValue() > 0
    and overflowingExpr.getRightOperand().(CompileTimeConstantExpr).getIntValue() > 0
    and overflowingExpr.(CompileTimeConstantExpr).getIntValue() <= 0
  )
  // Negative to positive (addition): -a + -b = +c
  or (
    overflowingExpr instanceof AddExpr
    and overflowingExpr.getLeftOperand().(CompileTimeConstantExpr).getIntValue() < 0
    and overflowingExpr.getRightOperand().(CompileTimeConstantExpr).getIntValue() < 0
    and overflowingExpr.(CompileTimeConstantExpr).getIntValue() >= 0
  )
  // Negative to positive (subtraction): -a - +b = +c
  or (
    overflowingExpr instanceof SubExpr
    and overflowingExpr.getLeftOperand().(CompileTimeConstantExpr).getIntValue() < 0
    and overflowingExpr.getRightOperand().(CompileTimeConstantExpr).getIntValue() > 0
    and overflowingExpr.(CompileTimeConstantExpr).getIntValue() >= 0
    // Ignore expressions like `(1 << 31) - 1`
    and not overflowingExpr.getLeftOperand() instanceof LeftShiftExpr
  )
  // Multiplication overflow
  or exists(int left, int right |
    overflowingExpr instanceof MulExpr
    and left = overflowingExpr.getLeftOperand().(CompileTimeConstantExpr).getIntValue()
    and right = overflowingExpr.getRightOperand().(CompileTimeConstantExpr).getIntValue()
    and (
      left > 0 and right > 0 and right > 2147483647 / left
      or
      // Divide by positive value here and below to avoid overflow (e.g. -2147483648 / -1 overflows)
      left > 0 and right < 0 and right < -2147483648 / left
      or
      left < 0 and right > 0 and left < -2147483648 / right
      or
      // Checks 2147483647 because minus * minus = plus
      left < 0 and right < 0 and right < 2147483647 / left
    )
  )
select overflowingExpr, "Value of this constant expression overflows"

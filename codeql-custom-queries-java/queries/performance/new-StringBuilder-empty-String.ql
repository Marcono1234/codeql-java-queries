/**
 * Finds creation of `StringBuilder` and `StringBuffer` with an empty String.
 * These constructors use the initial capacity of 16 + the length of the given
 * String. Thus providing an empty String creates a new builder with capacity
 * 16, which is the same capacity as the one of the no-arg constructors.
 * Therefore the no-arg constructors should be used instead.
 */

import java

from ClassInstanceExpr newExpr, StringBuildingType stringBuildingType
where
    stringBuildingType = newExpr.getConstructedType()
    // Only consider literals, ignore compile time constants
    and newExpr.getArgument(0).(StringLiteral).getRepresentedString().length() = 0
select newExpr, "Should create " + stringBuildingType.getName() + " without arguments"

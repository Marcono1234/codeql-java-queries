/**
 * Finds usage of numeric subtraction or addition to calculate the result for
 * the `compareTo` method. Such an implementation is error-prone because it
 * can lead to overflow for integral types and to precision loss for floating
 * point types, causing incorrect results. Instead the static `compare` methods
 * of the boxed types, e.g. `Integer.compare(int, int)`, should be used.
 * 
 * This is described in the book "Effective Java", Third Edition, Item 14.
 */

import java
import semmle.code.java.dataflow.DataFlow

from Method compareToMethod, BinaryExpr arithExpr, ReturnStmt returnStmt
where
    // Consider all methods which appear to perform comparison, not only Comparable.compareTo implementations
    compareToMethod.hasName(["compare", "compareTo"])
    and compareToMethod.getReturnType().hasName("int")
    and arithExpr.getEnclosingCallable() = compareToMethod
    and (
        arithExpr instanceof AddExpr
        or arithExpr instanceof SubExpr
    )
    // Make sure result is numeric (ignore string concatenation)
    and arithExpr.getType() instanceof NumericType
    // Only consider types where overflow can occur; smaller types, e.g. `short`, will have `int` as operation result
    and arithExpr.getAnOperand().getType().hasName(["int", "Integer", "long", "Long", "float", "Float", "double", "Double"])
    and returnStmt.getEnclosingCallable() = compareToMethod
    and DataFlow::localExprFlow(arithExpr, returnStmt.getResult())
select arithExpr, "Could lead to overflow; prefer using the static `compare` method of the boxed type"

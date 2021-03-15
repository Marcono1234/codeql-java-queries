/**
 * Finds expressions which clone arrays in a complicated way which can be simplified
 * by using either the `clone()` method which every array class implements, or using
 * `java.util.Arrays.copyOf(...)` or `copyOfRange(...)`.
 *
 * For example:
 * ```
 * int[] data;
 *
 * int[] getData() {
 *     // Can be simplified to `return data.clone();`
 *     int[] copy = new int[data.length];
 *     System.arraycopy(data, 0, copy, 0, data.length);
 *     return copy;
 * }
 * ```
 */

import java
import semmle.code.java.dataflow.DataFlow

abstract class ArrayCloningExpr extends MethodAccess {
    abstract string getAlternative();
}

// TODO: Could cause false positives when `array` is a field and
//       multiple instances of declaring class are processed, then
//       length reading might not correspond to same array instance
Expr getArrayLengthExpr(Variable array) {
    (
        result.(FieldAccess).getQualifier() = array.getAnAccess()
        and result.(FieldAccess).getField().hasName("length")
    )
    or exists (Method m | m = result.(MethodAccess).getMethod() |
        result.(MethodAccess).getArgument(0) = array.getAnAccess()
        and m.getDeclaringType().hasQualifiedName("java.lang.reflect", "Array")
        and m.hasStringSignature("getLength(Object)")
    )
}

predicate flowsLengthToExpr(Variable array, Expr dest) {
    // TODO: Reduce false positives by making sure length is not changed
    //       E.g. concat method might sum array lengths
    DataFlow::localFlow(DataFlow::exprNode(getArrayLengthExpr(array)), DataFlow::exprNode(dest))
}

/** Usage of System.arraycopy */
class ArraycopyExpr extends ArrayCloningExpr {
    Variable array;
    string alternative;
    
    ArraycopyExpr() {
        getMethod().getDeclaringType() instanceof TypeSystem
        and getMethod().hasStringSignature("arraycopy(Object, int, Object, int, int)")
        // 0 as start destination index
        and getArgument(3).(CompileTimeConstantExpr).getIntValue() = 0
        and DataFlow::localFlow(DataFlow::exprNode(array.getAnAccess()), DataFlow::exprNode(getArgument(0)))
        and exists (ArrayCreationExpr newArrayExpr, Expr newArrayLengthExpr, Expr copyLengthExpr |
            DataFlow::localFlow(DataFlow::exprNode(newArrayExpr), DataFlow::exprNode(getArgument(2)))
            and newArrayLengthExpr = newArrayExpr.getDimension(0)
            and copyLengthExpr = getArgument(4)
        |
            // 0 as start source index
            if (getArgument(1).(CompileTimeConstantExpr).getIntValue() = 0) then (
                if (
                    // Destination is created with same length as source
                    flowsLengthToExpr(array, newArrayLengthExpr)
                    and (
                        // source length flows to copy length argument
                        flowsLengthToExpr(array, copyLengthExpr)
                        // or destination length flows to copy length argument
                        or exists (Variable destination |
                            destination.getAnAssignedValue() = newArrayExpr
                            and flowsLengthToExpr(destination, newArrayLengthExpr)
                        )
                    )
                ) then (
                    alternative = "array.clone()"
                ) else (
                    // copyOf allows length > array.length, so it is applicable even when destination
                    // is supposed to be larger
                    // TODO: Can cause false positives when length < array.length, and dest.length > length
                    //       then Arrays.copyOf is not an alternative
                    alternative = "Arrays.copyOf(...)"
                )
            ) else (
                // copyOfRange allows length > array.length, so it is applicable even when destination
                // is supposed to be larger
                // TODO: Can cause false positives when length < array.length, and dest.length > length
                //       then Arrays.copyOfRange is not an alternative
                alternative = "Arrays.copyOfRange(...)"
            )
        )
    }
    
    override string getAlternative() {
        result = alternative
    }
}

class TypeArrays extends Class {
    TypeArrays() {
        hasQualifiedName("java.util", "Arrays")
    }
}

/** Usage of Arrays.copyOf or Arrays.copyOfRange */
class ArraysCopyExpr extends ArrayCloningExpr {
    Variable array;
    Method m;
    string alternative;
    
    ArraysCopyExpr() {
        m = getMethod()
        and m.getDeclaringType() instanceof TypeArrays
        and (
            (
                m.hasName("copyOf")
                and m.getNumberOfParameters() = 2
                and flowsLengthToExpr(array, getArgument(1))
                and alternative = "array.clone()"
            )
            or (
                m.hasName("copyOfRange")
                and m.getNumberOfParameters() = 3
                // 0 as start index
                and getArgument(1).(CompileTimeConstantExpr).getIntValue() = 0
                and if flowsLengthToExpr(array, getArgument(2)) then (
                    alternative = "array.clone()"
                ) else (
                    alternative = "Arrays.copyOf(...)"
                )
            )
        )
        and DataFlow::localFlow(DataFlow::exprNode(array.getAnAccess()), DataFlow::exprNode(getArgument(0)))
    }
    
    override string getAlternative() {
        result = alternative
    }
}

from ArrayCloningExpr cloningExpr
select cloningExpr, "Can use " + cloningExpr.getAlternative() + " instead."

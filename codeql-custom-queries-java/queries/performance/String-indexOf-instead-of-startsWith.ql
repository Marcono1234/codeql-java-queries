/**
 * Finds calls to one of the `String.indexOf` methods which check if
 * the String starts with a given substring (or has a specific character
 * at the beginning). Usage of `indexOf` for this task is rather
 * inefficient because even if the String does not start with the
 * substring, it goes through the complete String to find the substring,
 * even though the caller is not interested in this information.
 * E.g.:
 * ```java
 * // Should use `s.startsWith("prefix")`
 * if (s.indexOf("prefix") == 0) {
 *     ...
 * }
 * ```
 */

import java

class IndexOfCall extends MethodAccess {
    int startIndex;
    
    IndexOfCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType() instanceof TypeString
            // Consider all `indexOf` methods, even the ones taking a char or code point
            // For those an alternative might also be `charAt` or `codePointAt` (guarded by String length check)
            and m.hasName("indexOf")
        |
            // Implicitly starts at index 0
            m.getNumberOfParameters() = 1 and startIndex = 0
            // Or has explicit start index
            or m.getNumberOfParameters() = 2 and startIndex = getArgument(1).(IntegerLiteral).getIntValue()
        )
    }
    
    int getStartIndex() {
        result = startIndex
    }
}

// TODO: Also consider assignment to local variable
// TODO: Move this to QL library, then reuse for List
// TODO: For List could also check for lastIndexOf() == size() - 1 instead of get(size() - 1).equals... (though lastIndexOf usage also covers empty List, maybe on purpose)
from IndexOfCall indexOfCall, EqualityTest eqTest, string alternative
where
    eqTest.getAnOperand() = indexOfCall
    // Consider index value because `startsWith` overload with start index exists as well
    and eqTest.getAnOperand().(IntegerLiteral).getIntValue() = indexOfCall.getStartIndex()
    and if eqTest.polarity() = true then alternative = "startsWith(...)" else alternative = "!startsWith(...)"
select eqTest, "Should use " + alternative + " instead of indexOf check"

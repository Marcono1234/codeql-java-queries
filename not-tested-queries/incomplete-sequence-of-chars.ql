/**
 * Finds incomplete sequences of characters, e.g.:
 * ```
 * // Is missing the 4
 * String digits = "123567890";
 * ```
 */

import java

predicate areConsecutiveCharsLower(string first, string second) {
    (first = "a" and second = "b")
    or (first = "b" and second = "c")
    or (first = "c" and second = "d")
    or (first = "d" and second = "e")
    or (first = "e" and second = "f")
    or (first = "f" and second = "g")
    or (first = "g" and second = "h")
    or (first = "h" and second = "i")
    or (first = "i" and second = "j")
    or (first = "j" and second = "k")
    or (first = "k" and second = "l")
    or (first = "l" and second = "m")
    or (first = "m" and second = "n")
    or (first = "n" and second = "o")
    or (first = "o" and second = "p")
    or (first = "p" and second = "q")
    or (first = "q" and second = "r")
    or (first = "r" and second = "s")
    or (first = "s" and second = "t")
    or (first = "t" and second = "u")
    or (first = "u" and second = "v")
    or (first = "v" and second = "w")
    or (first = "w" and second = "x")
    or (first = "x" and second = "y")
    or (first = "y" and second = "z")
    or (first = "0" and second = "1")
    or (first = "1" and second = "2")
    or (first = "2" and second = "3")
    or (first = "3" and second = "4")
    or (first = "4" and second = "5")
    or (first = "5" and second = "6")
    or (first = "6" and second = "7")
    or (first = "7" and second = "8")
    or (first = "8" and second = "9")
    or (first = "9" and second = "0")
}

predicate isDigit(string char) {
    char = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
}

predicate isAlphabetic(string char) {
    char = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
}

bindingset[a, b]
predicate areSameType(string a, string b) {
    (isDigit(a) and isDigit(b))
    or (isAlphabetic(a.toLowerCase()) and isAlphabetic(b.toLowerCase()))
}

bindingset[first, second]
predicate areConsecutiveChars(string first, string second) {
    areConsecutiveCharsLower(first, second)
    or (
        first.isUppercase() and second.isUppercase()
        and areConsecutiveCharsLower(first.toLowerCase(), second.toLowerCase())
    )
}

bindingset[first]
string getSubsequentChar(string first) {
    if (first.isLowercase()) then (
        areConsecutiveCharsLower(first, result)
    ) else exists (string secondLower |
            areConsecutiveCharsLower(first.toLowerCase(), secondLower)
            and result = secondLower.toUpperCase()
    )
}

predicate isAllowedLastChar(string last) {
    last = [
        "f", // Last hex digit
        "z",
        "0",
        "9"
    ]
}

predicate hasSequenceStart(IncompleteSequenceExpr expr) {
    // Check first 3 chars, otherwise causes too much negatives, e.g. for "delete", "no", ...
    exists (string first, string second, string third |
        first = expr.charAt(0)
        and second = expr.charAt(1)
        and third = expr.charAt(2)
    |
        areConsecutiveChars(first, second)
        and areConsecutiveChars(second, third)
    )
    // Exclude words containing three or more consecutive chars
    and not expr.getString().toLowerCase().matches([
        "default%",
        "stub%"
    ])
}

abstract class IncompleteSequenceExpr extends Expr {
    abstract string getString();
    abstract string charAt(int index);
    abstract int length();
    
    string getMissingChar(int index) {
        exists (string previousCorrect, string lastCorrect |
            previousCorrect = charAt(index - 2)
            and lastCorrect = charAt(index - 1)
            // Make sure that there is a consecutive char in front, otherwise
            // sequence which then later has other chars causes false positives
            // e.g. "abc-15-15" would find matches for "15" (-> "12")
            and areConsecutiveChars(previousCorrect, lastCorrect)
            and result = getSubsequentChar(lastCorrect)
        |
            exists (string incorrect |
                incorrect = charAt(index)
            |
                // Verify that both chars are of the same type; ignore somthing like "12.0", "ABC-123"
                areSameType(lastCorrect, incorrect)
                and not areConsecutiveChars(lastCorrect, incorrect)
                and (
                    index = length() - 1
                    // Char was skipped, e.g. "abcd_f"
                    or areConsecutiveChars(result, incorrect)
                    // Duplicate char
                    or (
                        index <= length() - 1 // At least one more char
                        and lastCorrect = incorrect
                        and areConsecutiveChars(lastCorrect, charAt(index + 1))
                    )
                )
            )
            or (
                (
                    // Last char
                    index = length()
                    // Or next char has different type
                    or not areSameType(lastCorrect, charAt(index))
                )
                // Verify that sequence is not allowed to end with `lastCorrect`
                and not isAllowedLastChar(lastCorrect.toLowerCase())
            )
        )
    }
}

class IncompleteStringLiteralExpr extends IncompleteSequenceExpr, StringLiteral {
    override
    string getString() {
        result = getValue()
    }
    
    override
    string charAt(int index) {
        result = getString().charAt(index)
    }
    
    override
    int length() {
        result = getString().length()
    }
}

class IncompleteCharArrayExpr extends IncompleteSequenceExpr, ArrayInit {
    override
    string getString() {
        result = concat(string char | char = charAt(_))
    }
    
    override
    string charAt(int index) {
        result = getInit(index).(CharacterLiteral).getValue()
    }
    
    override
    int length() {
        // Count elements of initializer
        result = count(getAnInit())
    }
}

from IncompleteSequenceExpr incompleteSeq, int index
where
    hasSequenceStart(incompleteSeq)
    and not incompleteSeq.getEnclosingCallable().getDeclaringType() instanceof TestClass
select incompleteSeq, "Sequence of chars is incomplete, is missing '" + incompleteSeq.getMissingChar(index) + "' at index " + index

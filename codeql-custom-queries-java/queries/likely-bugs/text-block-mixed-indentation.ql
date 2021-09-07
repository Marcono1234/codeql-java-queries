/**
 * Finds text blocks which use different characters for indentation, for
 * example one line uses tabs and another line uses spaces. When incidental
 * whitespaces are removed from text block lines each whitespace character
 * is considered to have the same size, regardless of how an IDE might display
 * it.
 * 
 * In the following example one line is indented using spaces and the other
 * line is indented using a tab:
 * ```java
 * String value = """
 *     spaces
 * 	tab""";
 * ```
 * In the resulting string, instead of both lines having no indentation,
 * the line with spaces has still 3 spaces of indentation, only a single
 * space was removed:
 * ```java
 * "   spaces\ntab"
 * ```
 * 
 * See also [Programmer's Guide to Text Blocks](https://docs.oracle.com/en/java/javase/16/text-blocks/index.html).
 */

import java
import lib.Expressions
import lib.Strings

bindingset[lineIndex]
predicate isLastLine(TextBlock textBlock, int lineIndex) {
    not exists(int subsequentLineIndex |
        subsequentLineIndex > lineIndex
        and exists(textBlock.getLiteralLine(subsequentLineIndex))
    )
}

/**
 * If the line consistently uses one character for indentation the result is that
 * character. Otherwise if mixed indentation or no indentation is used this
 * predicate has no result.
 */
string getIndentationCharacter(TextBlock textBlock, int lineIndex) {
    exists(string literalLine, string indentation |
        literalLine = textBlock.getLiteralLine(lineIndex)
        and indentation = getLeadingJavaWhitespaces(literalLine)
        // Ignore blank lines, their whitespaces will be removed anyways, except for last line
        and (isLastLine(textBlock, lineIndex) or indentation != literalLine)
        // And all characters of indentation are the same
        and forex(int i | i = [0, indentation.length() - 1] |
            indentation.charAt(i) = result
        )
    )
}

from TextBlock textBlock, string message
where
    // Indentation of one line is mixed
    exists(int lineIndex, string literalLine, string indentation |
        literalLine = textBlock.getLiteralLine(lineIndex)
        and indentation = getLeadingJavaWhitespaces(literalLine)
        // Ignore blank lines, their whitespaces will be removed anyways, except for last line
        and (isLastLine(textBlock, lineIndex) or indentation != literalLine)
    |
        indentation.charAt(_) != indentation.charAt(_)
        and message = "Text block line " + lineIndex + " (0-based) uses mixed indentation; used characters: "
            + concat(string indentationChar | indentationChar = indentation.charAt(_) |
                getCodePointHex(indentationChar), ", "
            )
    )
    // Two or more lines which use a different character for indentation
    or exists(int lineIndex1, string indentationChar, string otherIndentationChar |
        indentationChar = getIndentationCharacter(textBlock, lineIndex1)
        and otherIndentationChar = getIndentationCharacter(textBlock, _)
        and indentationChar != otherIndentationChar
        // Establish order to prevent reporting them twice in different orders
        and forall(int lineIndex2 | otherIndentationChar = getIndentationCharacter(textBlock, lineIndex2) |
            lineIndex1 < lineIndex2
        )
        and message = (
            "Text block line(s) "
            + concat(int lineIndex | indentationChar = getIndentationCharacter(textBlock, lineIndex) |
                lineIndex.toString(), ", "
            )
            + " (0-based) use " + getCodePointHex(indentationChar)
            + " for indentation, but line(s) "
            + concat(int lineIndex | otherIndentationChar = getIndentationCharacter(textBlock, lineIndex) |
                lineIndex.toString(), ", "
            )
            + " use " + getCodePointHex(otherIndentationChar)
        )
    )
select textBlock, message

/**
 * Finds text blocks where a line has trailing whitespaces. Text blocks remove
 * incidental whitespaces, including any trailing whitespaces. If the whitespaces
 * should be preserved, a non-Unicode-escape such as `\s` for a space (U+0020)
 * should be used.
 * 
 * See also [Programmer's Guide to Text Blocks](https://docs.oracle.com/en/java/javase/16/text-blocks/index.html).
 */

import java
import lib.Expressions
import lib.Strings

from TextBlock textBlock, int lineIndex, string literalLine
where
    literalLine = textBlock.getLiteralLine(lineIndex)
    // Only need to check the last character of the line
    and consistsOnlyOfJavaWhitespaces(literalLine.charAt(literalLine.length() - 1))
    // And the line is not empty
    and not consistsOnlyOfJavaWhitespaces(literalLine)
select textBlock, "Has trailing whitespaces at text block line " + lineIndex + " (0-based)"

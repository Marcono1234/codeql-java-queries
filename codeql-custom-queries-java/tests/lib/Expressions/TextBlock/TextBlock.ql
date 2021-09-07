import java
import lib.Expressions

from TextBlock textBlock, int lineIndex
select textBlock, lineIndex, textBlock.getLiteralLine(lineIndex)

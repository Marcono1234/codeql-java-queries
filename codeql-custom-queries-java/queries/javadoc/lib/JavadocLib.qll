
import java

bindingset[s, toCount, endIndexInclusive]
private int countToIndex(string s, string toCount, int endIndexInclusive) {
    result = count(int index |
        index = s.indexOf(toCount)
        and index <= endIndexInclusive
    |
        index
    )
}

bindingset[s]
private int getInlineTagEndIndexExclusive(string s) {
    // Count opening and closing curly brackets, see also https://docs.oracle.com/en/java/javase/16/docs/specs/javadoc/doc-comment-spec.html#inline-tags
    result = min(int balancedIndex, int openingCount, int closingCount |
        balancedIndex = [0 .. s.length() - 1]
        and openingCount = countToIndex(s, "{", balancedIndex)
        and closingCount = countToIndex(s, "}", balancedIndex)
        and openingCount = closingCount
    |
        // + 1 to make index exclusive
        balancedIndex + 1
    )
}

private string getInlineTagPattern(boolean lazy) {
    exists(string quantifier |
        lazy = true and quantifier = "?"
        or lazy = false and quantifier = ""
    |    
        // Even though (some?) inline tags can span multiple lines, don't check multiline for now
        /*
        * Exact format is not specified, and parsing also seems to differ between tag types, see
        * https://github.com/openjdk/jdk/blob/4eacdb38a83b545603928392eccb116c744ef3b3/src/jdk.compiler/share/classes/com/sun/tools/javac/parser/DocCommentParser.java
        * The following pattern matches how some standard JDK tags are parsed
        * 
        * Group 1: tag name
        * Group 2: tag content
        */
        result = "(?s)\\{@([a-zA-Z0-9\\-_.:]+)\\p{javaWhitespace}+(.*" + quantifier + ")(?<!\\p{javaWhitespace})\\p{javaWhitespace}*\\}"
    )
}

bindingset[javadoc]
private string getInlineTagContent_(string javadoc, string tagName, int index, int length) {
    exists(string potentialInlineTag, string actualInlineTag |
        // For finding tag use lazy pattern, to not match multiple inline tags at once
        exists(javadoc.regexpFind(getInlineTagPattern(true), _, index))
        and potentialInlineTag = javadoc.suffix(index)
        // Get the actual end, this is at the same time the length of the tag (including closing '}')
        and length = getInlineTagEndIndexExclusive(potentialInlineTag)
        and actualInlineTag = potentialInlineTag.prefix(length)
        // For capturing use greedy pattern
        and exists(string capturePattern | capturePattern = getInlineTagPattern(false) |
            tagName = actualInlineTag.regexpCapture(capturePattern, 1)
            and result = actualInlineTag.regexpCapture(capturePattern, 2)
        )
    )
}

/**
 * Gets the content of an inline Javadoc tag. The complete tag, including opening
 * and closing curly brackets, starts at `index` and has length `length`.
 * Has no result if the string does not contain any inline tags, the inline tags have
 * no content or are malformed.
 */
bindingset[javadoc]
string getInlineTagContent(string javadoc, string tagName, int index, int length) {
    result = getInlineTagContent_(javadoc, tagName, index, length)
    /*
     * And because finding is done lazily, make sure that there is no enclosing inline tag
     * because nested inline tags are treated literally (only for some kinds?)
     * 
     * This requires having the actual implementation in separate predicate `getInlineTagContent_`,
     * otherwise it would lead to non-monotonic recursion (which is not permitted)
     * 
     * No need to check this recursively because brackets have to be balanced, so even
     * if the enclosing tag has itself an enclosing tag, then that would cover all tags
     */
    and not exists(int enclosingIndex, int enclosingLength |
        exists(getInlineTagContent_(javadoc, _, enclosingIndex, enclosingLength))
        and index = [enclosingIndex + 1 .. enclosingIndex + enclosingLength - 1]
    )
}

bindingset[maxIndexExclusive]
private string getCompleteJavadocTextUpTo(JavadocParent parent, int maxIndexExclusive) {
    // JavadocText only represents a single line, see https://github.com/github/codeql/issues/3696
    // Does not work correctly for Javadoc block tags, see https://github.com/github/codeql/issues/3825
    result = concat(int index, string line |
        line = parent.getChild(index).(JavadocText).getText()
        and index < maxIndexExclusive
    |
        line, "\n" order by index asc
    )
}

/**
 * Gets the complete Javadoc text of the parent, that is the text of all
 * lines concatenated with `\n`.
 */
string getCompleteJavadocText(JavadocParent parent) {
    result = getCompleteJavadocTextUpTo(parent, 2147483647)
}

/**
 * Gets the start index (starting at 0) of the JavadocText in the complete
 * text of the parent (as created by `getCompleteJavadocText`).
 */
int getStartIndexInCompleteJavadocText(JavadocParent parent, JavadocText javadocText) {
    exists(int index, int offset | parent.getChild(index) = javadocText |
        (
            index = 0 and offset = 0
            // + 1 for trailing line terminator, see `getCompleteJavadocTextUpTo` implementation
            or index > 0 and offset = 1
        )
        and result = getCompleteJavadocTextUpTo(parent, index).length() + offset
    )
}

import java
import semmle.code.xml.XML

// XML CodeQL classes don't extend Top, must use algebraic datatype as workaround
// See also https://github.com/github/codeql/issues/5646

private newtype TFormatterComment = TJavaComment(JavadocText t) or TXmlComment(XMLComment c)

/**
 * A comment which enables or disables the IDE formatter or a formatter plugin for a
 * range of code.
 */
abstract class FormatterComment extends TFormatterComment {
    /**
     * Gets the prefix of the comment, differentiating between comments for different
     * formatters
     */
    abstract string getPrefix();

    /**
     * Gets whether this comment is turning the formatter on (`true`) or off (`false`).
     */
    abstract boolean getIsFormatterOn();

    abstract Location getLocation();

    int getLineNumber() {
        result = getLocation().getStartLine()
    }

    /**
     * Gets a comment with the same prefix in the same type as this one.
     */
    FormatterComment getACommentInSameFile() {
        result.getLocation().getFile() = getLocation().getFile()
        and result.getPrefix() = getPrefix()
        and result != this
    }

    abstract string toString();
}

bindingset[comment, commentPrefix]
private boolean getIsCommentFormatterOn(string comment, string commentPrefix) {
    result = true and comment.matches("%" + commentPrefix + ":on%")
    or result = false and comment.matches("%" + commentPrefix + ":off%")
}

/**
 * Eclipse and IntelliJ IDEA Java source formatter comment
 */
private class EclipseIntelliJFormatterComment extends FormatterComment, TJavaComment {
    JavadocText comment;
    boolean isOn;

    EclipseIntelliJFormatterComment() {
        this = TJavaComment(comment)
        // Make sure this is not an actual Javadoc comment, see https://github.com/github/codeql/issues/3695
        and not exists(comment.getJavadoc().getCommentedElement())
        and isOn = getIsCommentFormatterOn(comment.getText(), "@formatter")
    }

    override
    string getPrefix() {
        result = "@formatter"
    }

    override
    boolean getIsFormatterOn() {
        result = isOn
    }

    override
    Location getLocation() {
        result = comment.getLocation()
    }

    override
    string toString() {
        result = comment.toString()
    }
}

/**
 * Spotless Java source formatter comment, see
 * https://github.com/diffplug/spotless/tree/main/plugin-gradle#spotlessoff-and-spotlesson
 * 
 * Spotless does not detect mismatching comments yet, see https://github.com/diffplug/spotless/issues/1165
 */
private class SpotlessJavaFormatterComment extends FormatterComment, TJavaComment {
    JavadocText comment;
    boolean isOn;

    SpotlessJavaFormatterComment() {
        this = TJavaComment(comment)
        // Make sure this is not an actual Javadoc comment, see https://github.com/github/codeql/issues/3695
        and not exists(comment.getJavadoc().getCommentedElement())
        and isOn = getIsCommentFormatterOn(comment.getText(), "spotless")
    }

    override
    string getPrefix() {
        result = "spotless"
    }

    override
    boolean getIsFormatterOn() {
        result = isOn
    }

    override
    Location getLocation() {
        result = comment.getLocation()
    }

    override
    string toString() {
        result = comment.toString()
    }
}

/**
 * Spotless XML formatter comment, see
 * https://github.com/diffplug/spotless/tree/main/plugin-gradle#spotlessoff-and-spotlesson
 * 
 * Spotless does not detect mismatching comments yet, see https://github.com/diffplug/spotless/issues/1165
 */
private class SpotlessXmlFormatterComment extends FormatterComment, TXmlComment {
    XMLComment comment;
    boolean isOn;

    SpotlessXmlFormatterComment() {
        this = TXmlComment(comment)
        and isOn = getIsCommentFormatterOn(comment.getText(), "spotless")
    }

    override
    string getPrefix() {
        result = "spotless"
    }

    override
    boolean getIsFormatterOn() {
        result = isOn
    }

    override
    Location getLocation() {
        result = comment.getLocation()
    }

    override
    string toString() {
        result = comment.toString()
    }
}

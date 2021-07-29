/**
 * Finds Maven POM XML elements with nested XML elements _and_ text.
 * POM XML elements usually should contain either nested XML elements or
 * have a text value. If they contain both then this might indicate a
 * formatting error, and the text might for example have been intended as
 * comment, but was not put inside an XML comment.
 */

import java
import semmle.code.xml.MavenPom

// Note: Cannot use PomElement because that actually matches any XMLElement
from XMLElement pomElement, string textValue
where
    pomElement.getParent+() instanceof Pom
    // Note: getTextValue() only seems to consider text if there are non-whitespace
    // characters, otherwise it is just an empty string; so no need to trim text here
    and textValue = pomElement.getTextValue()
    // Text is non-empty
    and textValue.length() > 0
    // And POM XML element also has XML element as child
    and exists(pomElement.getAChild())
// Trim whitespace from text value to remove indentation and line breaks
select pomElement, "POM XML element contains unexpected text '" + textValue.trim() + "'"

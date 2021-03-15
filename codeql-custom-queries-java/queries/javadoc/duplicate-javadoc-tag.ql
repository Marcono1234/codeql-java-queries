/**
 * Finds usage of inline and block javadoc tags which occur multiple times
 * despite only being allowed once.
 */

// Based on Java 15 Standard Doclet javadoc tags

import java

abstract class SingleUseJavadocTag extends JavadocElement {
    abstract string getTagName();
    abstract int getLocationIndex();
}

class SingleUseJavadocBlockTag extends SingleUseJavadocTag, JavadocTag {
    private string tagName;
    
    SingleUseJavadocBlockTag() {
        tagName = JavadocTag.super.getTagName()
        and tagName = [
            "@deprecated",
            "@hidden",
            "@return",
            "@serial",
            "@since",
            "@version"
        ]
    }
    
    override
    string getTagName() {
        result = tagName
    }
    
    override
    int getLocationIndex() {
        result = getLocation().getStartLine() // used for ordering
    }
}

// TODO: Not tested yet
class SingleUseJavadocInlineTag extends SingleUseJavadocTag, JavadocText {
    private string tagName;
    private int index;
    
    SingleUseJavadocInlineTag() {
        tagName = [
            "{@inheritDoc}",
            "{@summary " // has content, don't include closing `}`
        ]
        and index = getText().indexOf(tagName)
    }
    
    override
    string getTagName() {
        result = tagName
    }
     
    override
    int getLocationIndex() {
        // CodeQL has no class for inline javadoc tag; use index to
        // differentiate inline tags within the same JavadocText
        result = index
    }
} 

from SingleUseJavadocTag javadocTag, SingleUseJavadocTag otherJavadocTag, string tagName
where
    // Tags have same parent
    (
        javadocTag.getParent() = otherJavadocTag.getParent() and javadocTag != otherJavadocTag
        // Differentiate same JavadocText with different inline tags
        or javadocTag = otherJavadocTag and javadocTag.getIndex() != otherJavadocTag.getIndex()
    )
    and tagName = javadocTag.getTagName()
    // And tags are duplicate
    and tagName = otherJavadocTag.getTagName()
    // Prefer last occurence
    and javadocTag.getLocationIndex() >= otherJavadocTag.getLocationIndex()
select javadocTag, "Duplicate javadoc tag " + tagName

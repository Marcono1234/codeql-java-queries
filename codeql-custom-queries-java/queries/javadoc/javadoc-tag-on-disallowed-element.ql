/**
 * Finds usage of inline and block javadoc tags on elements on which these
 * tags are not allowed.
 * See "[Standard Doclet: Where Tags Can Be Used](https://docs.oracle.com/en/java/javase/15/docs/specs/javadoc/doc-comment-spec.html#where-tags-can-be-used)".
 */

import java

abstract class JavadocTag_ extends JavadocElement {
    abstract string getTagName();
    abstract predicate isAllowedOnElement();
    
    Documentable getDocumentedElement() {
        result = getParent+().(Javadoc).getCommentedElement()
    }
}

/**
 * Holds if the `typeString`, consisting of chars representing the allowed element
 * type, allows the documentable.
 */
bindingset[typeString]
private predicate isElem(Documentable d, string typeString) {
    exists(string c | c = typeString.charAt(_) |
        // Currently cannot check module and package javadoc, see https://github.com/github/codeql/issues/5288
        /*d instanceof Module and c = "M"
        or d instanceof Package and c = "p"
        or*/ d instanceof Type and c = "t"
        or d instanceof Constructor and c = "c"
        // "Method" includes annotation type members, see Standard Doclet documentation
        or (d instanceof Method or d instanceof AnnotationElement) and c = "m"
        or d instanceof Field and c = "f"
    )
}

class JavadocBlockTag extends JavadocTag_, JavadocTag { 
    override
    string getTagName() {
        result = JavadocTag.super.getTagName()
    }
    
    override
    predicate isAllowedOnElement() {
        // Ignore if javadoc does not belong to any element (should be caught by separate query)
        not exists(getDocumentedElement())
        or exists(string t, Documentable d |
            t = getTagName()
            and d = getDocumentedElement()
        |
            if t = "@author" then isElem(d, "Mpt")
            else if t = "@deprecated" then isElem(d, "Mtcmf")
            else if t = ["@exception", "@throws"] then isElem(d, "cm")
            else if t = "@hidden" then isElem(d, "tmf")
            else if t = "@param" then isElem(d, "tcm")
            else if t = "@provides" then isElem(d, "M")
            else if t = "@return" then isElem(d, "m")
            else if t = "@see" then any() // allowed on all
            else if t = "@serial" then isElem(d, "ptf")
            else if t = "@serialData" then d.(Method).hasName([
                "readObject", "writeObject",
                "readExternal", "writeExternal",
                "readResolve", "writeReplace"
            ])
            else if t = "@serialField" then d.(Field).hasName("serialPersistentFields")
            else if t = "@since" then any() // allowed on all
            else if t = "@uses" then isElem(d, "M")
            else if t = "@version" then isElem(d, "Mpt")
            // Allow unknown tags on any element
            else any()
        )
    }
}

class JavadocInlineTag extends JavadocTag_, JavadocText {
    private string tagName;
    
    JavadocInlineTag() {
        // Find `{@tag`
        tagName = getText().regexpFind("\\{@[a-zA-Z]+(?=\\s|\\})", _, _)
    }
    
    override
    string getTagName() {
        result = tagName
    }
    
    override
    predicate isAllowedOnElement() {
        // Ignore if javadoc does not belong to any element (should be caught by separate query)
        not exists(getDocumentedElement())
        or exists(string t, Documentable d |
            t = getTagName()
            and d = getDocumentedElement()
        |
            if t = "{@inheritDoc" then isElem(d, "tm")
            // {@return } is only allowed in main documantation text, but not in text of block tag (e.g. @param or @throws)
            else if t = "{@return" then isElem(d, "m") and getParent() instanceof Javadoc
            // All other tags are allowed everywhere, don't need to check them
            // Allow unknown tags on any element
            else any()
        )
    }
}

// Causes some false positives due to https://github.com/github/codeql/issues/5289
from JavadocTag_ javadocTag
where
    not javadocTag.isAllowedOnElement()
select javadocTag, "Javadoc tag " + javadocTag.getTagName() + " is not allowed here"

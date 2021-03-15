/**
 * Finds Javadoc block tags which are not in the conventional order:
 *   1. `@param`
 *   2. `@return`
 *   3. `@throws` (or `@exception`)
 *   4. `@author`
 *   5. `@version`
 *   6. `@see`
 *   7. `@since`
 *   8. `@serial`, `@serialField` or `@serialData`
 *   9. `@deprecated`
 *
 * See also https://www.oracle.com/technical-resources/articles/java/javadoc-tool.html#tag
 * (slightly outdated)
 *
 * Note that in contrast to the convention, this query also allows `@deprecated`
 * to be placed as first tag.
 */

import java

int getTagIndex(JavadocTag tag) {
    exists (string tagName | tagName = tag.getTagName() |
        tagName = "@param" and result = 1
        or tagName = "@return" and result = 2
        or tagName in ["@exception", "@throws"] and result = 3
        /*
         * Oracle convention says @author and @version should appear first, however
         * it does not consider that @param can be used for generic type parameters
         * of classes, so @author and @version probably fit best before @see
         * The JDK also places @author there, see e.g. java.util.List
         */
        or tagName = "@author" and result = 4
        or tagName = "@version" and result = 5
        or tagName = "@see" and result = 6
        or tagName = "@since" and result = 7
        or tagName in ["@serial", "@serialField", "@serialData"] and result = 8
        or tagName = "@deprecated" and result = 9
    )
}

string getAShouldBeBeforeTag(JavadocTag tag) {
    /*
     * Convention says that @deprecated should appear last; however it is rather common
     * for @deprecated to appears as first tag (even JDK does it like this, see java.lang.String)
     * So if `tag` is @deprecated and appears as first tag, do not return any results
     */
    not (
        tag.getTagName() = "@deprecated"
        // There is no other tag before @deprecated, i.e. @deprecated is first
        and not exists (JavadocTag other |
            other != tag
            and other.getParent().(Javadoc) = tag.getParent().(Javadoc)
            and other.getIndex() < tag.getIndex()
        )
    )
    and exists (JavadocTag shouldBeBefore |
        shouldBeBefore.getParent().(Javadoc) = tag.getParent().(Javadoc)
        and getTagIndex(shouldBeBefore) < getTagIndex(tag)
        and shouldBeBefore.getIndex() > tag.getIndex()
        and result = shouldBeBefore.getTagName()
    )
}

from JavadocTag javadocTag, string shouldBeBeforeTags
where
    shouldBeBeforeTags = strictconcat(getAShouldBeBeforeTag(javadocTag), ", ")
select javadocTag, "Should be placed after the following tags: " + shouldBeBeforeTags

/**
 * Finds usage of the `@exception` javadoc block tag.
 * The `@throws` tag should be preferred because it is more common and
 * its name shows the connection to the `throws` clause and the `throw`
 * statement more clearly.
 */

import java

from JavadocTag javadocTag
where
    javadocTag.getTagName() = "@exception"
select javadocTag

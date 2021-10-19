/**
 * Finds usage of the TAB character (`\t`) in Javadoc text. The Standard Doclet documentation
 * recommends using spaces instead because they are "interpreted by browsers more uniformly".
 * 
 * See [Standard Doclet documentation](https://docs.oracle.com/en/java/javase/17/docs/specs/javadoc/doc-comment-spec.html#leading-asterisks).
 */

import java

from JavadocText t
where
    // Make sure this is not a regular comment, see https://github.com/github/codeql/issues/3695
    exists(t.getJavadoc().getCommentedElement())
    and t.getText().matches("%\t%")
select t, "Contains TAB character"

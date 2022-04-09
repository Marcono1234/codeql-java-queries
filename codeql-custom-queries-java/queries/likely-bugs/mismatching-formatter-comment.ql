/**
 * Finds comments for enabling / disabling formatting in a code section (e.g. `// @formatter:off`)
 * which are not matching. Normally a comment to disable formatting should be followed by
 * a comment to enable formatting. Mismatching comments might be added by accident due to
 * copy and paste errors and might end up completely disabling formatting for the rest of
 * the file.
 */

import java

import lib.FormatterComments

from FormatterComment comment, boolean formatterState, FormatterComment previousComment
where
    formatterState = comment.getIsFormatterOn()
    and previousComment = comment.getACommentInSameFile()
    and previousComment.getLineNumber() < comment.getLineNumber()
    // And previous comment is of same type
    and previousComment.getIsFormatterOn() = formatterState
    // And there is no other comment in between
    and not exists(FormatterComment other |
        other = comment.getACommentInSameFile()
        and other.getLineNumber() > previousComment.getLineNumber()
        and other.getLineNumber() < comment.getLineNumber()
    )
select comment, "Has no effect because $@ previous comment is of the same type", previousComment, "this"

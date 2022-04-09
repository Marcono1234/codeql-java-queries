/**
 * Finds comments for enabling / disabling formatting in a code section (e.g. `// @formatter:off`)
 * which are leading, without any previous matching comment, or trailing, without any subsequent
 * matching comment.
 * 
 * A leading comment to enable the formatter is most likely redundant because normally the
 * formatter is either not enabled at all, or enabled for all files by default. The comment
 * may be a leftover from previous refactoring.
 * 
 * A trailing comment to disable the formatter might completely disable formatting for the
 * rest of the file, which is most likely not intended. Especially when new code is added in
 * the future without the author being aware of the comment further up in the file.
 */

import java

import lib.FormatterComments

from FormatterComment comment, string message
where
    (
        message = "No previous comment to turn formatter off exists"
        and comment.getIsFormatterOn() = true
        // Note: Don't check whether other is on / off; mismatching comments are reported by separate query
        and not exists(FormatterComment previous |
            previous = comment.getACommentInSameFile()
            and previous.getLineNumber() < comment.getLineNumber()
        )
    )
    or (
        message = "No subsequent comment to turn formatter on again exists"
        and comment.getIsFormatterOn() = false
        // Note: Don't check whether other is on / off; mismatching comments are is reported by separate query
        and not exists(FormatterComment subsequent |
            subsequent = comment.getACommentInSameFile()
            and subsequent.getLineNumber() > comment.getLineNumber()
        )
    )
select comment, message

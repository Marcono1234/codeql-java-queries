/**
 * Finds comments which contain a non-permalink GitHub URL, for example
 * `https://github.com/myorg/myrepo/blob/master/SomeClass.java#123`.
 *
 * If the referenced file is updated, renamed or removed, or if the branch is deleted or renamed
 * such URLs could become dead links, which requires some effort to then find out what the URL
 * was originally referring to.
 *
 * Prefer either permalinks with commit SHA, by clicking the three dots at the top right in the
 * GitHub UI and selecting "Copy permalink". Or instead of referencing branches such as `master`
 * or `main` use a reference to a version tag instead, e.g. `v1.0.0`.
 *
 * @id todo
 * @kind problem
 */

import java

// Javadoc covers regular comments as well
from JavadocText comment
where
  exists(
    // Only cover common default branch names; otherwise even when not using a commit SHA, the
    // reference can be stable in case it refers to a tag
    comment
        .getText()
        // Patterns for user and repo name are based on validation messages in GitHub UI
        .regexpFind("https://github\\.com/[a-zA-Z0-9\\-]+/[a-zA-Z0-9.\\-_]+/blob/(master|main)/", _, _)
  )
select comment, "Uses non-permalink GitHub URL"

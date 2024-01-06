/**
 * Finds a single non-escaped `.` in a Regex pattern without any qualifier.
 * In that case the `.` is treated as 'any character' instead of being matched literally.
 *
 * Consider this pattern:
 * ```
 * \d{4}.\d{2}.\d{2}
 * ```
 * The intention might have been to match dates such as `2024.01.01`, but it also matches
 * malformed dates such as `2024&01(01`.\
 * The pattern should have escaped the `.` as `\.` instead.
 *
 * @kind problem
 */

import java
// Uses alias `re` to avoid conflicting declarations
import semmle.code.java.regex.RegexTreeView as re

// Note: This does not match all Regex patterns, see
// https://github.com/github/codeql/blob/codeql-cli/v2.15.5/java/ql/lib/semmle/code/java/regex/RegexFlowConfigs.qll#L161-L162
from re::RegExpDot dot
where not dot.getParent() instanceof re::RegExpQuantifier
select dot, "This `.` should probably be escaped to match it literally"

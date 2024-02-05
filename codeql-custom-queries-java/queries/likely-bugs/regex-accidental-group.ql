/**
 * Finds Regex patterns containing `(...)` which was most likely not intended to be
 * treated as group but instead literally.
 *
 * For example in the pattern `Action ".*" failed (cancelled)` the part `(cancelled)`
 * was most likely supposed to be matched literally, but it is actually interpreted as
 * group and therefore `(` and `)` are not expected in the input. The `(` and `)`
 * should be escaped with a `\` in this case.
 *
 * @id todo
 * @kind problem
 */

import java
// Uses alias `re` to avoid conflicting declarations
import semmle.code.java.regex.RegexTreeView as re

class LiteralRegExpChar extends re::RegExpNormalChar {
  LiteralRegExpChar() {
    // RegExpNormalChar documentation says it also matches character classes; ignore them here
    not exists(this.getRawValue().indexOf("\\"))
  }
}

// Note: This does not match all Regex patterns, see
// https://github.com/github/codeql/blob/codeql-cli/v2.15.5/java/ql/lib/semmle/code/java/regex/RegexFlowConfigs.qll#L161-L162
from re::RegExpGroup group
where
  // Ignore special group syntax (non-capturing, lookahead, ...), which suggests group is intentional
  not group.getRawValue().matches("(?%") and
  // Require that group contains only literals; otherwise captured group content might be used somewhere
  forall(re::RegExpTerm child | child = group.getAChild() | child instanceof LiteralRegExpChar) and
  // Ignore if group has quantifier (e.g. `(ab)+`), then it is most likely intentional
  not group.getParent() instanceof re::RegExpQuantifier
// TODO: Maybe check for parse errors to reduce false-positives, with `not group.getRegex().failedToParse(_)`?
select group, "Potential accidental group"

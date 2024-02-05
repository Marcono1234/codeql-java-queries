/**
 * Finds Regex patterns with a character class which contains the same character multiple
 * times. This is redundant and might indicate that the string was not supposed to represent
 * a character class.
 *
 * For example in the pattern `[ERROR] some message.*` the part `[ERROR]` is actually a
 * character class which matches any of these characters. The `[` and `]` should be escaped
 * with a `\` in this case.
 *
 * Note that a `|` _inside a character class_ does not represent an 'either' and is instead
 * matched literally. E.g. the pattern `[ab|cd|ef]` also matches the string `"|"`.
 *
 * This issue is also reported by IntelliJ as `RegExpDuplicateCharacterInClass`.
 *
 * @id todo
 * @kind problem
 */

import java
// Uses alias `re` to avoid conflicting declarations
import semmle.code.java.regex.RegexTreeView as re

// Note: This does not match all Regex patterns, see
// https://github.com/github/codeql/blob/codeql-cli/v2.15.5/java/ql/lib/semmle/code/java/regex/RegexFlowConfigs.qll#L161-L162
from
  re::RegExpCharacterClass charClass, int indexA, re::RegExpNormalChar charA, int indexB,
  re::RegExpNormalChar charB, string charValue
where
  charA = charClass.getChild(indexA) and
  charB = charClass.getChild(indexB) and
  // Prevent reporting twice with order reversed
  indexA < indexB and
  charValue = charA.getRawValue() and
  charValue = charB.getRawValue() and
  // Ignore false positives for `&&`, which does not seem to be recognized by CodeQL Regex library yet
  not (charValue = "&" and indexA + 1 = indexB)
// TODO: Maybe check for parse errors to reduce false-positives, with `not charClass.getRegex().failedToParse(_)`?
select charClass, "Contains '" + charValue + "' twice $@ and $@", charA, "here", charB, "here"

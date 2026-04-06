/**
 * Finds `switch` expressions and statements where a pattern case with guard (`when ...`) appears before
 * a const case such as `case 1`.
 *
 * For such code the compiler cannot determine if the const case is actually unreachable, and it
 * might also lead to less efficient code where the guard is evaluated even if the const case would
 * match.
 *
 * For example:
 * ```java
 * switch (string) {
 *     case String s when !s.startsWith("prefix") -> ...;
 *     // Bad: const case after pattern case
 *     case "" -> ...;
 *     default -> ...;
 * }
 * ```
 * In this example the `case ""` is actually unreachable (the `case String ...` covers it) but the
 * compiler cannot detect it.
 *
 * See also [Java documentation "Pattern Matching with switch": "Pattern Label Dominance"](https://docs.oracle.com/en/java/javase/26/language/pattern-matching-switch.html#GUID-08C56E57-B95B-45D8-930D-E3FAFA29B5B7).
 *
 * @kind problem
 * @id TODO
 */

// Note: At least in current Java versions it might be unlikely that such code occurs in practice because
// const cases apparently have to match the switch condition type, e.g. `case "..."` is not possible for
// a `switch (object)`

import java

from
  SwitchBlock parent, int constIndex, ConstCase constCase, int patternIndex, PatternCase patternCase
where
  constCase.isNthCaseOf(parent, constIndex) and
  patternCase.isNthCaseOf(parent, patternIndex) and
  constIndex > patternIndex and
  // For pattern case without guard, compiler will detect unreachable patterns
  exists(patternCase.getGuard()) and
  // Ignore `case null` which cannot be accidentally matched by non-null pattern case
  not constCase.getValue() instanceof NullLiteral
select constCase, "Should appear before $@", patternCase, "pattern case"

/**
 * Finds usage of the `String` regex methods `matches`, `replaceAll`, `replaceFirst` and `split`
 * where the intention might have been to treat the argument literally but instead it is
 * interpreted as regex pattern.
 *
 * The method `java.util.regex.Pattern.quote` should be used to make sure none of the characters
 * in the argument are treated as special regex pattern characters.
 *
 * @kind problem
 * @precision low
 */

// TODO: Improve precision
import java

class StringRegexMethod extends Method {
  StringRegexMethod() {
    getDeclaringType() instanceof TypeString and
    hasName(["matches", "replaceAll", "replaceFirst", "split"])
  }
}

class RegexPatternMethod extends Method {
  RegexPatternMethod() {
    getDeclaringType().hasQualifiedName("java.util.regex", "Pattern") and
    hasName(["compile", "matches"])
  }
}

predicate isRelevantNonRegexUsage(RValue varRead) {
  not exists(MethodAccess otherStringRegexCall |
    otherStringRegexCall.getMethod() instanceof StringRegexMethod and
    otherStringRegexCall.getArgument(0) = varRead
  ) and
  not any(EqualityTest e).getAnOperand() = varRead and
  not exists(MethodAccess equalsCall | equalsCall.getMethod() instanceof EqualsMethod |
    equalsCall.getQualifier() = varRead or
    equalsCall.getArgument(0) = varRead
  )
}

from Variable var, RValue regexUsage, MethodAccess stringRegexCall, RValue otherUsage
where
  stringRegexCall.getMethod() instanceof StringRegexMethod and
  stringRegexCall.getArgument(0) = regexUsage and
  regexUsage = var.getAnAccess() and
  // Ignore if var name indicates intentional usage
  not var.getName().matches(["%regex%", "%Regex%", "%pattern%", "%Pattern%"]) and
  // Ignore if explicitly catching PatternSyntaxException
  not exists(TryStmt tryStmt |
    tryStmt.getBlock() = stringRegexCall.getAnEnclosingStmt() and
    tryStmt
        .getACatchClause()
        .getACaughtType()
        .hasQualifiedName("java.util.regex", "PatternSyntaxException")
  ) and
  otherUsage = var.getAnAccess() and
  otherUsage != regexUsage and
  isRelevantNonRegexUsage(otherUsage) and
  // Ignore if var is also explicitly used for Pattern method
  not exists(MethodAccess patternCall |
    patternCall.getMethod() instanceof RegexPatternMethod and
    patternCall.getArgument(0) = var.getAnAccess()
  ) and
  // If var has constant value, that value must contain special regex character
  (
    var.getInitializer() instanceof CompileTimeConstantExpr
    implies
    // Contains character which has special regex meaning
    exists(
      var.getInitializer()
          .(CompileTimeConstantExpr)
          .getStringValue()
          .indexOf(["\\", "[", "]", ".", "^", "$", "?", "*", "+", "{", "}", "|", "(", ")",])
    )
  )
select regexUsage,
  "Possibly accidental interpretation as Regex pattern because value is used $@ not as Regex pattern",
  otherUsage, "here"

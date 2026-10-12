/**
 * Finds calls to number parsing methods and constructors which accept non-ASCII digits
 * but where most likely only ASCII digits should be allowed.
 *
 * To reduce false positives only calls with a radix other than 10 are reported.
 * For such calls it is very unlikely that non-ASCII digits have to be supported, because
 * it is quite unlikely that the caller expects users to for example provide localized
 * octal or hex numbers (since such numbers are uncommon to most users). Instead it
 * is more likely that the caller parses textual data according to some specification
 * and that specification most likely only allows ASCII digits.
 *
 * Erroneously accepting non-ASCII digits can introduce bugs (e.g. when subsequent parts
 * of the code assume the input is ASCII only) or can be exploitable due to 'parser differentials'
 * (differences between parser implementations respectively deviations from a specification).
 *
 * When the radix is 16 (that is, a hex number is parsed) an alternative way to parse the
 * number and to only allow ASCII digits can be `java.util.HexFormat`.
 *
 * @kind problem
 * @id TODO
 */

import java

abstract class NumberParsingCallable extends Callable {
  /** 0-based index of the radix parameter */
  abstract int radixParamIndex();
}

class MethodCharacterDigit extends Method, NumberParsingCallable {
  MethodCharacterDigit() {
    getDeclaringType().hasQualifiedName("java.lang", "Character") and
    hasName("digit")
  }

  override int radixParamIndex() { result = 1 }
}

class MethodParsePrimitiveNumber extends Method, NumberParsingCallable {
  MethodParsePrimitiveNumber() {
    exists(string t, string m |
      getDeclaringType().hasQualifiedName("java.lang", t) and
      getName() = m
    |
      t = "Byte" and
      (
        m = ["parseByte"]
        or
        m = "valueOf" and getParameterType(0) instanceof TypeString
      )
      or
      t = "Short" and
      (
        m = ["parseShort"]
        or
        m = "valueOf" and getParameterType(0) instanceof TypeString
      )
      or
      t = "Integer" and
      (
        m = ["parseInt", "parseUnsignedInt"]
        or
        m = "valueOf" and getParameterType(0) instanceof TypeString
      )
      or
      t = "Long" and
      (
        m = ["parseLong", "parseUnsignedLong"]
        or
        m = "valueOf" and getParameterType(0) instanceof TypeString
      )
    )
  }

  override int radixParamIndex() {
    // radix is always the last parameter
    result = getNumberOfParameters() - 1 and
    // Note: Cannot check param name (`getParameter(result).hasName("radix")`); it seems only a
    // synthetic name such as `p0` is available
    getParameterType(result).hasName("int")
  }
}

class ConstructorBigInteger extends Constructor, NumberParsingCallable {
  ConstructorBigInteger() {
    getDeclaringType().hasQualifiedName("java.math", "BigInteger") and
    paramsString() = "(String, int)"
  }

  override int radixParamIndex() { result = 1 }
}

from Call call, int radixArgIndex
where
  radixArgIndex = call.getCallee().(NumberParsingCallable).radixParamIndex() and
  // And radix is not 10
  call.getArgument(radixArgIndex).(CompileTimeConstantExpr).getIntValue() != 10 and
  // And parsed number is not a constant
  not call.getArgument(0).(CompileTimeConstantExpr).getType() instanceof TypeString
select call, "Allows non-ASCII digits, which is probably undesired"

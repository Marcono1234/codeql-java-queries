/**
 * Finds creation of a `SimpleDateFormat` or a `DateTimeFormatter` with a format pattern
 * which likely does not behave as desired.
 *
 * @id TODO
 * @kind problem
 */

import java
import semmle.code.java.dataflow.DataFlow

class TypeSimpleDateFormat extends Class {
  TypeSimpleDateFormat() { hasQualifiedName("java.text", "SimpleDateFormat") }
}

class DateFormatPatternUsage extends Expr {
  DateFormatPatternUsage() {
    exists(ConstructorCall c |
      c.getConstructedType() instanceof TypeSimpleDateFormat and
      this = c.getArgument(0) and
      c.getConstructor().getParameterType(0) instanceof TypeString
    )
    or
    exists(MethodAccess c, Method m | m = c.getMethod() |
      m.getDeclaringType() instanceof TypeSimpleDateFormat and
      m.hasName(["applyLocalizedPattern", "applyPattern"]) and
      this = c.getArgument(0)
    )
    or
    exists(MethodAccess c, Method m | m = c.getMethod() |
      m.getDeclaringType().hasQualifiedName("java.time.format", "DateTimeFormatter") and
      m.hasName(["ofLocalizedPattern", "ofPattern"]) and
      this = c.getArgument(0)
    )
    or
    exists(MethodAccess c, Method m | m = c.getMethod() |
      m.getDeclaringType().hasQualifiedName("java.time.format", "DateTimeFormatterBuilder") and
      m.hasName(["appendPattern", "appendLocalized", "getLocalizedDateTimePattern"]) and
      this = c.getArgument(0) and
      m.getParameterType(0) instanceof TypeString
    )
  }
}

bindingset[pattern]
string getAPatternIssue(string pattern) {
  exists(string s, int index |
    index = pattern.indexOf(s) and
    // Ignore if substring is escaped by being enclosed in `'...'`
    // Note: Currently does not detect if `'` is escaped or if it belongs to a previous literal section,
    // but probably good enough for now
    not exists(int startIndex, int endIndex |
      startIndex < index and endIndex >= index + s.length()
    |
      pattern.charAt(startIndex) = "'" and
      pattern.charAt(endIndex) = "'"
    )
  |
    // See https://errorprone.info/bugpattern/MisusedWeekYear or https://rules.sonarsource.com/java/type/Bug/RSPEC-3986
    s = "Y" and result = "`Y` is 'week year', probably meant `y`"
    or
    s = "D" and
    exists(pattern.indexOf(["L", "M"])) and
    result = "`D` is 'day in year', probably meant `d` for 'day in month'"
    or
    s = "h" and
    not exists(pattern.indexOf("a")) and
    result =
      "`h` is 'hour in am/pm (1-12)', probably meant `H` ('hour in day (0-23)') or should include am/pm marker `a`"
    or
    // `m` ('minute') accidentally used for 'month'
    (
      s = ["-mm-", ".mm."] and
      not pattern.charAt(index - 1) = ["H", "h", "K", "k"]
      or
      exists(string sep | sep = ["", " ", ".", ":", "-", "_"] |
        s = sep + "m" and
        // `u` here is for DateTimeFormatter 'year'
        pattern.charAt(index - 1) = ["u", "y", "Y", "d", "D"]
        or
        s = "m" + sep and
        pattern.charAt(index + s.length()) = ["u", "y", "Y", "d", "D"]
      )
    ) and
    result = "`m` is 'minute in hour', probably meant `M` for 'month in year'"
    or
    // `M` ('month') accidentally used for 'minute'
    exists(string sep | sep = ["", " ", ":", "-", "_"] |
      s = sep + "M" and
      pattern.charAt(index - 1) = ["H", "h", "K", "k"]
      or
      s = "M" + sep and pattern.charAt(index + s.length()) = "s"
    ) and
    result = "`M` is 'month in year', probably meant `m` for 'minute in hour'"
    or
    // `S` ('millisecond') accidentally used for 'second'
    s = ["", " ", ":", "-", "_"] + "S" and
    pattern.charAt(index - 1) = "m" and
    result = "`S` is 'millisecond', probably meant `s` for 'second in minute'"
  )
}

from CompileTimeConstantExpr patternStr, DateFormatPatternUsage usage
where
  DataFlow::localExprFlow(patternStr, usage) and
  // If constant variable value is used, don't report the variable read here, instead report the assigned variable value (see below)
  not (
    patternStr = usage and
    patternStr.(RValue).getVariable().fromSource()
  )
  or
  not DataFlow::localExprFlow(patternStr, usage) and
  exists(Variable var |
    var.getAnAssignedValue() = patternStr and
    DataFlow::localExprFlow(var.getAnAccess(), usage)
  )
select patternStr, getAPatternIssue(patternStr.getStringValue())

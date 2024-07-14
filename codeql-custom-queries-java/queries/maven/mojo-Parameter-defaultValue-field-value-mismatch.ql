/**
 * Finds Maven plugin implementations where a parameter field has an explicit initial value which
 * differs from the default value set using `@Parameter#defaultValue`. The `defaultValue` overwrites
 * the initial field value when the plugin is used, so the explicit field value is redundant and
 * can cause confusion.
 *
 * For example:
 * ```java
 * @Parameter(defaultValue = "false")
 * public boolean useCustomFeature = true; // `= true` is redundant and misleading
 * ```
 *
 * @kind problem
 * @id TODO
 */

import java

predicate equalsDefaultValue(Literal l, string defaultValue) {
  exists(string literalValue | literalValue = l.getValue() |
    literalValue = defaultValue
    or
    // Or floating point value matches when removing `.0` suffix
    l.getType() instanceof FloatingPointType and
    literalValue.matches("%.0") and
    literalValue.prefix(literalValue.length() - ".0".length()) = defaultValue
  )
}

from
  Field f, CompileTimeConstantExpr initializedFieldValue, Annotation parameterAnnotation,
  Expr defaultValueExpr, string defaultValue
where
  initializedFieldValue = f.getInitializer() and
  parameterAnnotation = f.getAnAnnotation() and
  parameterAnnotation
      .getType()
      .hasQualifiedName("org.apache.maven.plugins.annotations", "Parameter") and
  defaultValue = parameterAnnotation.getStringValue("defaultValue") and
  // Ignore not set default value
  defaultValue != "" and
  defaultValueExpr = parameterAnnotation.getValue("defaultValue") and
  (
    initializedFieldValue instanceof Literal and
    not equalsDefaultValue(initializedFieldValue, defaultValue)
    or
    exists(initializedFieldValue.getStringValue()) and
    defaultValue != initializedFieldValue.getStringValue()
    or
    exists(initializedFieldValue.getBooleanValue()) and
    defaultValue != initializedFieldValue.getBooleanValue().toString()
    or
    exists(initializedFieldValue.getIntValue()) and
    defaultValue != initializedFieldValue.getIntValue().toString()
  ) and
  // Ignore if default value is `${...}` expression
  // TODO: Does this work as expected when property is undefined, i.e. is field default value used then?
  //   Or is field default value always overwritten? (in that case using `${...}` expression should not be ignored here)
  not defaultValue.matches("${%}")
select initializedFieldValue, "Does not match the $@ specified by @Parameter", defaultValueExpr,
  "defaultValue"

/**
 * Finds Maven plugin implementations where the implicit or explicit initial field value is
 * not specified as `@Parameter#defaultValue`. If `defaultValue` is not specified the plugin
 * documentation won't mention the default value, which makes the default behavior of the
 * plugin unclear to the user.
 *
 * For example:
 * ```java
 * @Parameter
 * // Should specify the default using `@Parameter(defaultValue = "true")` instead
 * public boolean useCustomFeature = true;
 * ```
 *
 * @kind problem
 * @id TODO
 */

// Related to https://github.com/apache/maven-shade-plugin/pull/219

import java

string getDefaultValue(PrimitiveType t) {
  t.hasName("boolean") and result = "false"
  or
  // TODO: Is `char` correct here or is its default value rather `\0`?
  t.hasName(["byte", "short", "char", "int", "long", "float", "double"]) and result = "0"
}

from Field f, Annotation parameterAnnotation, string defaultValue
where
  parameterAnnotation = f.getAnAnnotation() and
  parameterAnnotation
      .getType()
      .hasQualifiedName("org.apache.maven.plugins.annotations", "Parameter") and
  // Does not specify a default value
  parameterAnnotation.getStringValue("defaultValue") = "" and
  // Only consider @Parameter usage in Mojos
  f.getDeclaringType().getASourceSupertype+().hasQualifiedName("org.apache.maven.plugin", "Mojo") and
  (
    if exists(f.getInitializer())
    then
      // Only consider constant initial values, otherwise might not be possible to use @Parameter#defaultValue
      exists(CompileTimeConstantExpr initalizer | initalizer = f.getInitializer() |
        defaultValue = initalizer.(Literal).getValue() or
        defaultValue = initalizer.getStringValue() or
        defaultValue = initalizer.getIntValue().toString() or
        defaultValue = initalizer.getBooleanValue().toString()
      )
    else defaultValue = getDefaultValue(f.getType())
  ) and
  // Ignore if a value is assigned outside the initializer
  not f.getAnAssignedValue() != f.getInitializer() and
  // Ignore if default value is empty string, because it cannot be represented with @Parameter#defaultValue (?)
  defaultValue != ""
select parameterAnnotation, "Should specify defaultValue: " + defaultValue

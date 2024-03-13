/**
 * Finds usage of JUnit 5's `@CsvSource` where the values are not actually real CSV rows.
 * If none of the rows contains a delimiter character (`,` by default), then each 'row' is
 * passed as separate value to the test method. The `@ValueSource(strings = {...})`
 * annotation is exactly intended for that use case and should be preferred, because it
 * makes the intention clearer and is less error-prone in case a value happens to contain
 * a `,` (in which case it will not be split, unlike for `@CsvSource`).
 *
 * For example:
 * ```java
 * @CsvSource({"first", "second"})
 * // should be replaced with
 * @ValueSource(strings = {"first", "second"})
 * ```
 *
 * @id todo
 * @kind problem
 */

import java

string getDelimiter(Annotation csvSource) {
  exists(string delimiterString, string delimiterChar |
    delimiterString = csvSource.getStringValue("delimiterString") and
    delimiterChar = csvSource.getValue("delimiter").(CharacterLiteral).getValue()
  |
    // Check default values of annotation elements
    if delimiterString != ""
    then result = delimiterString
    else
      if delimiterChar != 0.toUnicode()
      then result = delimiterChar
      else result = ","
  )
}

from Annotation csvSource, string delimiter
where
  csvSource.getType().hasQualifiedName("org.junit.jupiter.params.provider", "CsvSource") and
  delimiter = getDelimiter(csvSource) and
  // And none of the values contains the delimiter
  not (
    exists(csvSource.getAStringArrayValue("value").indexOf(delimiter)) or
    exists(csvSource.getStringValue("textBlock").indexOf(delimiter))
  )
select csvSource, "Should use `@ValueSource(strings = {...})` instead"

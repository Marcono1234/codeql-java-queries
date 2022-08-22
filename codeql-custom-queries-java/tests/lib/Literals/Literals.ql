import java
import TestUtilities.InlineExpectationsTest
import lib.Literals

class LiteralsTest extends InlineExpectationsTest {
  LiteralsTest() { this = "LiteralsTest" }

  override string getARelevantTag() { result = "numeric" }

  override predicate hasActualResult(Location location, string element, string tag, string value) {
    location.getFile().isSourceFile() and
    tag = "numeric" and
    exists(Literal literal |
      location = literal.getLocation() and
      element = literal.toString() and
      value = getNumericValue(literal).toString()
    )
  }
}

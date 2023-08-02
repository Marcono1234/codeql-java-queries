import java
import TestUtilities.InlineExpectationsTest
import lib.Literals

module LiteralsTest implements TestSig {
  string getARelevantTag() { result = "numeric" }

  predicate hasActualResult(Location location, string element, string tag, string value) {
    location.getFile().isSourceFile() and
    tag = "numeric" and
    exists(Literal literal |
      location = literal.getLocation() and
      element = literal.toString() and
      value = getNumericValue(literal).toString()
    )
  }
}

import MakeTest<LiteralsTest>

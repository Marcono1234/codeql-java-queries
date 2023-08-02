import java
import TestUtilities.InlineExpectationsTest
import lib.VarAccess

module SameVarAccessTest implements TestSig {
  string getARelevantTag() { result = "sameVarAccess" }

  predicate hasActualResult(Location location, string element, string tag, string value) {
    tag = "sameVarAccess" and
    exists(MethodAccess call |
      call.getMethod().hasStringSignature("checkSameVarAccess(Object, Object)") and
      (
        // Verify that predicate is symmetric
        accessSameVarOfSameOwner(call.getArgument(0), call.getArgument(1)) and
        accessSameVarOfSameOwner(call.getArgument(1), call.getArgument(0))
      ) and
      // No value because only have to verify whether arguments are the same (InlineExpectationsTest comment
      // is present) or not (no comment is present)
      value = "" and
      location = call.getLocation() and
      element = call.toString()
    )
  }
}

import MakeTest<SameVarAccessTest>

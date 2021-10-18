/**
 * Finds usage of TestNG's `SoftAssert` without a call to the `assertAll` method.
 * `assertAll` has to be called, otherwise any collected assertion failures will
 * be ignored.
 */

import java
import lib.TestNg

from LocalVariableDecl var
where
  var.getType().(RefType).getASourceSupertype*() instanceof TestNgSoftAssert
  and not exists(MethodAccess assertAllCall, Method assertAllMethod |
     assertAllCall.getQualifier() = var.getAnAccess()
     and assertAllCall.getMethod() = assertAllMethod
     and assertAllMethod.getDeclaringType().getASourceSupertype*() instanceof TestNgSoftAssert
     and assertAllMethod.hasName("assertAll")
  )
select var, "Missing `assertAll()` call for this variable"

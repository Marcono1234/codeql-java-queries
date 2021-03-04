/**
 * Finds calls to `super.getClass()`. Because `getClass()` returns the runtime
 * class of the receiver, the result of `super.getClass()` will be the same as
 * `this.getClass()`. Therefore to avoid confusion, `super.getClass()` should
 * not be used.
 */

import java

from MethodAccess getClassCall
where
    getClassCall.getMethod().hasStringSignature("getClass()")
    and getClassCall.getQualifier() instanceof SuperAccess
select getClassCall, "Calls super.getClass() which is the same as this.getClass()"

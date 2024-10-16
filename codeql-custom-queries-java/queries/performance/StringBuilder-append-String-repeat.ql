/**
 * Finds code which first repeats a String using `String#repeat` and then appends it to
 * a `StringBuilder` or `StringBuffer`.
 *
 * Since Java 21 `StringBuilder` and `StringBuffer` have new `repeat` methods, which can
 * be used instead and likely provide better performance.
 *
 * @id TODO
 * @kind problem
 */

import java

from MethodAccess stringRepeatCall, Method stringRepeatMethod, MethodAccess stringBuilderAppendCall
where
  stringRepeatCall.getMethod() = stringRepeatMethod and
  stringRepeatMethod.getDeclaringType() instanceof TypeString and
  stringRepeatMethod.hasStringSignature("repeat(int)") and
  stringBuilderAppendCall.getReceiverType() instanceof StringBuildingType and
  stringBuilderAppendCall.getMethod().hasName("append") and
  // For now only cover `repeat` result directly being used as argument for `append`; that already has
  // a lot of findings. Could instead use local dataflow, but this causes false positives then if `repeat`
  // result is used multiple times and cannot be replaced with `StringBuilder#repeat`.
  stringRepeatCall = stringBuilderAppendCall.getAnArgument()
select stringRepeatCall,
  "Can instead use " + stringBuilderAppendCall.getReceiverType().getName() + "#repeat"

/**
 * Finds `hashCode()` implementations which consider more fields than
 * `equals(Object)` does. This can result in different hash codes despite
 * `equals` claiming that the objects are equal, which violates the
 * contract.
 */

import java
import semmle.code.java.dataflow.DataFlow

predicate delegatesCheck(Method m) {
    exists (MethodAccess call | 
        DataFlow::localFlow(DataFlow::parameterNode(m.getAParameter()), DataFlow::exprNode(call.getAnArgument()))
    )
}

from Field f, Method equalsM, Method hashCodeM
where
    equalsM.hasStringSignature("equals(Object)")
    and hashCodeM.hasStringSignature("hashCode()")
    and equalsM.getDeclaringType() = hashCodeM.getDeclaringType()
    // Check that field is declared by same type (or its ancestor)
    and equalsM.getDeclaringType().getAnAncestor() = f.getDeclaringType()
    // Ignore static fields because they influence hashCode for all instances
    // in the same way
    and not f.isStatic()
    // Check if hashCode considers field, but equals does not
    and hashCodeM.reads(f) and not equalsM.reads(f)
    // Verify that equals does not delegate check by calling another method with `obj`
    and not delegatesCheck(equalsM)
select hashCodeM, equalsM, f

/**
 * Finds usage of `java.util.zip.Deflater` and `java.util.zip.Inflater` where the `end()`
 * method is not called. To release the native resources held by instances of these classes
 * the `end()` method should be called once usage of the instance finished.
 * 
 * @kind problem
 */

import java

import lib.Expressions

// Note: Could also consider subclasses, but subclasses are probably rather rare
class DeflaterInflaterClass extends Class {
    DeflaterInflaterClass() {
        hasQualifiedName("java.util.zip", ["Deflater", "Inflater"])
    }
}

// Note: There are plans to have Deflater and Inflater implement AutoCloseable in the future, see
// https://bugs.openjdk.org/browse/JDK-8225763
class EndCall extends MethodAccess {
    EndCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType() instanceof DeflaterInflaterClass
            and m.hasStringSignature("end()")
        )
    }
}

from Variable var
where
    var.getType() instanceof DeflaterInflaterClass
    and (
        (
            var instanceof LocalVariableDecl
            and not any(EndCall c).getQualifier() = var.getAnAccess()
            // Reduce false positives by ignoring cases where instance is passed somewhere else
            // TODO: Check if this is really necessary, or whether this also removes a lot of true positives
            and not isLeaked(var.getAnAccess())
        )
        or (
            var instanceof Field
            and not any(EndCall c).getQualifier() = var.getAnAccess()
            // Reduce false positives by making sure new instance is created; ignore when only pooled instances are used
            and var.getAnAssignedValue() instanceof ClassInstanceExpr
        )
    )
select var, "Resources might be leaked because end() is not called"

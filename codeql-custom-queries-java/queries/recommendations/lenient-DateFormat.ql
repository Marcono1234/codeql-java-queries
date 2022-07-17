/**
 * Finds creation of `DateFormat` (or its subclass `SimpleDateFormat`) which is not made
 * strict. By default `DateFormat` is lenient and accepts invalid dates such as `2022-40-40`.
 * To protect against bugs and malicious input `setLenient(false)` can be used
 * to disallow such invalid dates. Alternatively the classes from the `java.time` package
 * (added in Java 8) can be used.
 */

import java
import semmle.code.java.dataflow.DataFlow

class TypeSimpleDateFormat extends Class {
    TypeSimpleDateFormat() {
        hasQualifiedName("java.text", "SimpleDateFormat")
    }
}

class DateFormatGetInstanceMethod extends Method {
    DateFormatGetInstanceMethod() {
        getDeclaringType().hasQualifiedName("java.text", "DateFormat")
        and isStatic()
        and getName().matches("get%Instance")
    }
}

from Expr newExpr
where
    (
        newExpr.(ClassInstanceExpr).getConstructedType() instanceof TypeSimpleDateFormat
        or newExpr.(MethodAccess).getMethod() instanceof DateFormatGetInstanceMethod
    )
    and not exists(MethodAccess setLenientCall |
        setLenientCall.getMethod().hasStringSignature("setLenient(boolean)")
        and DataFlow::localExprFlow(newExpr, setLenientCall.getQualifier())
    )
    // Reduce false positives by making sure DateFormat is actually used for parsing
    and exists(MethodAccess parseCall |
        parseCall.getMethod().getName().matches("parse%")
        and DataFlow::localExprFlow(newExpr, parseCall.getQualifier())
    )
    and not newExpr.getEnclosingCallable().getDeclaringType() instanceof TestClass
select newExpr, "DateFormat instance is lenient"

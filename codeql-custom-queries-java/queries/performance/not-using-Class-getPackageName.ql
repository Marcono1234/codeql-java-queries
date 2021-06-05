/**
 * Finds calls to `Class.getPackage().getName()`. Java 9 added the method `Class.getPackageName()`
 * which should be used instead since it avoids creating the intermediate `Package` object.
 * Note however, that `Class.getPackage()` and `Class.getPackageName()` behave differently for
 * primitive types and arrays.
 */

import java

class GetPackageMethod extends Method {
    GetPackageMethod() {
        getDeclaringType() instanceof TypeClass
        and hasStringSignature("getPackage()")
    }
}

class PackageGetNameMethod extends Method {
    PackageGetNameMethod() {
        getDeclaringType().hasQualifiedName("java.lang", "Package")
        and hasStringSignature("getName()")
    }
}

from MethodAccess getPackageCall, MethodAccess getNameCall
where
    getPackageCall.getMethod() instanceof GetPackageMethod
    and getNameCall.getMethod() instanceof PackageGetNameMethod
    // Chained `getPackage().getName()` call
    // This is easier to detect than using dataflow (e.g. would have to make sure
    // Package is not passed to somewhere else) and avoids false positives for `null`
    // handling because `getPackage()` and `getPackageName()` behave differently for
    // arrays and primitives
    and getPackageCall = getNameCall.getQualifier()
select getPackageCall, "Can be replaced with Class.getPackageName()"

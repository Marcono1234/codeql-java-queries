/**
 * Finds cases where an equality check in the form of an
 * (indirect) `equals` or `hashCode` call is performed on a
 * `java.net.URL`. The documentation of `URL.equals` says:
 * > Two hosts are considered equivalent if both host names can be resolved into the same IP addresses
 *
 * Most often this is undesired and has the following disadvantages:
 * - `equals` and `hashCode` calls could block while the
 *   host name is being resolved.
 * - Different hosts (e.g. `example.net` and `example.com`)
 *   are considered equal if they have the same IP. This makes
 *   code dependent on internal network layouts and also makes
 *   its behavior inconsistent, for example when the internet
 *   connection is lost preventing resolution of host names.
 * - It leaks the local machine IP address when trying to
 *   resolve host names.
 *
 * Therefore `java.net.URI` or the external String form of the
 * URL should be used instead for equality checks.
 *
 * See also https://rules.sonarsource.com/java/RSPEC-2112
 */

import java
import semmle.code.java.dataflow.DataFlow

class TypeUrl extends Class {
    TypeUrl() {
        hasQualifiedName("java.net", "URL")
    }
}

abstract class EqualityCheckingExpr extends Expr {
    abstract Expr getAEqualityCheckedArg();
}

class HashCodeCall extends MethodAccess, EqualityCheckingExpr {
    HashCodeCall() {
        getMethod() instanceof HashCodeMethod
    }
    
    override Expr getAEqualityCheckedArg() {
        result = getQualifier()
    }
}

class EqualsCall extends MethodAccess, EqualityCheckingExpr {
    EqualsCall() {
        getMethod() instanceof EqualsMethod
    }
    
    override Expr getAEqualityCheckedArg() {
        result = getQualifier()
        or result = getArgument(0)
    }
}

class TypeObjects extends Class {
    TypeObjects() {
        hasQualifiedName("java.util", "Objects")
    }
}

class ObjectsHashCodeCall extends MethodAccess, EqualityCheckingExpr {
    ObjectsHashCodeCall() {
        exists (Method m | m = getMethod() |
            m.getDeclaringType() instanceof TypeObjects
            and m.hasName(["hash", "hashCode"])
        )
    }
    
    override Expr getAEqualityCheckedArg() {
        result = getAnArgument()
    }
}

class ObjectsEqualsCall extends MethodAccess, EqualityCheckingExpr {
    ObjectsEqualsCall() {
        exists (Method m | m = getMethod() |
            m.getDeclaringType() instanceof TypeObjects
            and m.hasName(["equals", "deepEquals"])
        )
    }
    
    override Expr getAEqualityCheckedArg() {
        result = getAnArgument()
    }
}

class CollectionMethodCall extends MethodAccess, EqualityCheckingExpr {
    CollectionMethodCall() {
        exists (Method m | getMethod().getSourceDeclaration().overridesOrInstantiates*(m) |
            m.getDeclaringType().hasQualifiedName("java.util", "Collection")
            and m.hasStringSignature(["contains(Object)", "remove(Object)"])
        )
    }
    
    override Expr getAEqualityCheckedArg() {
        result = getArgument(0)
    }
}

class CollectionsMethodCall extends MethodAccess, EqualityCheckingExpr {
    CollectionsMethodCall() {
        exists (Method m, int paramsCount | m = getMethod() and paramsCount = m.getNumberOfParameters() |
            m.getDeclaringType().hasQualifiedName("java.util", "Collections")
            and (
                m.hasName(["binarySearch", "frequency"]) and paramsCount = 2
                or m.hasName("replaceAll") and paramsCount = 3
            )
        )
    }
    
    override Expr getAEqualityCheckedArg() {
        result = getArgument(1)
    }
}

class SetAddMethodCall extends MethodAccess, EqualityCheckingExpr {
    SetAddMethodCall() {
        exists (Method m | getMethod().getSourceDeclaration().overridesOrInstantiates*(m) |
            m.getDeclaringType().hasQualifiedName("java.util", "Set")
            and m.hasStringSignature(["add(E)", "remove(Object)"])
        )
    }
    
    override Expr getAEqualityCheckedArg() {
        result = getArgument(0)
    }
}

class ListIndexMethodCall extends MethodAccess, EqualityCheckingExpr {
    ListIndexMethodCall() {
        exists (Method m | getMethod().getSourceDeclaration().overridesOrInstantiates*(m) |
            m.getDeclaringType().hasQualifiedName("java.util", "List")
            and m.hasName(["indexOf", "lastIndexOf"])
        )
    }
    
    override Expr getAEqualityCheckedArg() {
        result = getArgument(0)
    }
}

class MapMethodCall extends MethodAccess, EqualityCheckingExpr {
    MapMethodCall() {
        exists (Method m | getMethod().getSourceDeclaration().overridesOrInstantiates*(m) |
            m.getDeclaringType().hasQualifiedName("java.util", "Map")
            and m.hasName(["compute", "computeIfAbsent", "computeIfPresent", "containsKey", "containsValue", "get", "getOrDefault", "merge", "put", "putIfAbsent", "remove", "replace"])
        )
    }
    
    override Expr getAEqualityCheckedArg() {
        result = getArgument(0)
    }
}

from Expr urlEqualityCheck
where
    urlEqualityCheck.(EqualityCheckingExpr).getAEqualityCheckedArg().getType() instanceof TypeUrl
    // Or method which checks equality is called with URL argument
    or exists (Callable callee, Callable called, int paramIndex, Parameter param |
        urlEqualityCheck.(Call).getCallee().getSourceDeclaration() = callee
        and if callee instanceof Method then callee.(Method).overridesOrInstantiates(called)
        else called = callee
        and urlEqualityCheck.(Call).getArgument(paramIndex).getType() instanceof TypeUrl
        and param = called.getParameter(paramIndex)
    |
        // Ignore if parameter type is URL because then `called` will already be flagged
        not param.getType() instanceof TypeUrl
        and DataFlow::localFlow(
            DataFlow::parameterNode(called.getParameter(paramIndex)),
            DataFlow::exprNode(any (EqualityCheckingExpr e).getAEqualityCheckedArg())
        )
    )
select urlEqualityCheck, "Checks equality of java.net.URL"

/**
 * Finds usage of the reflection classes `Field` and `Method` where they refer to
 * a static member, but a non-`null` value is provided as `obj` argument when the
 * member is used through reflection. For static members the `obj` value is ignored,
 * as mentioned by the documentation, therefore to avoid any confusion and to avoid
 * any unnecessarily verbose code, `null` should be provided as `obj` argument for
 * static members.
 * 
 * For example:
 * ```java
 * Field f = MyClass.class.getField("MY_STATIC_FIELD");
 * // Argument `MyClass.class` is redundant; could simplify this to `f.get(null)`
 * Object value = f.get(MyClass.class);
 * ```
 *
 * @kind problem
 */

import java
import semmle.code.java.Reflection 
import semmle.code.java.dataflow.DataFlow

class FieldUsageMethod extends Method {
    FieldUsageMethod() {
        getDeclaringType().hasQualifiedName("java.lang.reflect", "Field")
        and getName().matches(["get%", "set%"])
        // "get%" and "set%" also match unrelated methods; verify that first parameter is `Object obj`
        and getParameterType(0) instanceof TypeObject
    }
}

class MethodUsageMethod extends Method {
    MethodUsageMethod() {
        getDeclaringType().hasQualifiedName("java.lang.reflect", "Method")
        and hasName("invoke")
    }
}

from ClassMethodAccess classMethodAccess, Member usedMember, MethodAccess reflectiveUsage, Expr objArgument
where
    DataFlow::localFlow(DataFlow::exprNode(classMethodAccess), DataFlow::exprNode(reflectiveUsage.getQualifier()))
    // Used field or method is static
    and usedMember.isStatic()
    and objArgument = reflectiveUsage.getArgument(0)
    // And `obj` argument is not null
    and not objArgument instanceof NullLiteral
    and (
        (
            usedMember = classMethodAccess.(ReflectiveFieldAccess).inferAccessedField()
            and reflectiveUsage.getMethod() instanceof FieldUsageMethod
        )
        or (
            // Note: Causes some false positives due to https://github.com/github/codeql/issues/13490
            usedMember = classMethodAccess.(ReflectiveMethodAccess).inferAccessedMethod()
            and reflectiveUsage.getMethod() instanceof MethodUsageMethod
        )
    )
select objArgument, "Should provide `null` as argument because member `" + usedMember.getQualifiedName() + "` accessed through reflection is static"

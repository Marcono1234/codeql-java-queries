/**
 * Finds code which creates a `Set` with duplicated elements or which adds duplicated
 * elements to an existing `Set`. This is most likely an oversight since `Set`s can
 * only store an element once and ignore duplicates.
 * 
 * When using Java 9 the `Set.of` static factory methods can be used which throw an
 * exception for duplicate elements and can therefore help detecting this issue.
 * 
 * @kind problem
 */

import java
import semmle.code.java.dataflow.DataFlow

class SetType extends RefType {
    SetType() {
        getSourceDeclaration().getASourceSupertype*().hasQualifiedName("java.util", "Set")
    }
}

predicate haveSameValue(Expr e1, Expr e2) {
    exists(Literal l1, Literal l2 | l1 = e1 and l2 = e2 |
        // Check for same kind to avoid matching for example boolean `true` and `"true"`
        l1.getKind() = l2.getKind()
        and l1.getValue() = l2.getValue()
    )
    or exists(CompileTimeConstantExpr c1, CompileTimeConstantExpr c2 | c1 = e1 and c2 = e2 |
        c1.getBooleanValue() = c2.getBooleanValue()
        or c1.getIntValue() = c2.getIntValue()
        or c1.getStringValue() = c2.getStringValue()
    )
}

from Expr originalArg, Expr duplicateArg, MethodAccess varargsCall, int varargsIndex, Call setAddition
where
    haveSameValue(originalArg, duplicateArg)
    and originalArg.getIndex() < duplicateArg.getIndex()
    and (
        // Either explicit array passed to varargs
        exists(ArrayInit arrayInit |
            originalArg = arrayInit.getAnInit()
            and duplicateArg = arrayInit.getAnInit()
            // Make sure originalArg appears first to avoid reporting same result twice
            and originalArg.getIndex() < duplicateArg.getIndex()
            and DataFlow::localExprFlow(arrayInit, varargsCall.getArgument(varargsIndex))
        )
        // Or provided as varargs arguments
        or exists(int originalIndex, int duplicateIndex |
            originalArg = varargsCall.getArgument(originalIndex)
            and duplicateArg = varargsCall.getArgument(duplicateIndex)
            and originalIndex >= varargsIndex
            // Make sure originalArg appears first to avoid reporting same result twice
            and originalIndex < duplicateIndex
        )
    )
    and exists(Method varargsMethod | varargsMethod = varargsCall.getMethod().getSourceDeclaration() |
        // Usage of Collections.addAll with Set
        (
            varargsMethod.getDeclaringType().hasQualifiedName("java.util", "Collections")
            and varargsMethod.hasName("addAll")
            and varargsIndex = 1
            // And elements are added to Set
            and varargsCall.getArgument(0).getType() instanceof SetType
            // Arguments are directly added to Set
            and varargsCall = setAddition
        )
        or
        // Or first creates List with Arrays.asList or List.of and then adds elements to Set
        exists(Expr setAdditionSink |
            (
                varargsMethod.getDeclaringType().hasQualifiedName("java.util", "Arrays")
                and varargsMethod.hasName("asList")
                or
                varargsMethod.getDeclaringType().hasQualifiedName("java.util", "List")
                and varargsMethod.hasName("of")
            )
            and varargsIndex = 0
            and DataFlow::localExprFlow(varargsCall, setAdditionSink)
        |
            // Calling Set implementation constructor
            (
                setAddition.(ConstructorCall).getConstructedType() instanceof SetType
                and setAddition.getCallee().getNumberOfParameters() = 1
                and setAdditionSink = setAddition.getAnArgument()
            )
            // Or adding to existing Set
            or (
                setAddition.(MethodAccess).getMethod().getSourceDeclaration().getDeclaringType() instanceof SetType
                and setAddition.getCallee().getNumberOfParameters() = 1
                and setAddition.getCallee().hasName("addAll")
                and setAdditionSink = setAddition.getAnArgument()
            )
        )
    )
select duplicateArg, "Is the same as $@ argument, both being added to a Set $@",
    originalArg, "this", setAddition, "here"

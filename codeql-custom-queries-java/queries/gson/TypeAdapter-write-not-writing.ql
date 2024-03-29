/**
 * Finds implementations of Gson's `TypeAdaper` whose `write` method does not write
 * a value to the `JsonWriter` argument. This causes the `JsonWriter` to get into
 * in inconsistent state causing misleading exceptions for subsequent adapters.
 * 
 * @kind path-problem
 */

import java


class TypeTypeAdapter extends Class {
    TypeTypeAdapter() {
        hasQualifiedName("com.google.gson", "TypeAdapter")
    }
}

class TypeAdapterWriteMethod extends Method {
    TypeAdapterWriteMethod() {
        getDeclaringType().getASourceSupertype*() instanceof TypeTypeAdapter
        and hasName("write")
    }
}

class TypeJsonWriter extends Class {
    TypeJsonWriter() {
        hasQualifiedName("com.google.gson.stream", "JsonWriter")
    }
}

class WritingJsonWriterMethod extends Method {
    WritingJsonWriterMethod() {
        getDeclaringType().getASourceSupertype*() instanceof TypeJsonWriter
        and hasName([
            "beginArray",
            "beginObject",
            "endArray",
            "endObject",
            "jsonValue",
            "name",
            "nullValue",
            "value"
        ])
    }
}

predicate isUsageWithSideEffects(VarAccess writerAccess) {
    exists(MethodAccess writingCall |
        writingCall.getMethod() instanceof WritingJsonWriterMethod
        and writingCall.getQualifier() = writerAccess
    )
    // Or used in a different context, e.g. as method argument
    or not exists(MethodAccess call |
        call.getQualifier() = writerAccess
    )
}

ControlFlowNode getMethodExitNode(Method m) {
    // Method itself seems to represent exit of body
    result = m
}

predicate isExceptionExit(ControlFlowNode a, ControlFlowNode b) {
    b = getMethodExitNode(b.getEnclosingCallable())
    // Check this instead of just testing for ThrowStmt because CodeQL seems
    // to also consider exceptions thrown by called methods (?)
    and a.getAnExceptionSuccessor() = b
}

query predicate edges(ControlFlowNode a, ControlFlowNode b) {
    a.getASuccessor() = b
    // Ignore exceptional exit from method
    and not isExceptionExit(a, b)
    // And there is no writing action
    and not exists(VarAccess writerAccess |
        writerAccess.getType() instanceof TypeJsonWriter
        and isUsageWithSideEffects(writerAccess)
        and writerAccess.getControlFlowNode() = [a, b]
    )
}

from TypeAdapterWriteMethod writeMethod, ControlFlowNode entryNode, ControlFlowNode exitNode
where
    entryNode = writeMethod.getBody().getBasicBlock().getFirstNode()
    and exitNode = getMethodExitNode(writeMethod)
    and edges+(entryNode, exitNode)
select exitNode, entryNode, exitNode, "Exits `write` method without actually having written something"

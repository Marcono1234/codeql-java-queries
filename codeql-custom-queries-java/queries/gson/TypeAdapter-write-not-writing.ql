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

query predicate edges(ControlFlowNode a, ControlFlowNode b) {
    a.getASuccessor() = b
    // Ignore exceptional exit from method
    and not a.getEnclosingStmt() instanceof ThrowStmt
    // And there is no writing action
    and not exists(VarAccess writerAccess, ControlFlowNode writerAccessNode |
        writerAccess.getType() instanceof TypeJsonWriter
        and isUsageWithSideEffects(writerAccess)
        and writerAccessNode = writerAccess.getControlFlowNode()
        and (
            a = writerAccessNode
            or
            // Or there is a different (transitive) path from `a` to `b`
            a.getASuccessor+() = writerAccessNode
            and writerAccessNode.getASuccessor*() = b
        )
    )
}

from TypeAdapterWriteMethod writeMethod, ControlFlowNode entryNode, ControlFlowNode exitNode
where
    entryNode = writeMethod.getBody().getBasicBlock().getFirstNode()
    // Method itself seems to represent exit of body
    and exitNode = writeMethod
    and edges+(entryNode, exitNode)
select exitNode, entryNode, exitNode, "Exits `write` method without actually having written something"

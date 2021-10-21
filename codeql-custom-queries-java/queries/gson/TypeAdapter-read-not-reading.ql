/**
 * Finds implementations of Gson's `TypeAdaper` whose `read` method does not consume
 * a value from the `JsonReader` argument. This causes the `JsonReader` to get into
 * in inconsistent state causing misleading exceptions for subsequent adapters.
 * 
 * For example:
 * ```java
 * class CustomAdapter extends TypeAdapter<String> {
 *     @Override
 *     public String read(JsonReader reader) throws IOException {
 *         if (reader.peek() == JsonToken.NULL) {
 *             // Bad: Does not consume the JSON null
 *             return null;
 *         }
 * 
 *         ...
 *     }
 * 
 *     ...
 * }
 * ```
 * 
 * @kind path-problem
 */

import java


class TypeTypeAdapter extends Class {
    TypeTypeAdapter() {
        hasQualifiedName("com.google.gson", "TypeAdapter")
    }
}

class TypeAdapterReadMethod extends Method {
    TypeAdapterReadMethod() {
        getDeclaringType().getASourceSupertype*() instanceof TypeTypeAdapter
        and hasStringSignature("read(JsonReader)")
    }
}

class TypeJsonReader extends Class {
    TypeJsonReader() {
        hasQualifiedName("com.google.gson.stream", "JsonReader")
    }
}

class SideEffectFreeReaderMethod extends Method {
    SideEffectFreeReaderMethod() {
        getDeclaringType().getASourceSupertype*() instanceof TypeJsonReader
        and hasStringSignature([
            "getPath()",
            "hasNext()",
            "isLenient()",
            "peek()"
        ])
    }
}

predicate isUsageWithSideEffects(VarAccess readerAccess) {
    // Consider every usage which is not known to be side-effect free as having side
    // effects, including other method calls and passing it as argument
    not exists(MethodAccess sideEffectFreeCall |
        sideEffectFreeCall.getMethod() instanceof SideEffectFreeReaderMethod
        and sideEffectFreeCall.getQualifier() = readerAccess
    )
}

query predicate edges(ControlFlowNode a, ControlFlowNode b) {
    a.getASuccessor() = b
    // And there is no reading action
    and not exists(VarAccess readerAccess |
        readerAccess.getType() instanceof TypeJsonReader
        and isUsageWithSideEffects(readerAccess)
        and readerAccess.getControlFlowNode() = [a, b]
    )
}

ControlFlowNode getSuccessfulExitNode(Callable c) {
    exists(ReturnStmt returnStmt |
        returnStmt.getEnclosingCallable() = c
        and result = returnStmt.getResult().getControlFlowNode()
    )
}

from TypeAdapterReadMethod readMethod, ControlFlowNode entryNode, ControlFlowNode exitNode
where
        entryNode = readMethod.getBody().getBasicBlock().getFirstNode()
        and exitNode = getSuccessfulExitNode(readMethod)
        and edges+(entryNode, exitNode)
select exitNode, entryNode, exitNode, "Returns from `read` method without actually having read something"

import java
import semmle.code.java.dataflow.DataFlow

private predicate isOwnFieldAccess(FieldAccess fieldAccess) {
    fieldAccess.getField().isStatic()
    or fieldAccess.isOwnFieldAccess()
}

/**
 * Holds if the step from `node1` to `node2` is the assignment to a field followed
 * by a read of the field.
 */
predicate isOwnFieldStep(DataFlow::Node node1, DataFlow::Node node2) {
    exists(FieldWrite fieldWrite, FieldRead fieldRead |
        fieldWrite.getField() = fieldRead.getField()
        and isOwnFieldAccess(fieldWrite)
        and isOwnFieldAccess(fieldRead)
        and fieldWrite.getRhs() = node1.asExpr()
        and fieldRead = node2.asExpr()
    )
}

/**
 * Finds flow from the `java.io.Console` methods `readLine` and `readPassword` to a
 * dereferencing expression without any `null` check guarding the dereferencing.
 *
 * The documentation for these methods says that they return "`null` if an end of
 * stream has been reached". Such an "end of stream" usually happens when the
 * user presses `Ctrl` + `C` in the console. Even though this will likely terminate
 * the JVM in most cases; often `null` is still returned and a few more statements
 * are executed before the JVM exits. If no `null` check is performed, a confusing
 * `NullPointerException` might arise; possibly even without any printed stack
 * trace due to being interrupted by the JVM exit.
 *
 * @kind path-problem
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.Nullness
import semmle.code.java.dataflow.NullGuards
import DataFlow::PathGraph

class NullableConsoleCall extends MethodAccess {
    NullableConsoleCall() {
        exists(Method m | m  = getMethod() |
            m.getDeclaringType().hasQualifiedName("java.io", "Console")
            and m.hasName(["readLine", "readPassword"])
        )
    }
}

class NullCheckBarrierGuard extends DataFlow::BarrierGuard {
    Expr checked;
    boolean isNullBranch;

    NullCheckBarrierGuard() {
        exists(boolean branch, boolean isNull |
            // Guard represents a null check, determine which value `isNullBranch`
            // must have to indicate that the checked expression is null
            this = basicOrCustomNullGuard(checked, branch, isNull)
            and if isNull = true then isNullBranch = branch
            else isNullBranch = branch.booleanNot()
        )
    }

    override
    predicate checks(Expr e, boolean branch) {
        // Guard discards any dataflow to non-null branch
        e = checked and branch = isNullBranch.booleanNot()
    }
}

class ConsoleDataFlowConfiguration extends DataFlow::Configuration {
    ConsoleDataFlowConfiguration() { this = "ConsoleDataFlowConfiguration" }

    override
    predicate isSource(DataFlow::Node source) {
        source.asExpr() instanceof NullableConsoleCall
    }

    override
    predicate isSink(DataFlow::Node sink) {
        // Dereferences expression which could cause a NullPointerException
        dereference(sink.asExpr())
    }

    override
    predicate isBarrierGuard(DataFlow::BarrierGuard guard) {
        guard instanceof NullCheckBarrierGuard
    }
}

from ConsoleDataFlowConfiguration config, DataFlow::PathNode source, DataFlow::PathNode sink
where config.hasFlowPath(source, sink)
select sink.getNode(), source, sink, "Might throw NullPointerException because Console read result is not checked for null"

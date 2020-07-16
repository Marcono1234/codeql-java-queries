/**
 * Finds cases where user-controlled data flows to one of the Java methods
 * or constructors which allow creating an operating system process.
 * In contrast to QL's built-in query this query checks for flow to any of
 * the arguments (and not only the program name).
 * Under Windows the System property `jdk.lang.Process.allowAmbiguousCommands`
 * has to be set to `false`. Otherwise Windows' pre-processing of arguments
 * (https://docs.microsoft.com/en-us/cpp/cpp/main-function-command-line-args?view=vs-2019#parsing-c-command-line-arguments)
 * will split and merge arguments containing double quotes which can allow
 * command injection. However, this System property is not that well-known
 * and is likely often not set, making the application vulnerable.
 *
 * @kind path-problem
 */

/*
 * Similar to QL's semmle.code.java.security.ExternalProcess ArgumentToExec
 * However that only checks the program name and not the other arguments
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.FlowSources
import DataFlow::PathGraph

class CommandExecutingCallable extends Callable {
    int commandArgIndex;
    
    CommandExecutingCallable() {
        exists (string declName, string name |
            declName = getDeclaringType().getQualifiedName()
            and name = getName()
        |
            (
                declName = "java.lang.Runtime"
                and name = "exec"
                and commandArgIndex = 0
            )
            or (
                declName = "java.lang.ProcessBuilder"
                and name = [
                    "ProcessBuilder", // Constructor
                    "command"
                ]
                and commandArgIndex = [0 .. 2147483647] // In case of vararg
            )
        )
    }
    
    int getCommandArgIndex() {
        result = commandArgIndex
    }
}

class ListAddingMethod extends Method {
    int newElementParamIndex;
    
    ListAddingMethod() {
        (
            getDeclaringType().getSourceDeclaration().getASourceSupertype*().hasQualifiedName("java.util", "Collection")
            and hasName(["add", "addAll"])
            and getNumberOfParameters() = 1
            and newElementParamIndex = 0
        )
        or (
            getDeclaringType().getSourceDeclaration().getASourceSupertype*().hasQualifiedName("java.util", "List")
            and hasName(["add", "addAll", "set"])
            and getNumberOfParameters() = 2
            and newElementParamIndex = 1
        )
    }
    
    int getNewElementParamIndex() {
        result = newElementParamIndex
    }
}

class CommandReturningMethod extends Method {
    CommandReturningMethod() {
        getDeclaringType().hasQualifiedName("java.lang", "ProcessBuilder")
        and hasStringSignature("command()")
    }
}

class CommandExecutingCall extends Call {
    int commandArgIndex;
    
    CommandExecutingCall() {
        commandArgIndex = this.getCallee().(CommandExecutingCallable).getCommandArgIndex()
        // ProcessBuilder.command() returns mutable array, check if arguments are added
        // to that array
        or exists (MethodAccess commandCall, MethodAccess listAddingCall |
            commandCall.getMethod() instanceof CommandReturningMethod
            and listAddingCall.getMethod() instanceof ListAddingMethod
        |
            // TODO: Maybe should even consider global dataflow though that is likely too expensive
            DataFlow::localFlow(DataFlow::exprNode(commandCall), DataFlow::exprNode(listAddingCall.getQualifier()))
            and commandArgIndex = listAddingCall.getMethod().(ListAddingMethod).getNewElementParamIndex()
        )
    }
    
    Expr getCommandArg() {
        result = getArgument(commandArgIndex)
    }
}

class RemoteCommandExecutionConfiguration extends TaintTracking::Configuration {
    RemoteCommandExecutionConfiguration() {
        this = "RemoteCommandExecution"
    }
        
    override predicate isSource(DataFlow::Node source) {
        source instanceof RemoteFlowSource
    }

    override predicate isSink(DataFlow::Node sink) {
        exists (CommandExecutingCall call |
            sink.asExpr() = call.getCommandArg()
        )
    }
    
    override predicate isSanitizerOut(DataFlow::Node node) {
        (
            node.getType() instanceof PrimitiveType
            or node.getType() instanceof BoxedType
        )
        // char might be `"` which causes issues under Windows
        and not node.getType().hasName(["char", "Character"])
    }
}

from RemoteCommandExecutionConfiguration config, DataFlow::PathNode source, DataFlow::PathNode sink
where
    config.hasFlowPath(source, sink)
select sink.getNode(), source, sink, "OS command is created using user-controlled $@.", source.getNode(), "data"

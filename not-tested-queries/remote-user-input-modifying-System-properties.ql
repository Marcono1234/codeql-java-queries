/**
 * Finds paths from remote user input to methods modifying System properties
 * (adding new properties, or modifying or removing existing ones).
 * System properties are shared for the complete application; allowing user
 * input to modify them might break the application, disable security features
 * or lead to race conditions.
 *
 * @kind path-problem
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.FlowSources

/**
 * Method call for which some of the arguments modify the System properties.
 */
abstract class SystemPropertiesChangingCall extends MethodAccess {
}

class SystemPropertyClearOrSetCall extends SystemPropertiesChangingCall {
    SystemPropertyClearOrSetCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType() instanceof TypeSystem
            and m.hasStringSignature([
                "clearProperty(String)",
                "setProperty(String, String)"
            ])
        )
    }
}

// Not directly System properties, but cover Security properties as well
class SecurityPropertySetCall extends SystemPropertiesChangingCall {
    SecurityPropertySetCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType().hasQualifiedName("java.security", "Security")
            and m.hasStringSignature("setProperty(String, String)")
        )
    }
}

/**
 * Call to `System.getProperties()`.
 */
class GetSystemPropertiesCall extends MethodAccess {
    GetSystemPropertiesCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType() instanceof TypeSystem
            and m.hasStringSignature("getProperties()")
        )
    }
}

/**
 * Call to `System.setProperties(Properties)`.
 */
class SetSystemPropertiesCall extends MethodAccess {
    SetSystemPropertiesCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType() instanceof TypeSystem
            and m.hasStringSignature("setProperties(Properties)")
        )
    }
}

class TypeProperties extends Class {
    TypeProperties() {
        hasQualifiedName("java.util", "Properties")
    }
}

class PropertiesChangingCall extends MethodAccess {
    PropertiesChangingCall() {
        exists(Method m | m = getMethod() |
            // Check Properties and sub- and supertype methods
            m.getDeclaringType().getASourceSupertype*() = any(TypeProperties p).getASourceSupertype*()
            // Check for methods where user controlled data could be key or value
            and m.hasName([
                "setProperty",
                // Hashtable methods (Properties extends Hashtable<Object, Object>)
                "compute", "computeIfAbsent", "computeIfPresent",
                "merge",
                "put",
                "remove",
                // Inherited from Map
                "putIfAbsent",
                "remove",
                "replace"
            ])
        )
    }
}

/**
 * Call modifying `Properties` which originate from `System.getProperties()`.
 */
class SystemPropertiesFlowChangingCall extends SystemPropertiesChangingCall, PropertiesChangingCall {
    SystemPropertiesFlowChangingCall() {
        DataFlow::localFlow(DataFlow::exprNode(any(GetSystemPropertiesCall p)), DataFlow::exprNode(getQualifier()))
    }
}

/**
 * Call modifying `Properties` which are then later set using `System.setProperties(...)`.
 */
class SystemPropertiesFlowReplacingCall extends SystemPropertiesChangingCall, PropertiesChangingCall {
    SystemPropertiesFlowReplacingCall() {
        DataFlow::localFlow(DataFlow::exprNode(getQualifier()), DataFlow::exprNode(any(SetSystemPropertiesCall c).getArgument(0)))
    }
}

// TODO: Model call flow from user triggered method (e.g. HTTP POST) to Properties modifying method,
//       e.g. `Properties.clear()`; currently not possible with CodeQL only supports data / taint flow?

class SystemPropertyDataFlowConfiguration extends DataFlow::Configuration {
    SystemPropertyDataFlowConfiguration() { this = "SystemPropertyDataFlowConfiguration" }

    override
    predicate isSource(DataFlow::Node source) {
        source instanceof RemoteFlowSource
    }

    override
    predicate isSink(DataFlow::Node sink) {
        any(SystemPropertiesChangingCall c).getAnArgument() = sink.asExpr()
    }
}

from SystemPropertyDataFlowConfiguration config, DataFlow::PathNode source, DataFlow::PathNode sink
where config.hasFlowPath(source, sink)
select sink.getNode(), source, sink, "Modifies System properties"

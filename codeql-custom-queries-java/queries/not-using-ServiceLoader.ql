/**
 * Finds classes which are using System properties to specify class names
 * instead of using [`ServiceLoader`](https://docs.oracle.com/en/java/javase/15/docs/api/java.base/java/util/ServiceLoader.html).
 * `ServiceLoader` should be preferred because it makes it easier for
 * depending projects to specify an implementation. Especially if these
 * projects are themselves dependencies of other projects they might not
 * be able to reliably set the System properties before the respective
 * class reading the System properties is loaded.
 * Additionally with the Java Platform Module System, services and their
 * providers have to be defined in the module declaration which makes it
 * easier to understand which class is used as provider for which service,
 * see also [Module System Quick-Start Guide](https://openjdk.java.net/projects/jigsaw/quick-start#services).
 */

import java
import semmle.code.java.dataflow.DataFlow

abstract class ClassLoadingMethod extends Method {
    abstract int getClassNameParamIndex();
}

class ClassForName extends ClassLoadingMethod {
    ClassForName() {
        getDeclaringType() instanceof TypeClass
        and hasName("forName")
    }
    
    override
    int getClassNameParamIndex() {
        result = [0 .. getNumberOfParameters() - 1]
        and getParameterType(result) instanceof TypeString
    }
}

class TypeClassLoader extends Class {
    TypeClassLoader() {
        hasQualifiedName("java.lang", "ClassLoader")
    }
}

class ClassLoaderLoadClass extends ClassLoadingMethod {
    ClassLoaderLoadClass() {
        getDeclaringType().getASourceSupertype*() instanceof TypeClassLoader
        and hasName("loadClass")
    }
    
    override
    int getClassNameParamIndex() {
        result = [0 .. getNumberOfParameters() - 1]
        and getParameterType(result) instanceof TypeString
    }
}

class ClassLoadingDataFlowConfiguration extends DataFlow::Configuration {
    ClassLoadingDataFlowConfiguration() { this = "ClassLoadingDataFlowConfiguration" }
    
    override
    predicate isSource(DataFlow::Node source) {
        source.asExpr().(MethodAccess).getMethod() instanceof MethodSystemGetProperty
    }
    
    override
    predicate isSink(DataFlow::Node sink) {
        exists(MethodAccess classLoadingCall, ClassLoadingMethod classLoadingMethod |
            classLoadingMethod = classLoadingCall.getMethod()
            and sink.asExpr() = classLoadingCall.getArgument(classLoadingMethod.getClassNameParamIndex())
        )
    }
}

from ClassLoadingDataFlowConfiguration config, DataFlow::Node source, DataFlow::Node sink
where
    config.hasFlow(source, sink)
select source, "Should use ServiceLoader instead of getting class name from System property and then loading class $@", sink, "here"

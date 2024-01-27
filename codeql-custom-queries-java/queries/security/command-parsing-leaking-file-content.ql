/**
 * Detects flow from remote user input to a command parsing library which supports
 * syntax for reading arguments from a file (usually `@filename`). This can allow
 * an attacker to obtain the content of arbitrary files.
 *
 * To prevent this, use the corresponding library settings to disable this behavior:
 * - Args4J: `ParserProperties.withAtSyntax(false)`
 * - JCommander: `JCommander$Builder.expandAtSign(false)`
 *
 * This issue lead to [CVE-2024-23897 in Jenkins](https://www.jenkins.io/security/advisory/2024-01-24/).
 *
 * @id todo
 * @kind path-problem
 */

// TODO: This query has not found any vulnerable project yet, and also for Jenkins it did
// not detect this, probably because it did not consider the input to be remote user input

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.FlowSources

/* -- Args4J -- */
class ClassParserProperties extends Class {
  ClassParserProperties() { hasQualifiedName("org.kohsuke.args4j", "ParserProperties") }
}

class ClassCmdLineParser extends Class {
  ClassCmdLineParser() { hasQualifiedName("org.kohsuke.args4j", "CmdLineParser") }
}

/** Value flow for `ParserProperties.withX` methods */
class ParserPropertiesFlowStep extends AdditionalValueStep {
  override predicate step(DataFlow::Node node1, DataFlow::Node node2) {
    node1.getType() instanceof ClassParserProperties and
    exists(MethodAccess builderCall |
      builderCall = node2.asExpr() and
      builderCall.getQualifier() = node1.asExpr() and
      builderCall.getMethod().getName().matches("with%")
    )
  }
}

// TODO: Maybe use global dataflow instead? Local dataflow would not detect Jenkins
// fixes in https://github.com/jenkinsci/jenkins/commit/554f03782057c499c49bbb06575f0d28b5200edb
predicate isSafeArgs4jParser(Expr e) {
  // Call to roughly `new CmdLineParser(..., properties.withAtSyntax(false))`
  exists(ClassInstanceExpr newParserExpr, MethodAccess withAtSyntaxCall, Method withAtSyntaxMethod |
    newParserExpr.getConstructedType() instanceof ClassCmdLineParser and
    withAtSyntaxCall.getMethod() = withAtSyntaxMethod and
    withAtSyntaxMethod.getDeclaringType() instanceof ClassParserProperties and
    withAtSyntaxMethod.hasName("withAtSyntax") and
    withAtSyntaxCall.getArgument(0).(CompileTimeConstantExpr).getBooleanValue() = false and
    DataFlow::localExprFlow(withAtSyntaxCall, newParserExpr.getArgument(1))
  |
    // Direct local flow
    DataFlow::localExprFlow(newParserExpr, e)
    or
    // Or flow through field
    exists(Field f |
      DataFlow::localExprFlow(newParserExpr, f.getAnAssignedValue()) and
      DataFlow::localExprFlow(f.getAnAccess(), e)
    )
  )
}

class Args4jSink extends DataFlow::Node {
  Args4jSink() {
    exists(MethodAccess parseCall, Method parseMethod |
      parseCall.getMethod() = parseMethod and
      parseMethod.getDeclaringType() instanceof ClassCmdLineParser and
      parseMethod.hasName("parseArgument") and
      this.asExpr() = parseCall.getAnArgument() and
      not isSafeArgs4jParser(parseCall.getQualifier())
    )
  }
}

/* -- JCommander -- */
class ClassJCommander extends Class {
  ClassJCommander() { hasQualifiedName("com.beust.jcommander", "JCommander") }
}

class ClassJCommanderBuilder extends Class {
  ClassJCommanderBuilder() { hasQualifiedName("com.beust.jcommander", "JCommander$Builder") }
}

/** Value flow for `JCommander$Builder` methods */
class JCommanderBuilderFlowStep extends AdditionalValueStep {
  override predicate step(DataFlow::Node node1, DataFlow::Node node2) {
    node1.getType() instanceof ClassJCommanderBuilder and
    node2.getType() instanceof ClassJCommanderBuilder and
    node2.asExpr().(MethodAccess).getQualifier() = node1.asExpr()
  }
}

/** Flow for `JCommander$Builder.build()`; for simplicity treat this as value flow (instead of taint) */
class JCommanderBuildFlowStep extends AdditionalValueStep {
  override predicate step(DataFlow::Node node1, DataFlow::Node node2) {
    node1.getType() instanceof ClassJCommanderBuilder and
    exists(MethodAccess buildCall |
      buildCall = node2.asExpr() and
      buildCall.getQualifier() = node1.asExpr() and
      buildCall.getMethod().hasName("build")
    )
  }
}

predicate isSafeJCommanderParser(Expr e) {
  exists(MethodAccess expandAtSignCall, Method expandAtSignMethod, Expr affectedJCommander |
    // Call to `builder.expandAtSign(false)`
    expandAtSignCall.getMethod() = expandAtSignMethod and
    expandAtSignMethod.getDeclaringType() instanceof ClassJCommanderBuilder and
    expandAtSignMethod.hasName("expandAtSign") and
    expandAtSignCall.getArgument(0).(CompileTimeConstantExpr).getBooleanValue() = false and
    // Flow from result of the builder call
    affectedJCommander = expandAtSignCall
    or
    // Or call to `jCommander.setExpandAtSign(false)`
    expandAtSignCall.getMethod() = expandAtSignMethod and
    expandAtSignMethod.getDeclaringType() instanceof ClassJCommander and
    expandAtSignMethod.hasName("setExpandAtSign") and
    expandAtSignCall.getArgument(0).(CompileTimeConstantExpr).getBooleanValue() = false and
    // Flow from qualifier (= JCommander instance)
    affectedJCommander = expandAtSignCall.getQualifier()
  |
    // Direct local flow
    DataFlow::localExprFlow(affectedJCommander, e)
    or
    // Or flow through field
    exists(Field f |
      DataFlow::localExprFlow(affectedJCommander, f.getAnAssignedValue()) and
      DataFlow::localExprFlow(f.getAnAccess(), e)
    )
  )
}

class JCommanderSink extends DataFlow::Node {
  JCommanderSink() {
    // Calling `JCommander` constructor which parses arguments
    exists(ClassInstanceExpr parseConstructorCall |
      parseConstructorCall.getConstructedType() instanceof ClassJCommander and
      this.asExpr() = parseConstructorCall.getAnArgument() and
      (
        this.getType() instanceof TypeString or
        this.getType().(Array).getElementType() instanceof TypeString
      )
    )
    or
    // Or calling `JCommander` parse method
    exists(MethodAccess parseCall, Method parseMethod |
      parseCall.getMethod() = parseMethod and
      parseMethod.getDeclaringType() instanceof ClassJCommander and
      parseMethod.hasName(["parse", "parseWithoutValidation"]) and
      this.asExpr() = parseCall.getAnArgument() and
      not isSafeJCommanderParser(parseCall.getQualifier())
    )
    or
    // Or calling `JCommander$Builder.args(...)`
    exists(MethodAccess builderArgsCall, Method argsMethod |
      builderArgsCall.getMethod() = argsMethod and
      argsMethod.getDeclaringType() instanceof ClassJCommanderBuilder and
      argsMethod.hasName("args") and
      this.asExpr() = builderArgsCall.getAnArgument() and
      not isSafeJCommanderParser(builderArgsCall.getQualifier())
    )
  }
}

/* ----- */

module CommandParserConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node source) { source instanceof RemoteFlowSource }

  predicate isSink(DataFlow::Node sink) {
    sink instanceof Args4jSink or sink instanceof JCommanderSink
  }
}

module CommandParserFlow = TaintTracking::Global<CommandParserConfig>;

import CommandParserFlow::PathGraph

from CommandParserFlow::PathNode source, CommandParserFlow::PathNode sink
where CommandParserFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "Remote user input flows into command parser which expands file contents"

/**
 * Finds paths from user-provided floating point values to arithmetic
 * calculations or comparison checks without verification that the
 * user-provided value is finite.
 * The floating point types `float` and `double` (and their respective
 * boxed variants) can have the non-finite values `NaN` and `Infinity`.
 * Performing calculations with these values can 'poison' variables
 * because the result will be a non-finite value as well.
 * Additionally `NaN` has the special property that it is never equal
 * to another value, not even to itself. This might therefore break
 * application logic.
 *
 * @kind path-problem
 */

import java
import semmle.code.java.arithmetic.Overflow
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.FlowSources
import DataFlow::PathGraph

class AssignArithExpr extends AssignOp {
    AssignArithExpr() {
        (
            this instanceof AssignAddExpr
            // Ignore String concatenation
            and not this.(AssignAddExpr).getDest().getType() instanceof TypeString
        )
        or this instanceof AssignSubExpr
        or this instanceof AssignMulExpr
        or this instanceof AssignDivExpr
        or this instanceof AssignRemExpr
    }
    
    Expr getAnOperand() {
        result = getDest()
        or result = getSource()
    }
}

class ArithExpr_ extends Expr {
    Expr operand;
    
    ArithExpr_() {
        operand = [
            this.(ArithExpr).getAnOperand(),
            this.(AssignArithExpr).getAnOperand()
        ]
    }
    
    Expr getAnOperand() {
        result = operand
    }
}

class BoxedFloatingPointType extends Class {
    BoxedFloatingPointType() {
        hasQualifiedName("java.lang", ["Float", "Double"])
    }
}

class FloatingPointParsingCallable extends Callable {
    FloatingPointParsingCallable() {
        getDeclaringType() instanceof BoxedFloatingPointType
        and getNumberOfParameters() = 1
        and getParameterType(0) instanceof TypeString
        and (
            this instanceof Constructor // Constructor Float(String) or Double(String)
            or this.(Method).hasName([
                "valueOf", // Float and Double valueOf(String)
                "parseFloat",
                "parseDouble"
            ])
        )
    }
}

abstract class FloatingPointFiniteCheck extends MethodAccess {
    abstract Expr getChecked();
}

/**
 * Static finite check method taking a primitive floating point value as argument.
 */
class PrimitiveFloatingPointFiniteCheck extends FloatingPointFiniteCheck {
    PrimitiveFloatingPointFiniteCheck() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType() instanceof BoxedFloatingPointType
            and m.hasName([
                "isFinite",
                "isInfinite",
                "isNaN"
            ])
            and m.getNumberOfParameters() = 1
        )
    }
    
    override
    Expr getChecked() {
        result = getArgument(0)
    }
}

/**
 * Instance finite check method on a boxed floating point value.
 */
class BoxedFloatingPointFiniteCheck extends FloatingPointFiniteCheck {
    BoxedFloatingPointFiniteCheck() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType() instanceof BoxedFloatingPointType
            and m.hasName([
                "isInfinite",
                "isNaN"
            ])
            and m.getNumberOfParameters() = 0
        )
    }
    
    override
    Expr getChecked() {
        result = getQualifier()
    }
}

// Use abstract class with separate configuration subclasses because that appears to
// be faster than combining both configurations into one and checking node type in
// isAdditionalFlowStep
abstract class AbstractFloatingPointFlowConfiguration extends DataFlow::Configuration {
    AbstractFloatingPointFlowConfiguration() {
        this = "AbstractFloatingPointFlowConfiguration"
    }
    
    override
    predicate isBarrier(DataFlow::Node node) {
        any(FloatingPointFiniteCheck c).getChecked() = node.asExpr()
    }
    
    override
    predicate isSink(DataFlow::Node sink) {
        exists(ArithExpr_ arithExpr |
            arithExpr.getAnOperand() = sink.asExpr()
            // Ignore if result is not floating point type anymore; conversion to integral
            // type converted non-finite value to finite one
            and arithExpr.getType() instanceof FloatingPointType
            and not any(CastExpr cast | cast.getExpr() = arithExpr).getType() instanceof IntegralType
        )
        or any(ComparisonExpr c).getAnOperand() = sink.asExpr()
    }
}

// Note: Ignore CodeQL warning about missing characteristics predicate
class FloatingPointFlowConfiguration extends AbstractFloatingPointFlowConfiguration {
    override
    predicate isSource(DataFlow::Node source) {
        source.getType() instanceof FloatingPointType // double or float (including boxed)
        and source instanceof RemoteFlowSource
    }
}

// Note: Ignore CodeQL warning about missing characteristics predicate
class StringFloatingPointFlowConfiguration extends AbstractFloatingPointFlowConfiguration {
    override
    predicate isSource(DataFlow::Node source) {
        source.getType() instanceof TypeString // String which is later parsed
        and source instanceof RemoteFlowSource
    }
    
    override
    predicate isAdditionalFlowStep(DataFlow::Node node1, DataFlow::Node node2) {
        // String is parsed to floating point type
        exists(Call parsingCall | parsingCall.getCallee() instanceof FloatingPointParsingCallable |
            parsingCall.getArgument(0) = node1.asExpr()
            and parsingCall = node2.asExpr() // result of parsing call is node2
        )
    }
}

from AbstractFloatingPointFlowConfiguration config, DataFlow::PathNode source, DataFlow::PathNode sink
where
    config.hasFlowPath(source, sink)
select sink.getNode(), source, sink, "Uses potentially non-finite user-provided floating point value"

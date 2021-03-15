/**
 * Finds calls to `CharsetEncoder` or `CharsetDecoder` methods, which return `CoderResult`,
 * where the caller is not handling the result properly. Failing to do so can lead
 * to incorrect encoding / decoding results or in the worst case cause infinite encoding
 * or decoding loops.
 *
 * The correct handling of `CoderResult` requires checking its state **and** the state of
 * the input and output buffers. For all methods returning a `CoderResult` (including
 * `flush()`) the result must be checked.
 *
 * The following describes the correct handling of `CoderResult`. When calling `flush()`
 * it is only necessary to check for `isOverflow()`; `isUnderflow()` indicates success
 * (without requiring further action) and `isError()` won't occur (according to the
 * documentation).  
 * Also consult the documentation of the `CharsetEncoder` and `CharsetDecoder` class.
 *
 * - When `CoderResult.isUnderflow()`:
 *   - If _output_ buffer has unconsumed data (i.e. progress was made): Consume it
 *   - Else:
 *     1. Ensure there is free space in the _input_ buffer (either by removing consumed
 *        data, or by enlarging buffer).  
 *        **Important:** There might still be unconsumed input data (e.g. when encoding
 *        there might be an unpaired high surrogate char); don't discard it!
 *     2. Fill _input_ buffer
 *     3. Repeat operation
 * - When `CoderResult.isOverflow()`:
 *   - If _output_ buffer has unconsumed data (i.e. progress was made): Consume it
 *   - Else:
 *     1. Increase free space in _output_ buffer (either by removing consumed data,
 *        or by enlarging buffer).  
 *        **Important:** The free space in _output_ buffer **must be increased**, even
 *        if there is available free space. For example when decoding, charsets might
 *        only write byte sequences at bulk so if the free space in the _output_ buffer
 *        does not suffice, no progress will be made at all.
 * - When `CoderResult.isError()`: Call `CoderResult.throwException()`. That method
 *   always throws an exception. However, the compiler does not understand this, so if
 *   necessary add a `return null` (or similar) with an explanation comment to make
 *   the compiler happy.
 */

import java
import semmle.code.java.dataflow.DataFlow

class TypeCoderResult extends Class {
    TypeCoderResult() {
        hasQualifiedName("java.nio.charset", "CoderResult")
    }
}

abstract class CodingOperationMethod extends Method {
    CodingOperationMethod() {
        getDeclaringType().getASourceSupertype*().hasQualifiedName("java.nio.charset", ["CharsetEncoder", "CharsetDecoder"])
        and getReturnType() instanceof TypeCoderResult
    }
    
    abstract Method getARequiredCheckMethod();
}

class CoderResultMethod extends Method {
    CoderResultMethod() {
        getDeclaringType() instanceof TypeCoderResult
    }
}

class IsErrorMethod extends CoderResultMethod {
    IsErrorMethod() {
        hasStringSignature("isError()")
    }
}

class IsOverflowMethod extends CoderResultMethod {
    IsOverflowMethod() {
        hasStringSignature("isOverflow()")
    }
}

class IsUnderflowMethod extends CoderResultMethod {
    IsUnderflowMethod() {
        hasStringSignature("isUnderflow()")
    }
}

class EncodingMethod extends CodingOperationMethod {
    EncodingMethod() {
        hasName(["encode", "encodeLoop"])
    }
    
    override
    Method getARequiredCheckMethod() {
        result instanceof IsErrorMethod
        or result instanceof IsOverflowMethod
        or result instanceof IsUnderflowMethod
    }
}

class DecodingMethod extends CodingOperationMethod {
    DecodingMethod() {
        hasName(["decode", "decodeLoop"])
    }
    
    override
    Method getARequiredCheckMethod() {
        result instanceof IsErrorMethod
        or result instanceof IsOverflowMethod
        or result instanceof IsUnderflowMethod
    }
}

// Covers CharsetEncoder and CharsetDecoder
class FlushMethod extends CodingOperationMethod {
    FlushMethod() {
        hasName(["flush", "implFlush"])
    }
    
    override
    Method getARequiredCheckMethod() {
        result instanceof IsOverflowMethod
        or result instanceof IsUnderflowMethod
        // flush cannot produce isError according to documentation
    }
}

/**
 * Gets a check method which is not explicitly called for the `coderResult` result.
 */
private Method getANotExplicitlyCheckedMethod(Expr coderResult, CodingOperationMethod codingMethod) {
    result = codingMethod.getARequiredCheckMethod()
    and not exists(MethodAccess checkCall |
        checkCall.getMethod() = result
        and DataFlow::localFlow(DataFlow::exprNode(coderResult), DataFlow::exprNode(checkCall.getQualifier()))
    )
}

/**
 * Holds if the `true` and `false` branches of the node are separate, i.e. when one branch finishes
 * it won't be the same as the other (which would be the case for an `if` without `else`, where the
 * 'then' does not `return`, `break` or similar).
 */
private predicate hasSeparateBranches(ConditionNode conditionNode) {
  not conditionNode.getATrueSuccessor().getASuccessor*() = conditionNode.getAFalseSuccessor()
  and not conditionNode.getAFalseSuccessor().getASuccessor*() = conditionNode.getATrueSuccessor()
}

private Method getANotCheckedMethod(Expr coderResult, CodingOperationMethod codingMethod) {
    exists(int missingExplicitCheckCalls |
        missingExplicitCheckCalls = count(getANotExplicitlyCheckedMethod(coderResult, codingMethod))
    |
        if (
            // All check methods are called
            missingExplicitCheckCalls = 0
            // Or 1 method is missing, but there is an `else` branch of one check call which
            // might cover it
            or (
                missingExplicitCheckCalls = 1
                and exists(MethodAccess checkCall, ConditionNode conditionNode |
                    checkCall.getMethod() = codingMethod.getARequiredCheckMethod()
                    and DataFlow::localFlow(DataFlow::exprNode(coderResult), DataFlow::exprNode(checkCall.getQualifier()))
                    and conditionNode.getCondition() = checkCall
                    // Only consider `if` statements; ignore ternary expr ` ? : `
                    and any(IfStmt i).getCondition() = checkCall.getParent*()
                    and hasSeparateBranches(conditionNode)
                    // Ignore if `else` branch explicitly calls other check method
                    // TODO: Yields some false positives when `else` branch calls `result.throwException()`
                    //       in a loop (because check calls in next iteration are erroneously considered successors)
                    and not exists(MethodAccess otherCheckCall |
                        otherCheckCall.getMethod() = codingMethod.getARequiredCheckMethod()
                        and DataFlow::localFlow(DataFlow::exprNode(coderResult), DataFlow::exprNode(otherCheckCall.getQualifier()))
                    |
                        conditionNode.getAFalseSuccessor().getASuccessor*() = otherCheckCall
                    )
                )
            )
            // TODO: Yields some false positives when only `isUnderflow()` check is performed and
            //       `false` branch throws exception
        )
        then none() // all check methods (implicitly) covered
        else result = getANotExplicitlyCheckedMethod(coderResult, codingMethod)
    )
}

/**
 * Gets a check method which is not called for the `codingCall` result. Ignores
 * check methods which are implicitly covered by branches of a condition node.
 */
private Method getANotCheckedMethod(MethodAccess codingCall) {
    exists(CodingOperationMethod codingMethod | codingMethod = codingCall.getMethod() |
        result = getANotCheckedMethod(codingCall, codingCall.getMethod())
        // Ignore if delegate handles result
        and not exists(MethodAccess delegateCall, Parameter delegateParam |
            delegateParam = delegateCall.getMethod().getAParameter()
            and DataFlow::localFlow(DataFlow::exprNode(codingCall), DataFlow::exprNode(delegateParam.getAnArgument()))
            and not exists(getANotCheckedMethod(delegateParam.getAnAccess(), codingMethod))
        )
        // Ignore if result is returned; caller will have to perform checks then
        and not exists(ReturnStmt returnStmt |
            DataFlow::localFlow(DataFlow::exprNode(codingCall), DataFlow::exprNode(returnStmt.getResult()))
        )
    )
}

/*
 * Note: Causes some false positives when `isMalformed()` and `isUnderflow()` are
 * checked instead of `isError()`, but correctly detecting that might not be worth it
 */

from MethodAccess codingCall, string notCheckedMethods
where
    notCheckedMethods = strictconcat(Method missing |
        missing = getANotCheckedMethod(codingCall)
    |
        missing.getName(), ", "
    )
select codingCall, "CoderResult is not properly checked; missing calls: " + notCheckedMethods

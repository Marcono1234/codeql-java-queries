/**
 * Finds calls to methods which repeat an object a specific amount of times
 * where the repetition count provided by the caller is pointless.
 * E.g.:
 * ```
 * // Results in empty String ""
 * "test".repeat(0);
 * // Should use Collections.singletonList("test")
 * Collections.nCopies(1, "test");
 * ```
 */

import java

class TypeCollections extends Class {
    TypeCollections() {
        hasQualifiedName("java.util", "Collections")
    }
}

abstract class RepeatingMethod extends Method {
    abstract int getRepeatParamIndex();
    abstract string getAlternativeForRepetitionCount(int repetitionCount);
}

class CollectionsNCopiesMethod extends RepeatingMethod {
    CollectionsNCopiesMethod() {
        getDeclaringType() instanceof TypeCollections
        and hasName("nCopies")
    }
    
    override
    int getRepeatParamIndex() {
        result = 0
    }
    
    override
    string getAlternativeForRepetitionCount(int repetitionCount) {
        repetitionCount = 0 and result = "Collections.emptyList()"
        or repetitionCount = 1 and result = "Collections.singletonList(...)"
    }
}

class StringRepeatMethod extends RepeatingMethod {
    StringRepeatMethod() {
        getDeclaringType() instanceof TypeString
        and hasStringSignature("repeat(int)")
    }
    
    override
    int getRepeatParamIndex() {
        result = 0
    }
    
    override
    string getAlternativeForRepetitionCount(int repetitionCount) {
        repetitionCount = 0 and result = "empty String \"\""
        or repetitionCount = 1 and result = "String itself"
    }
}

from MethodAccess repeatingCall, RepeatingMethod repeatingMethod, int repetitionCount, string alternative
where
    repeatingCall.getMethod().getSourceDeclaration().overridesOrInstantiates*(repeatingMethod)
    and repetitionCount = repeatingCall.getArgument(repeatingMethod.getRepeatParamIndex()).(CompileTimeConstantExpr).getIntValue()
    and alternative = repeatingMethod.getAlternativeForRepetitionCount(repetitionCount)
select repeatingCall, "Should instead use " + alternative

/**
 * Finds String method calls, with an empty string literal as argument,
 * which can be simplified or omitted.
 */

import java

abstract class StringMethodCall extends MethodAccess {
    StringMethodCall() {
        getMethod().getDeclaringType() instanceof TypeString
    }
    
    abstract int getAnArgCandidateIndex();
    abstract string getMessage();
}

class CompareToCall extends StringMethodCall {
    CompareToCall() {
        getMethod().hasStringSignature([
            "compareTo(String)",
            "compareToIgnoreCase(String)"
        ])
    }
    
    override int getAnArgCandidateIndex() {
        result = 0
    }
    
    override string getMessage() {
        result = "Alternative: isEmpty()"
    }
}

class ConcatCall extends StringMethodCall {
    ConcatCall() {
        getMethod().hasStringSignature("concat(String)")
    }
    
    override int getAnArgCandidateIndex() {
        result = 0
    }
    
    override string getMessage() {
        result = "Has no effect"
    }
}

class ContainsCall extends StringMethodCall {
    ContainsCall() {
        getMethod().hasStringSignature("contains(CharSequence)")
    }
    
    override int getAnArgCandidateIndex() {
        result = 0
    }
    
    override string getMessage() {
        result = "Always true"
    }
}

class ContentEqualsCall extends StringMethodCall {
    ContentEqualsCall() {
        getMethod().hasStringSignature("contentEquals(CharSequence)")
    }
    
    override int getAnArgCandidateIndex() {
        result = 0
    }
    
    override string getMessage() {
        result = "Alternative: isEmpty()"
    }
}

class PrefixSuffixCall extends StringMethodCall {
    PrefixSuffixCall() {
        getMethod().hasStringSignature([
            "endsWith(String)",
            "startsWith(String)",
            "startsWith(String, int)"
        ])
    }
    
    override int getAnArgCandidateIndex() {
        result = 0
    }
    
    override string getMessage() {
        result = "Always true"
    }
}

class EqualsCall extends StringMethodCall {
    EqualsCall() {
        getMethod().hasStringSignature([
            "equals(Object)",
            "equalsIgnoreCase(String)"
        ])
    }
    
    override int getAnArgCandidateIndex() {
        result = 0
    }
    
    override string getMessage() {
        result = "Alternative: isEmpty()"
    }
}

class IndexCall extends StringMethodCall {
    IndexCall() {
        getMethod().hasStringSignature([
            "indexOf(String)",
            "indexOf(String, int)",
            "lastIndexOf(String)",
            "lastIndexOf(String, int)"
        ])
    }
    
    override int getAnArgCandidateIndex() {
        result = 0
    }
    
    override string getMessage() {
        result = "Always returns first allowed index"
    }
}

class JoinCall extends StringMethodCall {
    JoinCall() {
        getMethod().hasStringSignature("join(CharSequence, CharSequence[])")
    }
    
    override int getAnArgCandidateIndex() {
        result = [1 .. getNumArgument() - 1]
    }
    
    override string getMessage() {
        result = "Has no effect"
    }
}

class MatchesCall extends StringMethodCall {
    MatchesCall() {
        getMethod().hasStringSignature("matches(String)")
    }
    
    override int getAnArgCandidateIndex() {
        result = 0
    }
    
    override string getMessage() {
        result = "Alternative: isEmpty()"
    }
}

class RegionMatchesCall extends StringMethodCall {
    RegionMatchesCall() {
        getMethod().hasName("regionMatches")
    }
    
    override int getAnArgCandidateIndex() {
        getMethod().getParameterType(result) instanceof TypeString
    }
    
    override string getMessage() {
        result = "? Alternative: isEmpty()"
    }
}

class ReplaceFirstCall extends StringMethodCall {
    ReplaceFirstCall() {
        getMethod().hasStringSignature("replaceFirst(String, String)")
    }
    
    override int getAnArgCandidateIndex() {
        result = 0
    }
    
    override string getMessage() {
        result = "Alternative: Concat replacement with string"
    }
}

class SplitCall extends StringMethodCall {
    SplitCall() {
        getMethod().hasStringSignature("split(String)")
    }
    
    override int getAnArgCandidateIndex() {
        result = 0
    }
    
    override string getMessage() {
        result = "Alternative: toCharArray()"
    }
}

class EmptyString extends StringLiteral {
    EmptyString() {
        getValue().length() = 0
    }
}

from StringMethodCall call
where
    call.getArgument(call.getAnArgCandidateIndex()) instanceof EmptyString
select call, call.getMessage()

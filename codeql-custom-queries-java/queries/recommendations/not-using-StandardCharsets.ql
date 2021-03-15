/**
 * Finds calls which are referencing a charset using a String literal instead
 * of using the respective `java.nio.charset.StandardCharsets` constant.
 *
 * SonarSource rule: https://rules.sonarsource.com/java/RSPEC-4719
 */

import java

abstract class CallWithCharsetOverload extends Call {
    abstract int charsetParamIndex();
    abstract Callable alternative();
}

class TypeCharset extends Class {
    TypeCharset() {
        hasQualifiedName("java.nio.charset", "Charset")
    }
}

/**
 * Determines whether the callable is an alternative, i.e. all parameters
 * except the charset parameter have the same type, and gets the index of
 * the charset parameter as result.
 */
private int isAlternative(Callable c, Callable alternative) {
    c.getParameterType(result) instanceof TypeString
    and alternative.getParameterType(result) instanceof TypeCharset
    // Check that all other parameter types are the same
    // But allow if alternative has additional parameters
    // Note: This does not cover callables where parameter use generic type parameters, however checking
    //             for that is complicated and probably only a small number of callables like these exist
    and forall(int paramIndex | paramIndex != result and paramIndex = [0 .. c.getNumberOfParameters() - 1] |
        c.getParameterType(paramIndex) = alternative.getParameterType(paramIndex)
    )
}

class MethodCallWithCharsetOverload extends CallWithCharsetOverload, MethodAccess {
    private int charsetParamIndex;
    private Method alternative;
    
    MethodCallWithCharsetOverload() {
        alternative.getDeclaringType() = getReceiverType().getASourceSupertype*()
        and exists(Method m | m = getMethod() |
            alternative.getName() = m.getName()
            and charsetParamIndex = isAlternative(m, alternative)
        )
    }
    
    override
    int charsetParamIndex() {
        result = charsetParamIndex
    }
    
    override
    Method alternative() {
        result = alternative
    }
}

class ConstructorCallWithCharsetOverload extends CallWithCharsetOverload, ClassInstanceExpr {
    private int charsetParamIndex;
    private Constructor alternative;
    
    ConstructorCallWithCharsetOverload() {
        alternative.getDeclaringType() = getConstructedType()
        and exists(Constructor c | c = getConstructor() |
            charsetParamIndex = isAlternative(c, alternative)
        )
    }
    
    override
    int charsetParamIndex() {
        result = charsetParamIndex
    }
    
    override
    Constructor alternative() {
        result = alternative
    }
}

class CharsetForNameCall extends MethodAccess {
    CharsetForNameCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType() instanceof TypeCharset
            and m.hasStringSignature("forName(String)")
        )
    }
}

bindingset[a, b]
private predicate matchesIgnoreCase(string a, string b) {
    a.toUpperCase() = b.toUpperCase()
}

bindingset[charsetName]
string getStandardCharsetName(string charsetName) {
    // Match charset names and their aliases case insensitively and get corresponding
    // StandardCharsets constant name
    (
        matchesIgnoreCase(charsetName, ["ISO-8859-1", "819", "ISO8859-1", "l1", "ISO_8859-1:1987", "ISO_8859-1", "8859_1", "iso-ir-100", "latin1", "cp819", "ISO8859_1", "IBM819", "ISO_8859_1", "IBM-819", "csISOLatin1"])
        and result = "ISO_8859_1"
    )
    or (
        matchesIgnoreCase(charsetName, ["US-ASCII", "ANSI_X3.4-1968", "cp367", "csASCII", "iso-ir-6", "ASCII", "iso_646.irv:1983", "ANSI_X3.4-1986", "ascii7", "default", "ISO_646.irv:1991", "ISO646-US", "IBM367", "646", "us"])
        and result = "US_ASCII"
    )
    or (
        matchesIgnoreCase(charsetName, ["UTF-16", "UTF_16", "unicode", "utf16", "UnicodeBig"])
        and result = "UTF_16"
    )
    or (
        matchesIgnoreCase(charsetName, ["UTF-16BE", "X-UTF-16BE", "UTF_16BE", "ISO-10646-UCS-2", "UnicodeBigUnmarked"])
        and result = "UTF_16BE"
    )
    or (
        matchesIgnoreCase(charsetName, ["UTF-16LE", "UnicodeLittleUnmarked", "UTF_16LE", "X-UTF-16LE"])
        and result = "UTF_16LE"
    )
    or (
        matchesIgnoreCase(charsetName, ["UTF-8", "unicode-1-1-utf-8", "UTF8"])
        and result = "UTF_8"
    )
}

from Expr charsetExpr, string alternative
where
    // Calling Charset.forName(...)
    alternative = "Use java.nio.charset.StandardCharsets." + getStandardCharsetName(charsetExpr.(CharsetForNameCall).getArgument(0).(CompileTimeConstantExpr).getStringValue())
    // Or using callable with alternative
    or exists(CallWithCharsetOverload call, string standardCharsetName |
        standardCharsetName = getStandardCharsetName(charsetExpr.(CompileTimeConstantExpr).getStringValue())
        and charsetExpr.getParent() = call
        and call.getArgument(call.charsetParamIndex()) = charsetExpr
        and alternative = "Use " + call.alternative().getStringSignature() + " with java.nio.charset.StandardCharsets." + standardCharsetName
    )
select charsetExpr, alternative

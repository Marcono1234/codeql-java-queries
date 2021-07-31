/**
 * Finds code which creates a `java.math.BigDecimal` from a `float` or `double` literal.
 * Floating point values are not precise so instead of creating a `BigDecimal` from a floating
 * point literal, it should be created from a String.
 * 
 * ```java
 * // Error-prone
 * new BigDecimal(1.1);
 * 
 * // Good
 * new BigDecimal("1.1");
 * ```
 * 
 * Based on:
 * - [Google I/O 2011: Java Puzzlers - Scraping the Bottom of the Barrel](https://youtu.be/wbp-3BJWsU8?t=246)
 * - [SonarSource rule RSPEC-2111: "BigDecimal(double)" should not be used](https://rules.sonarsource.com/java/RSPEC-2111)
 */

import java
import semmle.code.java.dataflow.SSA

// Only use SSA but not local data flow to avoid false positives when variable
// is assigned at multiple locations or is re-assigned
Expr getDirectAccessOrSsa(Expr source) {
    source = result
    or exists (SsaExplicitUpdate ssaVar |
        ssaVar.getDefiningExpr().(VariableAssign).getSource() = source
        and result = ssaVar.getAUse()
    )
}

class TypeBigDecimal extends Class {
    TypeBigDecimal() {
        hasQualifiedName("java.math", "BigDecimal")
    }
}

class BigDecimalFromDoubleCall extends Call {
    Expr doubleArg;
    
    BigDecimalFromDoubleCall() {
        exists(ConstructorCall call | call = this |
            call.getConstructedType() instanceof TypeBigDecimal
            and call.getConstructor().hasStringSignature([
                "BigDecimal(double)",
                "BigDecimal(double, MathContext)"
            ])
            and doubleArg = call.getArgument(0)
        )
        or exists(MethodAccess call, Method m | call = this and m = call.getMethod() |
            m.getDeclaringType() instanceof TypeBigDecimal
            /*
             * Note: The result of `valueOf(double)` is closer to the original double literal
             * in source code, but it can still be inaccurate in case the literal has more
             * decimal digits than a `double` supports
             */
            and m.hasStringSignature("valueOf(double)")
            and doubleArg = call.getArgument(0)
        )
    }
    
    Expr getDoubleArg() {
        result = doubleArg
    }
}

class FloatOrDoubleLiteral extends Literal {
    FloatOrDoubleLiteral() {
        this instanceof FloatingPointLiteral
        or this instanceof DoubleLiteral
    }
}

from BigDecimalFromDoubleCall bigDecimalCall, FloatOrDoubleLiteral literal
where
    // Only consider cases where only literals are used, ignore if floating point
    // value might (conditionally) come from a variable
    bigDecimalCall.getDoubleArg() = getDirectAccessOrSsa(literal)
select bigDecimalCall, "Uses $@ floating point literal to construct BigDecimal", literal, "this"

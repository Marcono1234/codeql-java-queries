/**
 * Finds code which calculates the difference between two `java.time.Instant` values, but
 * does not use [`Duration.between(...)`](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/time/Duration.html#between(java.time.temporal.Temporal,java.time.temporal.Temporal))
 * for this. Usage of `Duration.between(...)` can make the code easier to understand. E.g.:
 * ```java
 * Instant creationTime = ...;
 * // Should instead use: Duration.between(creationTime, Instant.now()).toDays() > 1
 * boolean isOld = creationTime.plus(1, ChronoUnit.DAYS).isBefore(Instant.now());
 * ```
 */

import java

class TypeInstant extends Class {
    TypeInstant() {
        hasQualifiedName("java.time", "Instant")
    }
}

class GetEpochValueCall extends MethodAccess {
    GetEpochValueCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType() instanceof TypeInstant
            and m.hasNoParameters()
            and m.hasName([
                "getEpochSecond",
                "toEpochMilli"
            ])
        )
    }
}

class PlusOrMinusCall extends MethodAccess {
    PlusOrMinusCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType() instanceof TypeInstant
            and m.hasName([
                "minus",
                "minusMillis",
                "minusNanos",
                "minusSeconds",
                "plus",
                "plusMillis",
                "plusNanos",
                "plusSeconds"
            ])
        )
    }
}

class ComparingCall extends MethodAccess {
    ComparingCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType() instanceof TypeInstant
            and m.hasName([
                "isAfter",
                "isBefore",
                "compareTo"
            ])
        )
    }
}

from Expr diffExpr
where
    exists(SubExpr subDiffExpr | diffExpr = subDiffExpr |
        subDiffExpr.getLeftOperand() instanceof GetEpochValueCall
        and subDiffExpr.getRightOperand() instanceof GetEpochValueCall
    )
    or exists(PlusOrMinusCall plusOrMinusCall, ComparingCall comparingCall | diffExpr = comparingCall |
        plusOrMinusCall = comparingCall.getQualifier()
    )
select diffExpr, "Should use Duration.between(...)"

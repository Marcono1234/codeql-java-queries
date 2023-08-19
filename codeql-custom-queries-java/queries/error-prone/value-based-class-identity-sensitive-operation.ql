/**
 * Finds identity-sensitive operations on [value-based classes](https://docs.oracle.com/en/java/javase/15/docs/api/java.base/java/lang/doc-files/ValueBased.html).
 * Identity-sensitive operations, such as reference equality checks (`==`, `!=`)
 * or synchronization, may lead to unpredictable results because value-based classes
 * must only be compared using `equals(Object)` and `hashCode()`.
 *
 * See also https://bugs.openjdk.java.net/browse/JDK-8249100
 * 
 * @kind problem
 */

import java
import semmle.code.java.dataflow.DataFlow

abstract class ValueBasedClass extends RefType {
}

/**
 * Class which is value-based according to its documentation.
 */
class DocumentedValueBasedClass extends ValueBasedClass {
    // Based on JDK 15
    DocumentedValueBasedClass() {
        this instanceof BoxedType
        or getASourceSupertype*().hasQualifiedName("java.lang", ["ProcessHandle", "Runtime$Version"])
        or getASourceSupertype*().hasQualifiedName("java.lang.constant", ["ConstantDesc", "DynamicCallSiteDesc"])
        or getASourceSupertype*().hasQualifiedName("java.util", ["Optional", "OptionalDouble", "OptionalInt", "OptionalLong", "HexFormat"])
        or getASourceSupertype*().hasQualifiedName("java.time", ["Duration", "Instant", "LocalDate", "LocalDateTime", "LocalTime", "MonthDay", "OffsetDateTime", "OffsetTime", "Period", "Year", "YearMonth", "ZoneId", "ZonedDateTime", "ZoneOffset"])
        or getASourceSupertype*().hasQualifiedName("java.time.chrono", ["HijrahDate", "JapaneseDate", "MinguoDate", "ThaiBuddhistDate"])
    }
}

/**
 * Class annotated with an anntation (added in JDK 16) indicating that the class
 * is value-based.
 */
class AnnotatedValueBasedClass extends ValueBasedClass {
    AnnotatedValueBasedClass() {
        hasAnnotation("jdk.internal", "ValueBased")
    }
}

/**
 * Method which may return a value-based result.
 */
abstract class ValueBasedReturningMethod extends Method {
}

class ImmutableCollectionFactoryMethod extends ValueBasedReturningMethod {
    // Based on JDK 15
    ImmutableCollectionFactoryMethod() {
        getDeclaringType().hasQualifiedName("java.util", ["Set", "List", "Map"])
        and isStatic()
        and hasName(["of", "ofEntries", "copyOf"])
    }
}

class MapEntryFactoryMethod extends ValueBasedReturningMethod {
    // Based on JDK 15
    MapEntryFactoryMethod() {
        getDeclaringType().hasQualifiedName("java.util", "Map")
        and isStatic()
        and hasName("entry")
    }
}

class StreamCollectionMethod extends ValueBasedReturningMethod {
    StreamCollectionMethod() {
        getDeclaringType().getASourceSupertype*().hasQualifiedName("java.util.stream", "Stream")
        and hasStringSignature("toList()")
    }
}

class IdentityHashCodeCall extends MethodAccess {
    IdentityHashCodeCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType() instanceof TypeSystem
            and m.hasStringSignature("identityHashCode(Object)")
        )
    }
}

/**
 * Expression which occurs at a location where a value-based class must not be used.
 */
class ValueBasedForbiddenExpr extends Expr {
    ValueBasedForbiddenExpr() {
        exists(SynchronizedStmt sync |
            sync.getExpr() = this
        )
        or exists(EqualityTest eqTest |
            eqTest.getAnOperand() = this
            // Not a null check
            and not eqTest.getAnOperand() instanceof NullLiteral
            // Not unboxing a boxed type
            and not eqTest.getAnOperand().getType() instanceof PrimitiveType
        )
        or exists(IdentityHashCodeCall hashCodeCall |
            hashCodeCall.getArgument(0) = this
        )
        or exists(TypeAccess identityHashMapType |
            identityHashMapType.getType().(RefType).getSourceDeclaration().hasQualifiedName("java.util", "IdentityHashMap")
            // `this` is the key type of the map, on which reference equality checks are performed
            and this = identityHashMapType.getTypeArgument(0)
        )
    }
}

from ValueBasedForbiddenExpr forbiddenExpr
where
    forbiddenExpr.getType() instanceof ValueBasedClass
    or exists(MethodAccess valueBasedReturningCall |
        valueBasedReturningCall.getMethod() instanceof ValueBasedReturningMethod
        and DataFlow::localFlow(DataFlow::exprNode(valueBasedReturningCall), DataFlow::exprNode(forbiddenExpr))
    )
select forbiddenExpr, "Performs identity-sensitive operation on value-based class"

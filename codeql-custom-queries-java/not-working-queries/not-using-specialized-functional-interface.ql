import java
import lib.Nullness

abstract class FunctionalTypeAccess extends TypeAccess {
    FunctionalTypeAccess() {
        getType().(RefType).getPackage().hasName("java.util.function")
    }
    
    bindingset[index]
    string getBoxedTypeArgName(int index) {
        exists (TypeAccess typeArg | typeArg = getTypeArgument(index) |
            result = typeArg.getType().(BoxedType).getName()
            // Make sure that type has no annotations (except NonNull)
            // This also covers not having Nullable annotation
            and not exists (Annotation annotation | annotation = typeArg.getAnAnnotation() |
                not annotation instanceof NonNullAnnotation
            )
        )
        // In case type argument is not boxed or has annotations
        // Set a result so checks which assign all type arguments to QL variables
        // can still match partially
        or result = "-"
    }
    
    RefType getTypeArg(int index) {
        result = getTypeArgument(index).getType()
    }
    
    predicate areTypeArgsEquivalent(int indexA, int indexB) {
        exists (Expr a, Expr b | a = getTypeArgument(indexA) and b = getTypeArgument(indexB) |
            a.getType() = b.getType()
            and a.getKind() = b.getKind()
            // TODO: Maybe also check annotations
        )
    }
    
    abstract string getAlternative(boolean sameInterface);
}

private predicate hasName_(TypeAccess typeAccess, string name) {
    typeAccess.getType().getErasure().(RefType).hasName(name)
}

class BoxedVoid extends Class {
    BoxedVoid() {
        hasQualifiedName("java.lang", "Void")
    }
}

class BiConsumer extends FunctionalTypeAccess {
    BiConsumer() {
        hasName_(this, "BiConsumer")
    }
    
    override string getAlternative(boolean sameInterface) {
        sameInterface = false
        and exists (string tOrU | tOrU = getBoxedTypeArgName([0, 1]) |
            tOrU = "Double" and result = "ObjDoubleConsumer"
            or tOrU = "Integer" and result = "ObjIntConsumer"
            or tOrU = "Long" and result = "ObjLongConsumer"
        )
    }
}

class BiFunction extends FunctionalTypeAccess {
    BiFunction() {
        hasName_(this, "BiFunction")
    }
    
    override string getAlternative(boolean sameInterface) {
        (
            sameInterface = false
            and getTypeArg(2) instanceof BoxedVoid
            and result = "BiConsumer"
        )
        or (
            sameInterface = false
            and getBoxedTypeArgName(2) = "Boolean"
            and result = "BiPredicate"
        )
        or (
            sameInterface = true
            and areTypeArgsEquivalent(0, 1)
            and areTypeArgsEquivalent(1, 2)
            and result = "BinaryOperator"
        )
        or sameInterface = false
        and exists (string t, string u, string r |
            t = getBoxedTypeArgName(0)
            and u = getBoxedTypeArgName(1)
            and r = getBoxedTypeArgName(2)
        |
            (
                t = "Double" and u = "Double" and r = "Double"
                and result = "DoubleBinaryOperator"
            )
            or (
                t = "Integer" and u = "Integer" and r = "Integer"
                and result = "IntBinaryOperator"
            )
            or (
                t = "Long" and u = "Long" and r = "Long"
                and result = "LongBinaryOperator"
            )
            or (
                r = "Double" and result = "ToDoubleBiFunction"
                or r = "Integer" and result = "ToIntBiFunction"
                or r = "Long" and result = "ToLongBiFunction"
            )
        )
    }
}

class BinaryOperator extends FunctionalTypeAccess {
    BinaryOperator() {
        hasName_(this, "BinaryOperator")
    }
    
    override string getAlternative(boolean sameInterface) {
        (
            sameInterface = false
            and getTypeArg(0) instanceof BoxedVoid
            and result = "Runnable"
        )
        or (
            sameInterface = false
            and getBoxedTypeArgName(0) = "Boolean"
            and result = "BiPredicate" // At least the return type will not require boxing then
        )
        or sameInterface = false
        and exists (string t | t = getBoxedTypeArgName(0) |
            t = "Double" and result = "DoubleBinaryOperator"
            or t = "Integer" and result = "IntegerBinaryOperator"
            or t = "Long" and result = "LongBinaryOperator"
        )
    }
}

class BiPredicate extends FunctionalTypeAccess {
    BiPredicate() {
        hasName_(this, "BiPredicate")
    }
    
    override string getAlternative(boolean sameInterface) {
        none() // No alternative
    }
}

class Consumer extends FunctionalTypeAccess {
    Consumer() {
        hasName_(this, "Consumer")
    }
    
    override string getAlternative(boolean sameInterface) {
        (
            sameInterface = false
            and getTypeArg(0) instanceof BoxedVoid
            and result = "Runnable"
        )
        or sameInterface = false
        and exists (string t | t = getBoxedTypeArgName(0) |
            t = "Double" and result = "DoubleConsumer"
            or t = "Integer" and result = "IntConsumer"
            or t = "Long" and result = "LongConsumer"
        )
    }
}

class DoubleFunction extends FunctionalTypeAccess {
    DoubleFunction() {
        hasName_(this, "DoubleFunction")
    }
    
    override string getAlternative(boolean sameInterface) {
        (
            sameInterface = false
            and getTypeArg(0) instanceof BoxedVoid
            and result = "DoubleConsumer"
        )
        or (
            sameInterface = false
            and getBoxedTypeArgName(0) = "Boolean"
            and result = "DoublePredicate"
        )
        or sameInterface = false
        and exists (string t | t = getBoxedTypeArgName(0) |
            t = "Double" and result = "DoubleUnaryOperator"
            or t = "Integer" and result = "DoubleToIntFunction"
            or t = "Long" and result = "DoubleToLongFunction"
        )
    }
}

class Function extends FunctionalTypeAccess {
    Function() {
        hasName_(this, "Function")
    }
    
    override string getAlternative(boolean sameInterface) {
        (
            sameInterface = false
            and getTypeArg(1) instanceof BoxedVoid
            and result = "Consumer"
        )
        or (
            sameInterface = false
            and getBoxedTypeArgName(1) = "Boolean"
            and result = "Predicate"
        )
        or (
            sameInterface = true
            and areTypeArgsEquivalent(0, 1)
            and result = "UnaryOperator"
        )
        or sameInterface = false
        and exists (string t, string r | t = getBoxedTypeArgName(0) and r = getBoxedTypeArgName(1) |
            t = "Double" and (
                if r = "Double" then result = "DoubleUnaryOperator"
                else if r = "Integer" then result = "DoubleToIntFunction"
                else if r = "Long" then result = "DoubleToLongFunction"
                else if r = "Boolean" then result = "DoublePredicate"
                else result = "DoubleFunction"
            )
            or r = "Double" and result = "ToDoubleFunction"
            or t = "Integer" and (
                if r = "Double" then result = "IntToDoubleFunction"
                else if r = "Integer" then result = "IntUnaryOperator"
                else if r = "Long" then result = "IntToLongFunction"
                else if r = "Boolean" then result = "IntPredicate"
                else result = "IntFunction"
            )
            or r = "Integer" and result = "ToIntFunction"
            or t = "Long" and (
                if r = "Double" then result = "LongToDoubleFunction"
                else if r = "Integer" then result = "LongToIntFunction"
                else if r = "Long" then result = "LongUnaryOperator"
                else if r = "Boolean" then result = "LongPredicate"
                else result = "LongFunction"
            )
            or r = "Long" and result = "ToLongFunction"
        )
    }
}

class IntFunction extends FunctionalTypeAccess {
    IntFunction() {
        hasName_(this, "IntFunction")
    }
    
    override string getAlternative(boolean sameInterface) {
        (
            sameInterface = false
            and getTypeArg(0) instanceof BoxedVoid
            and result = "IntConsumer"
        )
        or (
            sameInterface = false
            and getBoxedTypeArgName(0) = "Boolean"
            and result = "IntPredicate"
        )
        or sameInterface = false
        and exists (string t | t = getBoxedTypeArgName(0) |
            t = "Double" and result = "IntToDoubleFunction"
            or t = "Integer" and result = "IntUnaryOperator"
            or t = "Long" and result = "IntToLongFunction"
        )
    }
}

class LongFunction extends FunctionalTypeAccess {
    LongFunction() {
        hasName_(this, "LongFunction")
    }
    
    override string getAlternative(boolean sameInterface) {
        (
            sameInterface = false
            and getTypeArg(0) instanceof BoxedVoid
            and result = "LongConsumer"
        )
        or (
            sameInterface = false
            and getBoxedTypeArgName(0) = "Boolean"
            and result = "LongPredicate"
        )
        or sameInterface = false
        and exists (string t | t = getBoxedTypeArgName(0) |
            t = "Double" and result = "LongToDoubleFunction"
            or t = "Integer" and result = "LongToIntFunction"
            or t = "Long" and result = "LongUnaryOperator"
        )
    }
}

class ObjDoubleConsumer extends FunctionalTypeAccess {
    ObjDoubleConsumer() {
        hasName_(this, "ObjDoubleConsumer")
    }
    
    override string getAlternative(boolean sameInterface) {
        none() // No alternative
    }
}

class ObjIntConsumer extends FunctionalTypeAccess {
    ObjIntConsumer() {
        hasName_(this, "ObjIntConsumer")
    }
    
    override string getAlternative(boolean sameInterface) {
        none() // No alternative
    }
}

class ObjLongConsumer extends FunctionalTypeAccess {
    ObjLongConsumer() {
        hasName_(this, "ObjLongConsumer")
    }
    
    override string getAlternative(boolean sameInterface) {
        none() // No alternative
    }
}

class Predicate extends FunctionalTypeAccess {
    Predicate() {
        hasName_(this, "Predicate")
    }
    
    override string getAlternative(boolean sameInterface) {
        sameInterface = false
        and exists (string t | t = getBoxedTypeArgName(0) |
            t = "Double" and result = "DoublePredicate"
            or t = "Integer" and result = "IntPredicate"
            or t = "Long" and result = "LongPredicate"
        )
    }
}

class Supplier extends FunctionalTypeAccess {
    Supplier() {
        hasName_(this, "Supplier")
    }
    
    override string getAlternative(boolean sameInterface) {
        (
            sameInterface = false
            and getTypeArg(0) instanceof BoxedVoid
            and result = "Runnable"
        )
        or sameInterface = false
        and exists (string t | t = getBoxedTypeArgName(0) |
            t = "Double" and result = "DoubleSupplier"
            or t = "Integer" and result = "IntSupplier"
            or t = "Long" and result = "LongSupplier"
        )
    }
}

class ToDoubleBiFunction extends FunctionalTypeAccess {
    ToDoubleBiFunction() {
        hasName_(this, "ToDoubleBiFunction")
    }
    
    override string getAlternative(boolean sameInterface) {
        sameInterface = false
        and exists (string t, string u | t = getBoxedTypeArgName(0) and u = getBoxedTypeArgName(1) |
            t = "Double" and u = "Double" and result = "DoubleBinaryOperator"
        )
    }
}

class ToDoubleFunction extends FunctionalTypeAccess {
    ToDoubleFunction() {
        hasName_(this, "ToDoubleFunction")
    }
    
    override string getAlternative(boolean sameInterface) {
        (
            sameInterface = false
            and getTypeArg(0) instanceof BoxedVoid
            and result = "DoubleSupplier"
        )
        or sameInterface = false
        and exists (string t | t = getBoxedTypeArgName(0) |
            t = "Integer" and result = "IntToDoubleFunction"
            or t = "Long" and result = "LongToDoubleFunction"
        )
    }
}

class ToIntBiFunction extends FunctionalTypeAccess {
    ToIntBiFunction() {
        hasName_(this, "ToIntBiFunction")
    }
    
    override string getAlternative(boolean sameInterface) {
        sameInterface = false
        and exists (string t, string u | t = getBoxedTypeArgName(0) and u = getBoxedTypeArgName(1) |
            t = "Integer" and u = "Integer" and result = "IntBinaryOperator"
        )
    }
}

class ToIntFunction extends FunctionalTypeAccess {
    ToIntFunction() {
        hasName_(this, "ToIntFunction")
    }
    
    override string getAlternative(boolean sameInterface) {
        (
            sameInterface = false
            and getTypeArg(0) instanceof BoxedVoid
            and result = "IntSupplier"
        )
        or sameInterface = false
        and exists (string t | t = getBoxedTypeArgName(0) |
            t = "Double" and result = "DoubleToIntFunction"
            or t = "Long" and result = "LongToIntFunction"
        )
    }
}

class ToLongBiFunction extends FunctionalTypeAccess {
    ToLongBiFunction() {
        hasName_(this, "ToLongBiFunction")
    }
    
    override string getAlternative(boolean sameInterface) {
        sameInterface = false
        and exists (string t, string u | t = getBoxedTypeArgName(0) and u = getBoxedTypeArgName(1) |
            t = "Long" and u = "Long" and result = "LongBinaryOperator"
        )
    }
}

class ToLongFunction extends FunctionalTypeAccess {
    ToLongFunction() {
        hasName_(this, "ToLongFunction")
    }
    
    override string getAlternative(boolean sameInterface) {
        (
            sameInterface = false
            and getTypeArg(0) instanceof BoxedVoid
            and result = "LongSupplier"
        )
        or sameInterface = false
        and exists (string t | t = getBoxedTypeArgName(0) |
            t = "Double" and result = "DoubleToLongFunction"
            or t = "Integer" and result = "IntToLongFunction"
        )
    }
}

class UnaryOperator extends FunctionalTypeAccess {
    UnaryOperator() {
        hasName_(this, "UnaryOperator")
    }
    
    override string getAlternative(boolean sameInterface) {
        sameInterface = false
        and exists (string t | t = getBoxedTypeArgName(0) |
            t = "Double" and result = "DoubleUnaryOperator"
            or t = "Integer" and result = "IntUnaryOperator"
            or t = "Long" and result = "LongUnaryOperator"
            or t = "Boolean" and result = "Predicate" // At least the return type will not require boxing then
        )
    }
}

from FunctionalTypeAccess functionTypeAccess, ExprParent parent, string alternative
where
    parent = functionTypeAccess.getParent()
    // QL considers functional expressions and ArrayInit to be TypeAccess, ignore them
    and not parent instanceof FunctionalExpr
    and not parent instanceof ArrayInit
    /*
     * TODO: Reduce false positives; in some cases type cannot be changed, e.g.
     * if it occurs as parameter or return type (if return type of overridden method is less specific)
     * of overridden method, or if variable or field of that type is retrieved from method,
     * or if it is used as argument
     *
     * Relevant `parent`s might be:
     * - RefType / SrcRefType: If type access appears in `extends` or `implements` clause
     * - Method: If type access appears in return type or throws clause
     * - LocalVariableDeclStmt: Variable type
     * - ClassInstanceExpr: Anonymous class implementing interface?
     * - FieldDeclaration: Field type
     * - Parameter: Parameter type
     * - ArrayCreationExpr: Element type
     * Check recursively:
     * - TypeAccess: If type access is generic type argument
     * - WildcardTypeAccess: Bound of wildcard
     * - ArrayTypeAccess: Element type
     */
    and alternative = functionTypeAccess.getAlternative(_)
select functionTypeAccess, alternative

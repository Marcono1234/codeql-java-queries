/**
 * Finds local variables and fields which are assigned always the same value, at different
 * locations in the code. This might indicate a bug, where one of the assignments should
 * instead assign a different value.
 * 
 * For example:
 * ```java
 * class List<E> {
 *     private boolean hasChanged = false;
 * 
 *     public void add(E e) {
 *         ...
 * 
 *         // Bug; should assign value `true`
 *         hasChanged = false;
 *     }
 * }
 * ```
 */

import java
import semmle.code.java.Reflection

import lib.Literals

class IntegralLiteral extends Literal {
    IntegralLiteral() {
        this instanceof IntegerLiteral
        or this instanceof LongLiteral
    }
}

predicate isSameValue(Expr e1, Expr e2) {
    e1 instanceof NullLiteral and e2 instanceof NullLiteral
    or e1.(TypeLiteral).getReferencedType() = e2.(TypeLiteral).getReferencedType()
    or exists(CompileTimeConstantExpr c1, CompileTimeConstantExpr c2 | c1 = e1 and c2 = e2 |
        c1.getBooleanValue() = c2.getBooleanValue()
        or c1.getIntValue() = c2.getIntValue()
        or c1.getStringValue() = c2.getStringValue()
        or c1.getType() = c2.getType() and c1.(Literal).getValue() = c2.(Literal).getValue()
        // Consider widening conversion for types whose value cannot be obtained from CompileTimeConstantExpr
        or c1.(IntegralLiteral).getValue() = c2.(IntegralLiteral).getValue()
        or c1.(FloatingPointLiteral_).getValue() = c2.(FloatingPointLiteral_).getValue()
        or c1.(FloatingPointLiteral_).getValue().toFloat() = c2.(IntegralLiteral).getValue().toInt()
        or c1.(IntegralLiteral).getValue().toInt() = c2.(FloatingPointLiteral_).getValue().toFloat()
    )
}

predicate isAssigningSameValue(LValue write, Expr valueExpr) {
    exists(AssignExpr a |
        a.getDest() = write
        and isSameValue(a.getRhs(), valueExpr)
    )
}

predicate hasLocalVarSameValueAssigns(LocalVariableDecl v) {
    exists(LocalVariableDeclExpr declExpr, VariableAssign assign, Expr assignedValue |
        (
            // Only consider local variables without implicit value; ignore for example
            // variables from enhanced `for` loop
            any(LocalVariableDeclStmt s).getAVariable() = declExpr
            or any(ForStmt s).getAnInit() = declExpr
        )
        and declExpr.getVariable() = v
        and assign.getDestVar() = v
        and assignedValue = assign.getSource()
        // If init exists, require that assign is declExpr; otherwise code below which checks
        // for LValue would not match LocalVariableDeclExpr init
        and (exists(declExpr.getInit()) implies assign = declExpr)
    |
        // Use forex to make sure there is at least one other assign
        // Use LValue and then restrict in isAssigningSameValue to AssignExpr to ignore
        // variable if there are other variable updates, such as compound assigns
        forex(LValue write |
            write.getVariable() = v
            // Don't match the original assign
            and not write = assign.(AssignExpr).getDest()
        |
            isAssigningSameValue(write, assignedValue)
        )
    )
}

predicate isInitializedBy(Field f, Constructor c) {
    // Either assigns field value
    // Note: This is inaccurate because it does not consider whether a field read occurs
    // before, but verifying this is difficult because read might occur in instance methods
    // which are called by the constructor
    exists(FieldAccess fieldAccess, AssignExpr assign |
        assign.getDest() = fieldAccess
        and fieldAccess.getField() = f
        and fieldAccess.isOwnFieldAccess()
        and assign.getEnclosingCallable() = c
        // To reduce false positives require that assignment is in same block
        and assign.getEnclosingStmt().getEnclosingStmt() = c.getBody()
    )
    // Or delegates to other constructor which initializes field
    or exists(ConstructorCall delegateCall |
        delegateCall.getConstructor().getDeclaringType() = c.getDeclaringType()
        and delegateCall.getEnclosingCallable() = c
    )
}

predicate isInitialized(Field f) {
    exists(f.getInitializer())
    // Or is final; then it must be initialized
    or f.isFinal()
    // Or all constructors initialize field
    or forall(Constructor c |
        c.getDeclaringType() = f.getDeclaringType()
    |
        isInitializedBy(f, c)
    )
}

private predicate areSameFieldWrites(FieldWrite a, FieldWrite b) {
    a.getEnclosingCallable().getDeclaringType().getQualifiedName() = b.getEnclosingCallable().getDeclaringType().getQualifiedName()
    and exists(Location locA, Location locB |
        locA = a.getLocation()
        and locB = b.getLocation()
    |
        locA.getStartLine() = locB.getStartLine()
        and locA.getEndLine() = locB.getEndLine()
        and locA.getStartColumn() = locB.getStartColumn()
        and locA.getEndColumn() = locB.getEndColumn()
    )
}

predicate isUsedByVarHandle(Field f) {
    exists(MethodAccess lookupCall, Method lookupMethod |
        lookupCall.getMethod() = lookupMethod
        and lookupMethod.getDeclaringType().hasQualifiedName("java.lang.invoke", "MethodHandles$Lookup")
        and lookupMethod.hasName(["findVarHandle", "staticFieldVarHandle"])
        and lookupCall.getArgument(0).(TypeLiteral).getReferencedType().(RefType).getSourceDeclaration() = f.getDeclaringType()
        and lookupCall.getArgument(1).(CompileTimeConstantExpr).getStringValue() = f.getName()
    )
}

predicate isUsedByReflection(Field f) {
    any(ReflectiveFieldAccess a).inferAccessedField() = f
    // Or accessed field cannot be inferred, but lookup of field with same name happens in class
    // declaring the field (e.g. when `Class<?>` is used for the field lookup, such as in Guava's Striped64)
    or exists(MethodAccess lookupCall, Method lookupMethod |
        lookupCall.getMethod().getSourceDeclaration() = lookupMethod
        and lookupCall.getQualifier().(TypeLiteral).getReferencedType().(RefType).getSourceDeclaration().getASourceSupertype*() = f.getDeclaringType()
        and lookupMethod.hasName(["getDeclaredField", "getField"])
        and lookupCall.getArgument(0).(CompileTimeConstantExpr).getStringValue() = f.getName()
        and lookupCall.getEnclosingCallable().getDeclaringType() = f.getDeclaringType()
    )
}

predicate isUsedByUnsafe(Field f) {
    exists(MethodAccess unsafeCall, Method unsafeMethod |
        unsafeCall.getMethod() = unsafeMethod
        and unsafeMethod.getDeclaringType().hasQualifiedName("jdk.internal.misc", "Unsafe")
        and unsafeMethod.hasName("objectFieldOffset")
        and unsafeCall.getArgument(0).(TypeLiteral).getReferencedType().(RefType).getSourceDeclaration() = f.getDeclaringType()
        and unsafeCall.getArgument(1).(CompileTimeConstantExpr).getStringValue() = f.getName()
    )
}

// TODO: Seems to have some false positives, possibly caused by https://github.com/github/codeql/issues/5734
//             when constant is only assigned once, but in two different versions of the same class
predicate hasFieldSameValueAssigns(Field f) {
    f.fromSource()
    // Only consider private and package private fields; otherwise they might be
    // assigned externally
    and (f.isPrivate() or f.isPackageProtected())
    // If field is initialized can simply check all assignments
    and (
        if isInitialized(f) then exists(AssignExpr assign, Expr assignedValue |
            assign.getDest() = f.getAnAccess()
            and assignedValue = assign.getRhs()
        |
            // Use forex to make sure there is at least one other assign
            // Use FieldWrite and then restrict in isAssigningSameValue to AssignExpr to ignore
            // field if there are other field updates, such as compound assigns
            forex(FieldWrite write |
                write.getField() = f
                // Don't match the original assign
                and not write = assign.getDest()
                // Prevent false positives for multi-module projects, see https://github.com/github/codeql/issues/5734
                and not areSameFieldWrites(write, assign.getDest())
            |
                isAssigningSameValue(write, assignedValue)
            )
        )
        // Otherwise consider default field value
        // Using Literal here is a bit brittle because Literal must exist at another
        // place in source, but that should normally be the case
        else exists(Literal defaultValue |
            f.getType().hasName("boolean") and defaultValue.(BooleanLiteral).getBooleanValue() = false
            // Match any numeric primitive to account for conversion at assignment
            // TODO: Might be rather inefficient
            or f.getType().(PrimitiveType) instanceof NumericOrCharType and (
                defaultValue.(CharacterLiteral).getCodePointValue() = 0
                or defaultValue.(IntegerLiteral).getIntValue() = 0
                or defaultValue.(LongLiteral).getValue() = "0"
                or defaultValue.(FloatLiteral).getFloatValue() = 0
                or defaultValue.(DoubleLiteral).getDoubleValue() = 0
            )
            or f.getType() instanceof RefType and defaultValue instanceof NullLiteral
        |
            forex(FieldWrite write |
                write.getField() = f
            |
                isAssigningSameValue(write, defaultValue)
            )
        )
    )
    // Ignore if field is annotated with RUNTIME annotation; then it might be set
    // using reflection
    and not exists(Annotation retentionAnnotation |
        retentionAnnotation = f.getAnAnnotation().getType().getAnAnnotation()
        and retentionAnnotation.getType().hasQualifiedName("java.lang.annotation", "Retention")
        and retentionAnnotation.getValue("value").(FieldRead).getField().hasName("RUNTIME")
    )
    // Ignore if VarHandle or reflection is used to access field
    and not isUsedByVarHandle(f)
    and not isUsedByReflection(f)
    and not isUsedByUnsafe(f)
}

from Variable var
where
    hasLocalVarSameValueAssigns(var)
    or hasFieldSameValueAssigns(var)
select var, "Variable is always assigned the same value"

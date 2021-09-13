/**
 * Finds fields which are only used by a single method or instance fields
 * which are only used in the constructor. Such fields should be converted
 * to local variables to increase readability of the code.
 */

import java

// TODO: Apparently there is currently no easy way to determine this,
// see also https://github.com/github/codeql/issues/5732
predicate isInExplicitInitializer(Expr e) {
    // Implicit BlockStmt of method body and explicit BlockStmt of initializer
    // Note that this modeling is an implementation detail of CodeQL
    count(BlockStmt block | block = e.getAnEnclosingStmt()) >= 2
}

Top getReportedUsageLocation(Expr e) {
    // InitializerMethod is at the location of the class signature which is not
    // very helpful, instead get the BlockStmt containing the expression
    if e.getEnclosingCallable() instanceof InitializerMethod
    then exists(InitializerMethod init |
        result.(BlockStmt) = e.getAnEnclosingStmt()
        and result = init.getBody().getAChild()
    )
    else result = e.getEnclosingCallable()
}

from Field f, FieldAccess fieldRead, Callable callable, Top reportedUsageLocation
where
    // Field cannot be accessed from outside
    (f.isPrivate() or f.isPackageProtected())
    // Only consider FieldRead here since FieldWrite also occurs at initialization
    // (possibly in initializer block) and which on its own is not relevant
    and fieldRead = f.getAnAccess()
    and callable = fieldRead.getEnclosingCallable()
    and reportedUsageLocation = getReportedUsageLocation(fieldRead)
    // When inside initializer method require that an explicit initializer block is used
    // since it is easy to switch to local variables; ignore if directly part of initializer
    // of field
    and (callable instanceof InitializerMethod implies isInExplicitInitializer(fieldRead))
    // All access only occurs from one callable
    // Cannot consider multiple callables because then it would be necessary to analyze
    // control flow, making sure the callables are not calling each other
    and forall(FieldAccess access, Callable enclosingCallable | 
        access = f.getAnAccess()
        and enclosingCallable = access.getEnclosingCallable()
    |
        // For non-static fields access must occur on own field, otherwise field can possibly
        // not be converted to local variable
        (not f.isStatic() implies access.isOwnFieldAccess())
        and (
            // Ignore initializer methods and constructors since their initialization logic of field can
            // probably be moved to local variable
            if f.isStatic() then f.getDeclaringType() = enclosingCallable.(StaticInitializer).getDeclaringType()
            else (
                enclosingCallable instanceof InitializerMethod
                or enclosingCallable instanceof Constructor
            )
            or
            enclosingCallable = callable
        )
    )
    // For all read access, field value is overwritten before
    // Use `forex` to make sure there is readAccess; this prevents detecting unused fields
    // (should be detected by separate query) and fields which are only read using reflection
    and forex(FieldRead readAccess | readAccess.getEnclosingCallable() = callable |
        // Only consider AssignExpr since Assignment or FieldWrite would also match compound assignments
        // which additionally read the field
        exists(AssignExpr assign |
            assign.getDest() = f.getAnAccess()
        |
            strictlyDominates(assign.getControlFlowNode(), readAccess.getControlFlowNode())
        )
    )
select f, "This field could be converted to a local variable because it is only used $@", reportedUsageLocation, "here"

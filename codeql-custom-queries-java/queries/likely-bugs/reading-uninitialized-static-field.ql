/**
 * Finds access on static fields which occurs before the field is initialized.
 * This is most likely unintended.
 */

// In some situations this could overlap with CodeQL's java/unassigned-field

// TODO: Merge with likely-bugs/reading-uninitialized-field.ql

/*
 * TODO: Maybe combine with field-read-before-assignment.ql
 *  Maybe that query should also consider inherited fields and
 *  should consider any read before any write in general regardless
 *  of whether there occurs a write afterwards or not
 */

import java

predicate initializesStaticField(Method m, Field f) {
    // TODO: Uses getDeclaringType() as workaround for raw types being the result
    // for static method access on generic types, see https://github.com/github/codeql/issues/5593
    m.getDeclaringType().getSourceDeclaration() = f.getDeclaringType()
    and (
        f.getAnAccess().(FieldWrite).getEnclosingCallable() = m
        // Assume that native method might initialize field
        or m.isNative()
    )
    // Or special JVM method intializing fields from archive; Java Class Data Sharing (CDS)
    or (
        m.getDeclaringType().hasQualifiedName("jdk.internal.misc", "VM")
        and m.hasName("initializeFromArchive")
    )
}

from StaticInitializer staticInit, Field f, FieldRead read
where
    f.isStatic()
    and f.getDeclaringType() = staticInit.getDeclaringType()
    and read.getField() = f
    and read.getEnclosingCallable() = staticInit
    // Ignore fields which are initialized with compile time constants since the
    // compiler inlines the constant (though field access has to use explicit qualifier)
    and not f.getInitializer().isCompileTimeConstant()
    // There is no write to the field before the read; since this is all in the same
    // StaticInitializer, this also considers initialization of a field at declaration
    and not exists(FieldWrite write |
        write.getField() = f
        and write.getEnclosingCallable() = staticInit
        and write.getParent().(Expr).getControlFlowNode().getASuccessor+() = read.getControlFlowNode()
    )
    // And there is not call which might initialize field
    and not exists(MethodAccess call |
        call.getEnclosingCallable() = staticInit
        and call.getControlFlowNode().getASuccessor+() = read.getControlFlowNode()
        and initializesStaticField(call.getMethod(), f)
    )
select read, "Reads uninitialized static field $@", f, f.getName()

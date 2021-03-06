/**
 * Finds interface methods whose `default` implementation might be error-prone.
 * Often `default` methods are misused to introduce methods which subtypes have
 * to implement, but due to binary compatibility the method was not made
 * `abstract`. Such a method is then either implemented as no-op or it always
 * throws an exception.  
 * However, such implementations are error-prone because it is likely that
 * subtypes forget to override the method, leaving it in a broken or incomplete
 * state. E.g.:
 * ```
 * interface Validator {
 *     void validate(Path file) throws ValidationException;
 *
 *     // Method might have been introduced in later release and implemented
 *     // as no-op to not break binary compatibility; however if subtypes
 *     // forget to override it, they might behave incorrectly
 *     default void validate(JarInputStream jar) throws ValidationException {
 *         // Subtypes have to override this method
 *     }
 * }
 * ```
 *
 * It might be better to make the method `abstract` and introduce it in the next
 * major release, so dependent projects can update their code.
 *
 * Note that for some methods it is acceptable to have a no-op implementation,
 * e.g. for listeners. This makes it easier for subtypes to only override the
 * methods they are interested in, and not having to implement all the other
 * methods.
 */

// TODO: Maybe in the future cover non-abstract methods in abstract classes as well
//       Though this might lead to more false-positives

import java

from Method defaultMethod, BlockStmt body
where
    defaultMethod.isDefault()
    and body = defaultMethod.getBody()
    and (
        // Empty body
        body.getNumStmt() = 0
        or
        // Or only one statement
        body.getNumStmt() = 1
        // No parameter is used
        and not exists(Parameter p | p = defaultMethod.getAParameter() |
            exists(p.getAnAccess())
        )
        // No call is made
        and not exists(Call call | call.getEnclosingCallable() = defaultMethod |
            // Ignore creation of new exceptions as part of `throw`
            not call.(ClassInstanceExpr).getEnclosingStmt() instanceof ThrowStmt
        )
        // No field is accessed
        and not exists(defaultMethod.getAnAccessedField())
        and exists(Stmt s |
            s = body.getAStmt()
        |
            // Throws exception but does not use parameter (parameter access is checked above)
            // If method had no parameters, then default method might be legit implementation
            // for throwing exceptions
            s instanceof ThrowStmt and defaultMethod.getNumberOfParameters() > 0
            // `return this`; method is probably intended for chaining, but does nothing
            or s.(ReturnStmt).getResult() instanceof ThisAccess
        )
    )
    // Ignore listener and visitor classes which have default implementation so subtypes
    // only have to override methods they are interested in
    and not defaultMethod.getDeclaringType().getName().matches(["%Listener", "%Watcher", "%Observer", "%Monitor", "%Visitor"])
    // Ignore test classes which might only test reflection utilities on method
    and not defaultMethod.getDeclaringType().getEnclosingType*() instanceof TestClass
select defaultMethod, "Method might have error-prone default implementation"

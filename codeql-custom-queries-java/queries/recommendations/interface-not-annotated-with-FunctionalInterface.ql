/**
 * Finds interfaces which are used as functional interface by a lambda or method reference
 * expression, but which are not annotated with `@FunctionalInterface`. To avoid breaking
 * these usages and to make the intention clearer the interface should be annotated with
 * `@FunctionalInterface`. This prevents accidental modifications to the interface which
 * would prevent it from being used as functional interface.
 */

import java

from Interface interface, FunctionalExpr functionalExpr
where
    interface.fromSource()
    and functionalExpr.asMethod().getASourceOverriddenMethod().getDeclaringType() = interface
    and not interface.getAnAnnotation().getType().hasQualifiedName("java.lang", "FunctionalInterface")
select interface, "Interface is not annotated with @FunctionalInterface, but used as functional interface $@", functionalExpr, "here"

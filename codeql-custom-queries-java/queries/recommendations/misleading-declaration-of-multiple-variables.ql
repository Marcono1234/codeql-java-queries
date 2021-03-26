/**
 * Finds declarations of local variables or fields where multiple are
 * declared at once but only some are initialized, and in a misleading
 * way. E.g.:
 * ```java
 * // Should separate these declarations; only `s2` is initialized
 * String s1, s2 = "test";
 * ```
 * Declaration of multiple variables are not very common and programmers
 * might not be familiar with their syntax. Only initializing some
 * of the variables, and declaring them after a variable without
 * initialization might be misleading since a reader could assume the
 * previous variables are initialized by this as well.
 */

import java

// Use boolean result instead of making it a predicate without result because
// have to differentiate between no var at that index and var, but no init
// LocalVariableDeclStmt is 1-based, FieldDeclaration is 0-based, therefore
// cannot solve this only by binding indices in `where` clause
private boolean hasVarInit(Top variableDecl, int varIndex) {
    exists(LocalVariableDeclExpr declExpr |
        declExpr = variableDecl.(LocalVariableDeclStmt).getVariable(varIndex)
    |
        if exists(declExpr.getInit()) then result = true
        else result = false
    )
    or exists(Field f |
        f = variableDecl.(FieldDeclaration).getField(varIndex)
    |
        if exists(f.getInitializer()) then result = true
        else result = false
    )
}

/*
 * Only consider if var without init occurs before var with init, e.g.:
 * String s1, s2 = "";
 * Ignore cases where no init exists, or where init occurs only before
 * and is therefore not misleading, e.g.:
 * String s1 = "", s2;
 */
from Top variableDecl, int noInitIndex, int initIndex
where
    hasVarInit(variableDecl, noInitIndex) = false
    and noInitIndex < initIndex
    and hasVarInit(variableDecl, initIndex) = true
select variableDecl, "Misleading declaration of multiple variables"

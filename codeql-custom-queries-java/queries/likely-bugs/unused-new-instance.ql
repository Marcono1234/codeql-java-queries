/**
 * Finds cases where a new instance is created, but not used afterwards.
 *
 * If the intention is to perform argument validation, it might be better
 * to use the created instance in case it was successfully created instead
 * of creating an instance at a later point again.
 *
 * If the constructor has side effects such as starting a new thread or
 * registering the instance somewhere, it might be good to redesign it
 * to perform this in a separate step to make the design clearer.
 */

import java

from ClassInstanceExpr newExpr
where
    newExpr.getParent() instanceof ExprStmt
    // Verify that instance creation does not happen in test method
    // Might be used there to test error handling
    and not newExpr.getEnclosingCallable() instanceof TestMethod
select newExpr

import java

class NumericPrimitiveType extends PrimitiveType {
    NumericPrimitiveType() {
        not hasName("boolean")
    }
}

// TODO: Maybe reduce false positives when following stream operation
// only works for boxed, e.g. collecting to List<Integer>

// TODO: Consider `iterate(...)` with primitive value as seed ?
// TODO: Consider `reduce(...)` with primitive value as identity ?

from MethodAccess streamMethodCall, FunctionalExpr functionalExpr
where
  // TODO: Need to restrict this more, some Stream methods are fine
  streamMethodCall.getMethod().getDeclaringType().getSourceDeclaration().getASourceSupertype*().hasQualifiedName("java.util.stream", "Stream")
  and functionalExpr = streamMethodCall.getAnArgument()
  and forex(ReturnStmt returnStmt |
    returnStmt.getEnclosingCallable() = functionalExpr.asMethod()
  |
    // TODO: Causes false positives for `void` functional methods
    returnStmt.getResult().getType() instanceof NumericPrimitiveType
  )
select streamMethodCall


// TODO: Maybe also consider Collectors methods
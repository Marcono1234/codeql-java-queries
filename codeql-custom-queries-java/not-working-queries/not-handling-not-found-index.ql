import java
import semmle.code.java.dataflow.TaintTracking

class IndexMethod extends Method {
    IndexMethod() {
        (
          getDeclaringType().hasQualifiedName("java.lang", "String")
          and (hasName("indexOf") or hasName("lastIndexOf"))
        )
        or (
          exists (RefType declType | declType = getDeclaringType() |
             declType instanceof StringBuildingType
            and (hasName("indexOf") or hasName("lastIndexOf"))
          )
        )
        or (
          getDeclaringType().hasQualifiedName("java.util", "List")
          and (hasName("indexOf") or hasName("lastIndexOf"))
      )
    }
}

// TODO: This is incorrect
/*
 * Assume that `+ 1` is sanitizing because this results in `0`
 * as index which is most of the times valid
 *
 * This pattern is used to remove an optional prefix, e.g.:
 * str.substring(str.indexOf("optprefix") + 1)
 */
predicate isSanitizingAddArg(Expr expr) {
   exists (PreIncExpr preIncExpr |
     preIncExpr.getExpr() = expr
   )
   or exists (PostIncExpr postIncExpr |
     postIncExpr.getExpr() = expr
   )
   or exists (AssignAddExpr assignAddExpr | 
     assignAddExpr.getDest() = expr
     and assignAddExpr.getRhs().(IntegerLiteral).getIntValue() = 1
  )
  or exists (AddExpr addExpr |
    addExpr.getAnOperand() = expr
    and addExpr.getAnOperand().(IntegerLiteral).getIntValue() = 1
  )
}

predicate isPubliclyVisible(RefType t) {
    t.isPublic()
    and (
        not exists (t.getEnclosingType())
        or isPubliclyVisible(t.getEnclosingType())
    )
}

class IndexIncrementConfiguration extends TaintTracking::Configuration {
    IndexIncrementConfiguration() {
        this = "IndexIncrementConfiguration"
    }

    override predicate isSource(DataFlow::Node source) {
        exists(MethodAccess call, Method m |
            source.asExpr() = call
            and m = call.getMethod()
            and m.getAnOverride*() instanceof IndexMethod
            // TODO: Maybe remove public method parameter restriction
            and exists (Parameter p, Callable pCallable |
              pCallable = p.getCallable()
              and pCallable.isPublic()
              and isPubliclyVisible(pCallable.getDeclaringType())
              and (
                call.getAnArgument() = p.getAnAccess()
                or call.getQualifier() = p.getAnAccess()
              )
            )
        )
    }

    override predicate isSink(DataFlow::Node sink) {
        exists (MethodAccess call |
        	sink.asExpr() = call.getAnArgument()
     	)
    }

    // TODO: Maybe should be isSanitizerOut, but that maybe that has a different meaning
    // TODO: Does not work if equality test happens in loop where result is also assigned to variable?
    override predicate isSanitizer(DataFlow::Node node) {
        exists (ComparisonExpr compExpr |
            node.asExpr() = compExpr.getAnOperand()
        )
        or exists (EqualityTest eqTest |
           node.asExpr() = eqTest.getAnOperand()  
        )
        //or isSanitizingAddArg(node.asExpr())
    }
}

from DataFlow::Node src, DataFlow::Node sink
where
    exists (IndexIncrementConfiguration config | config.hasFlow(src, sink))
select src, sink
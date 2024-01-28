/**
 * Finds loop statements such as `while (...) { ... }` which seem to loop infinitely
 * because the loop condition depends on variables which are not updated in the loop.
 *
 * This also covers cases where the loop condition depends on a non-`volatile` field
 * which might therefore indicate thread- and memory-safety issues if updates to
 * that field are not guaranteed to be fully or consistently visible to the reading
 * thread.
 *
 * @id todo
 * @kind problem
 */

// TODO: Seems to have false positives for Kotlin because it does not recognize
// variable updates in loop body?

// Note: Slightly similar to standard CodeQL query `java/unreachable-exit-in-loop`;
// might also have some overlap with standard query `java/spin-on-field`
import java

Expr getAWrite(Variable v) {
  result.(LValue) = v.getAnAccess()
  or
  exists(ArrayAccess arrayAccess | arrayAccess.getArray() = v.getAnAccess() |
    result.(Assignment).getDest() = arrayAccess or
    result.(UnaryAssignExpr).getExpr() = arrayAccess
  )
}

predicate isWrittenInLoop(Variable v, LoopStmt loop) {
  exists(Expr write | write = getAWrite(v) |
    write.getAnEnclosingStmt() = loop.getBody() or
    write.getParent*() = [loop.getCondition(), loop.(ForStmt).getAnUpdate()]
  )
}

Stmt getAnEnclosingStmt(Expr e) {
  result = e.getAnEnclosingStmt()
  or
  exists(FunctionalExpr f |
    e.getEnclosingCallable() = f.asMethod() and
    result = getAnEnclosingStmt(f)
  )
}

from LoopStmt loop
where
  // Exclude 'for each loop' which is limited implicitly by the number of elements
  exists(loop.getCondition()) and
  // Ignore explicit infinite loops
  not loop.getCondition().(BooleanLiteral).getBooleanValue() = true and
  // If the condition checks local variables, they are not updated in the loop
  forall(LocalScopeVariable localVar | localVar.getAnAccess().getParent*() = loop.getCondition() |
    not isWrittenInLoop(localVar, loop)
  ) and
  // If the condition checks fields, they are not updated in the loop (also not
  // implicitly by calling a method)
  forall(Field f | f.getAnAccess().getParent*() = loop.getCondition() |
    // If `volatile` then it might be updated concurrently by different thread
    not f.isVolatile() and
    // Even if non-volatile, ignore `boolean` fields, maybe there is implicit synchronization
    // logic which makes sure value change is seen eventually by reading thread; however,
    // for other types there might be other thread-safety issues, so don't consider them safe
    not f.getType().hasName("boolean") and
    not isWrittenInLoop(f, loop) and
    not exists(MethodAccess call |
      getAnEnclosingStmt(call) = loop.getBody()
      or
      call.getParent*() = [loop.getCondition(), loop.(ForStmt).getAnUpdate()]
    |
      // But only consider methods in source which might update field, ignore for example
      // calls to JDK methods
      call.getMethod().getSourceDeclaration().fromSource()
    )
  ) and
  // Ignore if condition depends on method, in that case it is very likely not infinite
  not exists(MethodAccess call | call.getParent*() = loop.getCondition()) and
  // Ignore if loop is left manually using e.g. `break`
  not (
    any(BreakStmt b).getTarget() = loop or
    any(ReturnStmt r).getEnclosingStmt*() = loop.getBody()
  )
select loop, "Potential infinite loop"

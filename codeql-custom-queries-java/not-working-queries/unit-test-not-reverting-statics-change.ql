import java

FieldAccess getAQualifier(FieldAccess fieldAccess) {
  result = fieldAccess.getQualifier()
}

FieldAccess getMutatingFieldAccess(Expr expr) {
  (
    result = expr.(FieldWrite)
    and (
      getAQualifier*(result).getField().isStatic()
      or getAQualifier*(result).isOwnFieldAccess()
    )
    // Ignore lazy initialization of field, using null check
    and not exists (ConditionNode conditionNode, EqualityTest nullCheckExpr |
      nullCheckExpr = conditionNode.getCondition()
      and nullCheckExpr.getAnOperand() instanceof NullLiteral
      and nullCheckExpr.getAnOperand().(FieldAccess).getField() = result.getField()
      and conditionNode.getABranchSuccessor(nullCheckExpr.polarity()).getASuccessor*() = result.getParent().(Expr).getBasicBlock()
    )
    // Ignore lazy initialization of field, using boolean flag
    and not exists (ConditionNode conditionNode, Field flag, boolean branch, Assignment flagAssignment |
      conditionNode.getCondition() = flag.getAnAccess()
      // Check for flag assignment which happens in same branch as field write
      and conditionNode.getABranchSuccessor(branch).getASuccessor*() =  result.getParent().(Expr).getBasicBlock()
      and flagAssignment.getDest() = flag.getAnAccess()
      and conditionNode.getABranchSuccessor(branch).getASuccessor*() =  flagAssignment
    )
  )
  or (
    result = expr.(Assignment).getDest().(ArrayAccess).getArray()
    and (
      getAQualifier*(result).getField().isStatic()
      or getAQualifier*(result).isOwnFieldAccess()
    )
  )
  or exists (Expr mutatingExpr |
    (
      expr.(MethodAccess).getMethod().isStatic()
      or getAQualifier*(expr.(MethodAccess).getQualifier()).getField().isStatic()
      or getAQualifier*(expr.(MethodAccess).getQualifier()).isOwnFieldAccess()
    )
    and mutatingExpr.getEnclosingCallable() = expr.(MethodAccess).getMethod()
    and result = getMutatingFieldAccess(mutatingExpr)
  )
}

class InstanceOrStaticMutatingExpr extends Expr {
  InstanceOrStaticMutatingExpr() {
    exists (getMutatingFieldAccess(this))
  }
  
  predicate isStatic() {
    getAQualifier*(this).getField().isStatic()
    or this.(MethodAccess).getMethod().isStatic()
    or getAQualifier*(this.(MethodAccess).getQualifier()).getField().isStatic()
  }
  
  FieldAccess getMutatingFieldAccess() {
    result = getMutatingFieldAccess(this)
  }
}

class StaticMutatingExpr extends InstanceOrStaticMutatingExpr {
  StaticMutatingExpr() {
    this.isStatic()
  }
}


abstract class BeforeMethod extends Method {
  abstract AfterMethod getAfterMethod();
}

abstract class AfterMethod extends Method {}

class BeforeClassMethod extends BeforeMethod {
  BeforeClassMethod() {
    getAnAnnotation().getType().getQualifiedName() in [
      "org.junit.BeforeClass", // JUnit 4
      "org.junit.jupiter.api.BeforeAll", // JUnit 5
      "org.testng.annotations.BeforeClass" // TestNG
    ]
  }
  
  override
  AfterClassMethod getAfterMethod() {
    result.getDeclaringType() = getDeclaringType()
  }
}

class AfterClassMethod extends AfterMethod {
  AfterClassMethod() {
    getAnAnnotation().getType().getQualifiedName() in [
      "org.junit.AfterClass", // JUnit 4
      "org.junit.jupiter.api.AfterAll", // JUnit 5
      "org.testng.annotations.AfterClass" // TestNG
    ]
  }
}

class BeforeEachMethod extends BeforeMethod {
  BeforeEachMethod() {
    getAnAnnotation().getType().getQualifiedName() in [
      "org.junit.Before", // JUnit 4
      "org.junit.jupiter.api.BeforeEach", // JUnit 5
      "org.testng.annotations.BeforeMethod" // TestNG
    ]
  }
  
  override
  AfterEachMethod getAfterMethod() {
    result.getDeclaringType() = getDeclaringType()
  }
}

class AfterEachMethod extends AfterMethod {
  AfterEachMethod() {
    getAnAnnotation().getType().getQualifiedName() in [
      "org.junit.After", // JUnit 4
      "org.junit.jupiter.api.AfterEach", // JUnit 5
      "org.testng.annotations.AfterMethod" // TestNG
    ]
  }
}

// Suffix `_` because QL already defines a class with this name
class TestMethod_ extends Method {
  TestMethod_() {
    getAnAnnotation().getType().getQualifiedName() in [
      "org.junit.Test", // JUnit 4
      "org.junit.jupiter.api.Test", // JUnit 5
      "org.junit.jupiter.api.ParameterizedTest", // JUnit 5
      "org.junit.jupiter.api.RepeatedTest", // JUnit 5
      "org.testng.annotations.Test" // TestNG
    ]
  }
}

FieldAccess getFirstQualifier(FieldAccess fieldAccess) {
  result = getFirstQualifier(fieldAccess.getQualifier())
  or result = fieldAccess
}

from Method m, StaticMutatingExpr mutatingExpr, FieldAccess mutatingAccess
where
  m = mutatingExpr.getEnclosingCallable()
  and mutatingAccess = mutatingExpr.getMutatingFieldAccess()
  and not exists(mutatingAccess.getLocation().getFile().getRelativePath().indexOf("test"))
  and (
    (
      m instanceof BeforeMethod
      // Ignore case where mutation happens on field within same compilation unit
      // and no other compilation unit uses that field
      //   TODO: This assumption is wrong, if multiple test methods use that field, or 
      //   if RepeatedTest uses it, then it will affect other test runs
      and not (
        forall (FieldAccess fieldAccess |
          fieldAccess = mutatingAccess.getField().getAnAccess()
          |
          fieldAccess.getCompilationUnit() = m.getCompilationUnit()
        )
        or forall (FieldAccess qualifierFieldAccess |
          // Ignore if field is static because then it does not matter on which
          // object method is called
          not mutatingAccess.getField().isStatic()
          and qualifierFieldAccess = getFirstQualifier(mutatingExpr.(MethodAccess).getQualifier()).getField().getAnAccess()
          |
          qualifierFieldAccess.getCompilationUnit() = m.getCompilationUnit()
        )
      )
      and not exists (AfterMethod after, StaticMutatingExpr resettingExpr |
        after = m.(BeforeMethod).getAfterMethod()
        and mutatingExpr != resettingExpr
        // TODO: This is incorrect, if mutated field is not static, might matcher mutation of field
        // or other instance
        and mutatingAccess.getField() = resettingExpr.getMutatingFieldAccess().getField()
        and resettingExpr.getEnclosingCallable() = after
      )
    )
    or (
      m instanceof TestMethod_
      and not exists (StaticMutatingExpr resettingExpr |
        mutatingExpr != resettingExpr
        // TODO: This is incorrect, if mutated field is not static, might matcher mutation of field
        // or other instance
        and mutatingAccess.getField() = resettingExpr.getMutatingFieldAccess().getField()
        and resettingExpr.getEnclosingCallable() = mutatingExpr.getEnclosingCallable()
      )
    )
  )
select mutatingExpr, mutatingAccess

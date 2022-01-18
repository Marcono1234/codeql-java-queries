/**
 * Finds creation of a secret token from the result of one of the Apache Commons Lang
 * `RandomStringUtils` methods. These methods uses a `Random` instance which is not
 * cryptographically secure and should therefore not be used for the creation of
 * secret tokens. Instead the overload with `Random` parameter can be used with an
 * instance of `SecureRandom`.
 */

// Similar to CodeQL's query `java/jhipster-prng`

import java
import semmle.code.java.frameworks.apache.Lang
import semmle.code.java.security.SensitiveActions
import semmle.code.java.dataflow.DataFlow

class PseudoRandomCall extends MethodAccess {
    PseudoRandomCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType() instanceof TypeApacheRandomStringUtils
            and m.getReturnType() instanceof TypeString
            // Ignore if caller can provide own Random instance
            and not m.getAParamType().(RefType).getASourceSupertype*().hasQualifiedName("java.util", "Random")
        )
    }
}

bindingset[name]
predicate isSensitiveName(string name) {
    // Uses regexpFind as workaround for https://github.com/github/codeql/issues/7636
    exists(name.regexpFind(getCommonSensitiveInfoRegex(), _, _))
    or name.regexpMatch("(?i).*auth.*")
}

from PseudoRandomCall randomCall
where
    // Result is assigned to sensitive variable, e.g. `authToken`
    exists(Variable var |
        isSensitiveName(var.getName())
        and DataFlow::localExprFlow(randomCall, var.getAnAssignedValue())
    )
    // Or result is returned by method with sensitive name, e.g. `generateToken()`
    or exists(Method m, ReturnStmt returnStmt |
        returnStmt.getEnclosingCallable() = m
        and isSensitiveName(m.getName())
        and DataFlow::localExprFlow(randomCall, returnStmt.getResult())
    )
select randomCall, "Pseudo number generator used for security token"

/**
 * Finds overriding methods which seem to have parameters switched by accident,
 * compared to the overridden method.
 *
 * For example:
 * ```java
 * void addUser(String firstName, String lastName);
 *
 * ...
 *
 * // Accidentally has "lastName" as first parameter
 * @Override
 * void addUser(String lastName, String firstName) {
 *     ...
 * }
 * ```
 *
 * @id TODO
 * @kind problem
 */

// TODO: Could make this more precise (at the risk of more false negatives) by checking that parameters
// are really switched, i.e. the other expected param also has the overriding param switched
// (currently the query just checks if the param is at the wrong index)
import java

// CodeQL seems to generate param names in the form p0, p1, ... for external classes
predicate areParamNamesKnown(Method m) {
  m.fromSource()
  or
  // Or there is a param name which is not `p<N>`
  exists(string paramName | paramName = m.getAParameter().getName() |
    not paramName.regexpMatch("p\\d+")
  )
}

from
  Method m, int pIndex, Parameter p, Method overridden, int pOverriddenIndex, Parameter pOverridden
where
  m.fromSource() and
  p = m.getParameter(pIndex) and
  overridden = m.getAnOverride() and
  // TODO: Maybe also check that both parameters have same type, or common (non-Object) supertype
  pOverridden = overridden.getParameter(pOverriddenIndex) and
  pOverridden.getName() = p.getName() and
  pOverriddenIndex != pIndex and
  areParamNamesKnown(overridden)
select p, "Has different position than $@ parameter in overridden method", pOverridden, "this"

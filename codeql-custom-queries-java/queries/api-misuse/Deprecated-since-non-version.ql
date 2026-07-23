/**
 * For the `@Deprecated` annotation the `since` element represents:
 * > the version in which the annotated element became deprecated
 *
 * This query finds `since` values which do not seem to be a version and are
 * regular text instead. Use the `@deprecated` Javadoc tag for this instead,
 * describing the reason for the deprecation and replacements, if any.
 *
 * @kind problem
 * @id TODO
 */

import java

from DeprecatedAnnotation annotation, string since
where
  since = annotation.getStringValue("since") and
  // Non-empty value containing no digit
  since.regexpMatch("[^\\d]+")
select annotation, "`since` value is not a version"

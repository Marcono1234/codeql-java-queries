/**
 * Finds code which uses identifiers which become keywords or restricted identifiers
 * in future Java versions. Such code will prevent upgrading to a newer Java version
 * and might prevent usage by other applications.
 * 
 * See [JLS 16 §3.8: Identifiers](https://docs.oracle.com/javase/specs/jls/se16/html/jls-3.html#jls-3.8)
 */

/*
 * Overlaps with CodeQL queries `java/underscore-identifier` and `java/enum-identifier`
 */

import java

/*
 * Based on
 * - https://docs.oracle.com/javase/tutorial/java/nutsandbolts/_keywords.html
 * - https://en.wikipedia.org/wiki/List_of_Java_keywords
 * - https://docs.oracle.com/javase/specs/jls/se16/html/jls-3.html#jls-3.8
 */
bindingset[identifier]
predicate usesFutureKeyword(Element e, string identifier, int sinceJavaVersion, boolean isRestrictedIdentifier) {
    isRestrictedIdentifier = false
    and (
        identifier = "strictfp" and sinceJavaVersion = 2
        or identifier = "assert" and sinceJavaVersion = 4
        or identifier = "enum" and sinceJavaVersion = 5
        or identifier = "_" and sinceJavaVersion = 9
    )
    or
    isRestrictedIdentifier = true
    and (e instanceof ClassOrInterface or e instanceof TypeVariable)
    and (
        identifier = "var" and sinceJavaVersion = 10
        or identifier = ["yield", "record"] and sinceJavaVersion = 14
    )
    // Don't consider "yield" as method name; this actually only applies to unqualified method
    // access, declaration of such method is allowed
}

from Element e, string identifier, string tempMessage, string message, int sinceJavaVersion, boolean isRestrictedIdentifier
where
    e.fromSource()
    // Element name, or for package consider all components (since they are identifiers)
    and identifier = [e.getName(), e.(Package).getName().splitAt(".")]
    and usesFutureKeyword(e, identifier, sinceJavaVersion, isRestrictedIdentifier)
    and (
        isRestrictedIdentifier = true and tempMessage = "'" + identifier + "' is a restricted identifier since Java " + sinceJavaVersion
        or isRestrictedIdentifier = false and tempMessage = "'" + identifier + "' is a keyword since Java " + sinceJavaVersion
    )
    // Ignore constructors since they must have the same name as the declaring class (instead report the declaring class)
    and not e instanceof Constructor
    // Package has no source location, therefore include its name in message
    and if e instanceof Package then message = "Package '" + e.getName() + "': " + tempMessage
    else message = tempMessage
select e, message

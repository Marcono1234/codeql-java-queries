/**
 * Finds Maven POMs which specify a non-existent class as 'main class'.
 * 
 * Note that this query might produce false positives when the referenced
 * main class is not part of the queried QL database, but is for example added
 * by a plugin to the result JAR.
 */

import java
import lib.MavenLib

from MainClassElement mainClassElement, string mainClassName
where
    mainClassName = mainClassElement.getValue()
    and not exists(ClassOrInterface mainClass |
        // Neither parameterized nor raw type
        mainClass.getSourceDeclaration() = mainClass
        and mainClass.getQualifiedName() = mainClassName
    )
select mainClassElement, "Refers to non-existent main class '" + mainClassName + "'"

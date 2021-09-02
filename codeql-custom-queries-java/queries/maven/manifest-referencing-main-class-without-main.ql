/**
 * Finds Maven POMs which specify a class without `main` method as 'main class'.
 */

import java
import lib.MavenLib

from MainClassElement mainClassElement, ClassOrInterface mainClass
where
    // Neither parameterized nor raw type
    mainClass.getSourceDeclaration() = mainClass
    and mainClass.getQualifiedName() = mainClassElement.getValue()
    and not exists(MainMethod mainMethod |
        mainMethod.getDeclaringType() = mainClass
    )
select mainClassElement, "Refers to class $@ which does not have a `main` method", mainClass, mainClass.getName()

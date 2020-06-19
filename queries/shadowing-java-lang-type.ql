/**
 * Finds classes or interfaces with the same name as a type in the
 * `java.lang` package. These types are automatically imported and
 * are used commonly. Defining an own type with such a name can lead
 * to confusion.
 */

import java

from ClassOrInterface shadowingClass, ClassOrInterface shadowedClass
where
    shadowingClass.fromSource()
    and shadowingClass.getPackage().getName() != "java.lang"
    and shadowedClass.getPackage().getName() = "java.lang"
    and shadowedClass.isTopLevel()
    and shadowingClass.getName() = shadowedClass.getName()
select shadowingClass, shadowedClass.getQualifiedName()

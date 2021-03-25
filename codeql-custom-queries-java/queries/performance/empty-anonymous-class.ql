/**
 * Finds empty anonymous classes. If an anonymous class does not override
 * any methods or defines additional fields, there is no need to create an
 * anonymous class. Simply creating an instance of the super class would
 * suffice. The creation of an anonymous class additionally creates an
 * unnecessary separate class file in this case.
 *
 * Note that this does not match anonymous classes whose super type is an
 * interface or a class which acts as a "type token", i.e. it has a generic
 * type parameter and is intended to be subclassed by anonymous classes to
 * to make the generic type argument available at compile-time.
 */

import java

/**
 * Class which appears to be intended to be subclassed by anonymous classes to make
 * the generic type argument available at compile-time. E.g. Gson's or Guava's `TypeToken`.
 */
class TypeToken extends GenericType {
    TypeToken() {
        // Make sure there is only one type variable, otherwise it might not
        // be a type token
        count(getATypeParameter()) = 1
        and exists (Method m |
            m = getAMethod()
            and not m.isStatic()
            and m.getNumberOfParameters() = 0
            and m.getReturnType().(RefType).hasQualifiedName("java.lang.reflect", "Type")
        )
    }
}

from AnonymousClass anonymousClass
where
    not anonymousClass.getASourceSupertype() instanceof TypeToken
    // QL adds as only member a default constructor
    and forall (Member m | m = anonymousClass.getAMember() |
        m.(Constructor).isDefaultConstructor()
    )
    // Make sure that super type is not abstract, otherwise have to create
    // (anonymous) subclass
    and exists (RefType supertype |
        supertype = anonymousClass.getASupertype()
        // Ignore if type is java.lang.Object, which is the case when
        // anonymous class implements interface
        and not supertype instanceof TypeObject
        and not supertype.isAbstract()
    )
select anonymousClass

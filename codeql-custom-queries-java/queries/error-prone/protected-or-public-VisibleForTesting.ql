/**
 * Finds `protected` and `public` elements which are annotated with an annotation indicating
 * that the element is only supposed to be used by test code, respectively only has increased
 * visibility to be accessible by tests.
 * 
 * Prefer making the element at most package-private (i.e. no access modifier), otherwise
 * the element might be accessed by accident outside of test code. Normally test code is in
 * the same package and can therefore access package-private elements. If the test is not
 * in the same package for some reason, a workaround could be to create a `public` accessor
 * class in the same package in the test sources which provides access to package-private
 * elements in the main source for the tests in the other package.
 * 
 * @kind problem
 */

import java

from Annotatable annotated
where
    annotated.getAnAnnotation().getType().hasName([
        // Android, Guava and JetBrains annotations
        "VisibleForTesting",
        // JetBrains annotations
        "TestOnly",
    ])
    and (
        annotated.(Modifiable).isProtected()
        or annotated.(Modifiable).isPublic()
    )
select annotated, "Element is made publicly visible for testing; should be at most package-private"

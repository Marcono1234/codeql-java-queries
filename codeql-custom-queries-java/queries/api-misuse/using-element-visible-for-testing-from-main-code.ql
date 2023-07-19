/**
 * Finds code which uses elements that are only intended to be used by tests.
 * 
 * Since these elements are not considered part of the public API, relying on them
 * should be avoided because they could be removed in future versions or their behavior
 * could change without any announcement.
 * 
 * @kind problem
 */

import java

class TestOnlyAnnotation extends Annotation {
    TestOnlyAnnotation() {
        getType().hasName([
            // JetBrains annotations
            "TestOnly",
        ])
    }
}

from Annotatable elementForTesting, Expr usage
where
    (
        elementForTesting.getAnAnnotation() instanceof TestOnlyAnnotation
        or
        elementForTesting.getAnAnnotation().getType().hasName([
            // Android, Guava and JetBrains annotations
            "VisibleForTesting",
        ])
        // To reduce false positives only consider elements which are public for testing and
        // are used from other package
        and elementForTesting.getCompilationUnit().getPackage() != usage.getCompilationUnit().getPackage()
    )
    and (
        elementForTesting.(Field).getAnAccess() = usage
        or elementForTesting = usage.(Call).getCallee().getSourceDeclaration()
        or elementForTesting = usage.(TypeAccess).getType().(RefType).getSourceDeclaration()
    )
    // Ignore if access is from test code
    and not (
        usage.getEnclosingCallable().getDeclaringType() instanceof TestClass
        or usage.getFile().getAbsolutePath().matches("%/test/%")
    )
    // Ignore if caller is itself also only intended for testing
    and not usage.getEnclosingCallable().getAnAnnotation() instanceof TestOnlyAnnotation
select usage, "Uses element '$@' which is only visible for testing", elementForTesting, elementForTesting.getName()

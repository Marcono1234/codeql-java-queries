/**
 * Finds test classes which do not appear to be in the same package as
 * the tested class. This might make the test results confusing, and
 * requires that tested members, which would normally have been package-private,
 * to be public.
 */

import java

bindingset[a, b]
private int getMismatchIndex(string a, string b) {
    result = [0 .. a.length()]
    and a.prefix(result) = b.prefix(result)
    and a.prefix(result + 1) != b.prefix(result + 1)
}

bindingset[a, b]
private string getMismatchMessage(string a, string b) {
    exists(int mismatchIndex | mismatchIndex = getMismatchIndex(a, b) |
        result = "…" + a.suffix(mismatchIndex) + " vs. …" + b.suffix(mismatchIndex)
    )
}

from TopLevelClass testClass, string testClassPackage, string testClassName, TopLevelType testedType, string testedTypePackage
where
    testClass.fromSource() and testedType.fromSource()
    and testClass instanceof TestClass
    and testClassName = testClass.getName()
    and testClassName.matches("%Test")
    and testedType.getName() = testClassName.prefix(testClassName.length() - "Test".length())
    // And verify that the assumed testedType is actually used in test class
    and exists(TypeAccess typeAccess |
        typeAccess.getEnclosingCallable().getDeclaringType() = testClass
        and typeAccess.getType() = testedType
    )
    and testClassPackage = testClass.getPackage().getName()
    and testedTypePackage = testedType.getPackage().getName()
    and testClassPackage != testedTypePackage
    // And verify that testedType is not actually an unrelated class with the same name
    // (which is accessed in the test class as well)
    and not exists(TopLevelType actualTestedType, TypeAccess typeAccess |
        actualTestedType.getName() = testedType.getName()
        and actualTestedType.getPackage().getName() = testClassPackage
        and typeAccess.getEnclosingCallable().getDeclaringType() = testClass
        // And `actualTestedType` is accessed in the test
        and typeAccess.getType() = actualTestedType
    )
select testClass, "Test class is not in same package as $@: " + getMismatchMessage(testClassPackage, testedTypePackage),
    testedType, "tested type"

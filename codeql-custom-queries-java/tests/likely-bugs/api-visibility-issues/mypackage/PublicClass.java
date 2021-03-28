package mypackage;

import notexportedpackage.NotExportedClass;
import restrictedpackage.RestrictedClass;

public class PublicClass {
    // Bad, class is not exported in module declaration
    public NotExportedClass getNotExported() {
        return null;
    }

    // Bad, class is only exported to some modules
    public RestrictedClass getRestrictedClass() {
        return null;
    }

    // Bad, class is only package private
    public PackagePrivateClass getPackagePrivateClass() {
        return null;
    }

    private static class PrivateClass {
    }

    // Bad, class is only private
    public PrivateClass getPrivateClass() {
        return null;
    }

    protected static class ProtectedClass {
    }

    // Bad, class is only protected
    public ProtectedClass getProtectedClass() {
        return null;
    }

    // Correct
    public String getPublicClass() {
        return "";
    }

    // Correct, protected method exposed protected type
    protected ProtectedClass getProtectedClassCorrect() {
        return null;
    }

    public static class DifferentProtected {
        // Bad, subclassing DifferentProtected does not make ProtectedClass visible
        protected ProtectedClass getProtectedClass() {
            return null;
        }
    }

    public static class ProtectedClassDeclaring {
        protected static class OtherProtectedClass {
        }
    }

    public static class InheritedProtected extends ProtectedClassDeclaring {
        // Correct, InheritedProtected extends ProtectedClassDeclaring, so subclassing InheritedProtected
        // makes OtherProtectedClass visible as well
        protected OtherProtectedClass getInheritedProtectedClass() {
            return null;
        }
    }
}

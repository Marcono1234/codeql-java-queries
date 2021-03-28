package restrictedpackage;

import mypackage.PublicClass;

/**
 * Class is only exported to some modules.
 */
public class RestrictedClass {
    // Correct, class is exported to all modules
    public PublicClass getPublicClass() {
        return null;
    }

    // Bad, class is only package private
    public PackagePrivateClass getPackagePrivateClass() {
        return null;
    }
}

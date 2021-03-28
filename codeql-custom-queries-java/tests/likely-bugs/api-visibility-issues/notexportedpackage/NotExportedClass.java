package notexportedpackage;

import otherrestrictedpackage.OtherRestrictedClass;
import restrictedpackage.RestrictedClass;

/**
 * Class which is not exported to any other modules.
 */
public class NotExportedClass {
    // Does not matter; this class is not publicly visible
    public RestrictedClass getRestrictedClass() {
        return null;
    }

    private static class PrivateClass {
    }

    // Does not matter; this class is not publicly visible
    public PrivateClass getPrivateClass() {
        return null;
    }
}

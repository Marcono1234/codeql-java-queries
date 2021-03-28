package otherrestrictedpackage;

import restrictedpackage.RestrictedClass;

public class OtherRestrictedClass {
    // Bad, exported to different module
    public RestrictedClass getRestrictedClass() {
        return null;
    }
}

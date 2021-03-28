package samerestrictedpackage;

import restrictedpackage.RestrictedClass;

public class SameRestrictedClass {
    // Correct, this package and other one are exported to same modules
    public RestrictedClass getRestrictedClass() {
        return null;
    }
}

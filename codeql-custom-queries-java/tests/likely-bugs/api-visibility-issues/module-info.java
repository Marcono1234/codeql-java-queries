module mypackage {
    exports mypackage;
    exports restrictedpackage to java.base;
    exports samerestrictedpackage to java.base;
    exports otherrestrictedpackage to java.compiler;
}

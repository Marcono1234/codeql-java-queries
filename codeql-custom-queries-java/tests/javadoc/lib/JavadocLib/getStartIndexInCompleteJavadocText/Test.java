class Test {
    /**
     * First line
     * second line
     * third line
     */
    int i;

    /** */
    int i2;

    // Does not work correctly for block tags due to https://github.com/github/codeql/issues/3825
    /**
     * First
     * @deprecated Deprecated1
     * Deprecated2
     */
    int i3;
}

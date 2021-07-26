class Test {
    static class Other { }
    static class OtherGeneric<T> { }

    static class Sub extends Test { }

    @Override
    public boolean equals(Object obj) {
        boolean bad[] = {
            obj instanceof Other,
            obj instanceof OtherGeneric<?>,
            obj.getClass() == Other.class
        };

        // These should not be reported
        boolean good[] = {
            // These should not be reported
            obj instanceof Sub,
            obj.getClass() == Sub.class,
            obj instanceof Object,
            obj.getClass() == Object.class
        };

        return false;
    }
}
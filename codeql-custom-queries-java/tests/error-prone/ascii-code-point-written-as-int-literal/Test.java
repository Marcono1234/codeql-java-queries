class Test {
    char[] chars = {61, 120}; // TODO: Currently not detected by CodeQL
    char c = (char) 40;

    char testPrimitive() {
        return 126;
    }

    Character testBoxed() {
        return 32;
    }

    char testPrimitiveCorrect() {
        return 'a';
    }

    Character testBoxedCorrect() {
        return 'B';
    }

    char testNonAscii() {
        char chars[] = {1, 31, 127, 65535};
        return 0;
    }
}
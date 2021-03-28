class Test {
    void test(String s) {
        boolean r;
        r = s.indexOf("substring") == -1;
        r = s.indexOf("substring") != -1;
        r = s.indexOf("substring") > -1;
        r = -1 < s.indexOf("substring");
        r = s.indexOf("substring") <= -1;
        r = -1 >= s.indexOf("substring");
        r = s.indexOf("substring") >= 0;
        r = 0 <= s.indexOf("substring");
        r = s.indexOf("substring") < 0;
        r = 0 > s.indexOf("substring");
        r = s.lastIndexOf("substring") == -1;
        r = s.lastIndexOf("substring") != -1;
        r = s.lastIndexOf("substring") > -1;
        r = s.lastIndexOf("substring") <= -1;
        r = s.lastIndexOf("substring") >= 0;
        r = s.lastIndexOf("substring") < 0;
    }

    void testCorrect(String s) {
        boolean r;
        // Use custom start index
        r = s.indexOf("substring", 1) == -1;
        r = s.lastIndexOf("substring", 1) == -1;
        // Check for code points
        r = s.indexOf('a') == -1;
        r = s.lastIndexOf('a') == -1;
        // Use different compared index
        r = s.indexOf("substring") != 5;
        r = s.indexOf("substring") > 0;
        r = s.indexOf("substring") <= 0;
    }
}
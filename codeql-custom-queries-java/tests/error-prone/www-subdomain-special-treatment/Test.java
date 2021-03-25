class Test {
    private static final String SUBDOMAIN = "www";
    
    void test(String domain) {
        if (domain.startsWith(SUBDOMAIN + ".")) {
        }

        // Match case-insensitively
        if (domain.startsWith("wWw.")) {
        }

        String r = domain.startsWith("www.") ? domain.substring(4) : domain;
    }

    void testCorrect(String domain) {
        // Period behind `www` is missing
        if (domain.startsWith(SUBDOMAIN)) {
        }

        // Should only match usage as part of condition, and not usage like this
        System.out.println("www.");

        // More than just the subdomain `www.`
        if (domain.startsWith("www.example.com/")) {
        }
    }
}
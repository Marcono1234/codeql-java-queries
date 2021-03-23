import java.io.Console;

class Test {
    Console console;

    void test() {
        System.out.println(console.readPassword().length);
        System.out.println(console.readPassword("Password:").length);
        System.out.println(console.readLine().trim());
        System.out.println(console.readLine("Line:").trim());

        String input = console.readLine();
        String s;
        if (true) {
            s = input;
        } else {
            s = "test";
        }
        System.out.println("Length: " + s.length());
        if (s == null) {
            System.out.println("Length: " + s.length());
        }
    }

    void testCorrect() {
        char[] password = console.readPassword();
        if (password != null) {
            System.out.println(password.length);
        }

        String input = console.readLine();
        String s;
        if (true) {
            s = input;
        } else {
            s = "test";
        }

        if (s == null) {
            System.out.println("Cancelled");
        } else {
            System.out.println("Length: " + s.length());
        }
    }
}
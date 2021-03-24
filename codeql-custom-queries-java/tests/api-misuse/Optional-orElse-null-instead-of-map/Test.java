import java.util.Optional;

class Test {
    void test(Optional<String> opt) {
        String temp;
        String result;

        temp = opt.orElse(null);
        result = temp == null ? "" : temp.trim();

        temp = opt.orElse(null);
        result = temp != null ? temp.trim() : "";
    }

    String testCorrect(Optional<String> opt) {
        String s = "test";
        String temp = opt.orElse(null);
        return temp == null ? "" : s.trim(); // Uses other variable
    }
}
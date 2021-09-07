/**
 * \uu1234
 * 
 * Single u:
 * \u1234
 * Escaped:
 * \\uu1234
 */
public class Test {
    String[] bad = {
        "\uuABCD",
    };

    String[] good = {
        "\uABCD",
        "\\uuABCD", // escaped
    };
}

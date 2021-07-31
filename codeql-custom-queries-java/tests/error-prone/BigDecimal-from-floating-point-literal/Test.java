import java.math.BigDecimal;
import java.math.MathContext;

class Test {
    void bad() {
        new BigDecimal(1.1f);
        new BigDecimal(1.1d);

        new BigDecimal(1.1f, MathContext.DECIMAL128);
        new BigDecimal(1.1d, MathContext.DECIMAL128);

        BigDecimal.valueOf(1.1f);
        BigDecimal.valueOf(1.1d);

        float f = 1.1f;
        new BigDecimal(f);

        double d = 1.1d;
        new BigDecimal(d);
    }

    public static final float CONST_F = 1.1f;
    public static final double CONST_D = 1.1d;

    void good(float f, double d) {
        new BigDecimal(f);
        new BigDecimal(d);

        float f1 = 1.1f;
        if (f > 0) {
            f1 = f;
        }
        // Should not be reported, value might come from parameter `f`
        new BigDecimal(f1);

        double d1 = 1.1d;
        if (d > 0) {
            d1 = d;
        }
        // Should not be reported, value might come from parameter `d`
        new BigDecimal(d1);

        // Should not report compile time constants from final fields, they might be used in other
        // other contexts as well and cannot simply be converted to String literals
        new BigDecimal(CONST_F);
        new BigDecimal(CONST_D);
    }
}
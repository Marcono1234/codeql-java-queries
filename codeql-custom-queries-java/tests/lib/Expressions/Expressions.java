import java.util.function.Supplier;

class Expressions {
    void test() {
        toString();
        // LocalVariableDeclarationStatement with init
        String s = toString();
        int i;
        i = 0;
        i++;
        new Object();
        // ArrayCreationExpression cannot be a StatementExpression, but a method access
        // on it can be
        new int[] {}.clone();

        // StatementExpressions
        for (int i1 = 0; i1 < 10; i1++) { }
        for (;;) {
            doSomething();
        }

        // Not a StatementExpression
        for (int i2 : new int[] {1}) { }

        switch(1) {
            default -> toString(); // StatementExpression
        }
        // SwitchExpression has no StatementExpression
        String s2 = switch(1) {
            default -> toString();
        };

        // Lambda with non-void return type has no StatementExpression
        Supplier<Object> supplier1 = () -> toString();
        // Lambda with void return type has StatementExpression
        Runnable r = () -> toString();

        // Method reference with non-void return type has no StatementExpression
        Supplier<Object> supplier2 = Expressions::new;
        // Implicit method of method reference contains StatementExpression
        // TODO: Missing, not sure why. Workaround in StmtExpr should cover this
        Runnable r2 = this::toString;
    }

    void doSomething() { }
}
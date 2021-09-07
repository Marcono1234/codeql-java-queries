package StmtExpr;

import java.util.function.Supplier;

class StmtExpr {
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
            break;
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
        Supplier<Object> supplier2 = () -> {
            return toString();
        };
        // Lambda with void return type has StatementExpression
        Runnable r = () -> toString();
        Runnable r2 = () -> {
            toString();
        };

        // Method reference with non-void return type has no StatementExpression
        Supplier<Object> supplier3 = StmtExpr::new;
        // Implicit method of method reference contains StatementExpression
        Runnable r3 = this::toString;
    }

    void doSomething() { }
}
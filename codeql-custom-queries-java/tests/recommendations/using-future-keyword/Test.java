// Only `_` is a keyword in Java 9, other ones are restricted identifiers which
// are allowed as part of package name
package var.yield.record._.Var.Yield.Record._a;

class Test {
    class _ { }
    class var { }
    class yield { }
    class record { }
    interface TypeVars<_, var, yield, record> {
        <_, var, yield, record> void test();
    }

    // Only `_` is a keyword in Java 9, other ones are restricted identifiers which
    // are allowed as field names
    int _;
    int __;
    int var;
    int yield;
    int record;

    interface Methods {
        void _();
        // Only `_` is a keyword in Java 9, other ones are restricted identifiers which
        // are allowed as parameter names
        void test(int _, int __, int var, int yield, int record);

        // Declaration is allowed, only usage without qualifier is not
        void yield();
    }

    // Allowed
    class _A { }
    class __ { }
    class Var { }
    class Yield { }
    class Record { }
}
import java.util.Comparator;

class Test {
    interface Compared {
        byte getByte();
        short getShort();
        char getChar();
        int getInt();
        long getLong();
        float getFloat();
        double getDouble();

        boolean getBoolean();
        Integer getBoxedInteger();
    }

    void testMethodRef() {
        Comparator<Compared> c;
        c = Comparator.comparing(Compared::getByte);
        c = c.thenComparing(Compared::getByte);

        c = Comparator.comparing(Compared::getShort);
        c = c.thenComparing(Compared::getShort);

        c = Comparator.comparing(Compared::getChar);
        c = c.thenComparing(Compared::getChar);

        c = Comparator.comparing(Compared::getInt);
        c = c.thenComparing(Compared::getInt);

        c = Comparator.comparing(Compared::getLong);
        c = c.thenComparing(Compared::getLong);

        c = Comparator.comparing(Compared::getFloat);
        c = c.thenComparing(Compared::getFloat);

        c = Comparator.comparing(Compared::getDouble);
        c = c.thenComparing(Compared::getDouble);

        // These should not be reported
        c = Comparator.comparing(Compared::getBoolean);
        c = c.thenComparing(Compared::getBoolean);

        c = Comparator.comparing(Compared::getBoxedInteger);
        c = c.thenComparing(Compared::getBoxedInteger);

        c = Comparator.comparingInt(Compared::getInt);
        c = c.thenComparingInt(Compared::getInt);
    }

    void testLambda() {
        Comparator<Compared> c;
        c = Comparator.comparing(o -> o.getByte());
        c = Comparator.comparing(o -> {
            int add = o.getInt();
            return o.getByte() + add;
        });
        c = Comparator.comparing(o -> {
            if (o.getBoolean()) {
                return (int) o.getByte();
            } else {
                return o.getInt();
            }
        });
        c = c.thenComparing(o -> o.getByte());
        c = c.thenComparing(o -> {
            int add = o.getInt();
            return o.getByte() + add;
        });
        c = c.thenComparing(o -> {
            if (o.getBoolean()) {
                return (int) o.getByte();
            } else {
                return o.getInt();
            }
        });

        c = Comparator.comparing(o -> o.getShort());
        c = c.thenComparing(o -> o.getShort());

        c = Comparator.comparing(o -> o.getChar());
        c = c.thenComparing(o -> o.getChar());

        c = Comparator.comparing(o -> o.getInt());
        c = c.thenComparing(o -> o.getInt());

        c = Comparator.comparing(o -> o.getLong());
        c = c.thenComparing(o -> o.getLong());

        c = Comparator.comparing(o -> o.getFloat());
        c = c.thenComparing(o -> o.getFloat());

        c = Comparator.comparing(o -> o.getDouble());
        c = c.thenComparing(o -> o.getDouble());

        // These should not be reported
        c = Comparator.comparing(o -> o.getBoolean());
        c = c.thenComparing(o -> o.getBoolean());

        c = Comparator.comparing(o -> o.getBoxedInteger());
        c = c.thenComparing(o -> o.getBoxedInteger());
        c = Comparator.comparing(o -> {
            int r = o.getInt();
            if (r > 0) {
                return r;
            } else {
                return o.getBoxedInteger();
            }
        });
        c = c.thenComparing(o -> {
            int r = o.getInt();
            if (r > 0) {
                return r;
            } else {
                return o.getBoxedInteger();
            }
        });

        c = Comparator.comparingInt(o -> o.getInt());
        c = c.thenComparingInt(o -> o.getInt());
    }
}

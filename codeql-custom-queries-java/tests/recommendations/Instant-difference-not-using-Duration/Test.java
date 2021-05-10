import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;

class Test {
    void test(Instant start, Instant now) {
        boolean b;
        b = start.minus(1, ChronoUnit.DAYS).isAfter(now);
        b = start.minus(Duration.ofDays(1)).isAfter(now);
        b = start.minusMillis(200).isAfter(now);
        b = start.minusNanos(1000).isAfter(now);
        b = start.minusSeconds(5).isAfter(now);
        b = start.minusSeconds(5).isBefore(now);
        b = start.minusSeconds(5).compareTo(now) < 0;

        b = start.plus(1, ChronoUnit.DAYS).isAfter(now);
        b = start.plus(Duration.ofDays(1)).isAfter(now);
        b = start.plusMillis(200).isAfter(now);
        b = start.plusNanos(1000).isAfter(now);
        b = start.plusSeconds(5).isAfter(now);
        b = start.plusSeconds(5).isBefore(now);
        b = start.plusSeconds(5).compareTo(now) < 0;
    }

    void testSub(Instant start, Instant end) {
        long r;
        r = end.getEpochSecond() - start.getEpochSecond();
        r = end.toEpochMilli() - start.toEpochMilli();
    }
}
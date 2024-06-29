/**
 * Finds duration constants which can be simplified to increase readability.
 *
 * For example `Duration.ofSeconds(3600)` could be written as `Duration.ofHours(1)` instead.
 *
 * This query was inspired by [this Guava commit](https://github.com/google/guava/commit/9ea68165fcb78aace43a7b80b0a0e77c7327789b).
 *
 * @kind problem
 * @id todo
 */

import java

newtype TDurationUnit =
  TDurationNanos() or
  TDurationMicros() or
  TDurationMillis() or
  TDurationSeconds() or
  TDurationMinutes() or
  TDurationHours() or
  TDurationDays()

abstract class DurationUnit extends TDurationUnit {
  /** Gets the name of the corresponding `java.util.concurrent.TimeUnit` constant. */
  abstract string getTimeUnitName();

  /** Gets the name of the corresponding `java.time.Duration` method, if any. */
  abstract string getDurationMethodName();

  string toString() { result = getTimeUnitName() }

  /** Gets the next higher unit, if any. */
  abstract DurationUnit getHigherUnit();

  /** Gets the multiplication factor to the next higher unit, if any. */
  abstract int getHigherUnitFactor();

  int getFactorTo(DurationUnit higherUnit) {
    if higherUnit = this
    then result = 1
    else result = getHigherUnitFactor() * getHigherUnit().getFactorTo(higherUnit)
  }
}

class DurationNanos extends DurationUnit, TDurationNanos {
  override string getTimeUnitName() { result = "NANOSECONDS" }

  override string getDurationMethodName() { result = "ofNanos" }

  override DurationUnit getHigherUnit() { result instanceof DurationMicros }

  override int getHigherUnitFactor() { result = 1000 }
}

class DurationMicros extends DurationUnit, TDurationMicros {
  override string getTimeUnitName() { result = "MICROSECONDS" }

  override string getDurationMethodName() {
    // Has no `Duration` method
    none()
  }

  override DurationUnit getHigherUnit() { result instanceof DurationMillis }

  override int getHigherUnitFactor() { result = 1000 }
}

class DurationMillis extends DurationUnit, TDurationMillis {
  override string getTimeUnitName() { result = "MILLISECONDS" }

  override string getDurationMethodName() { result = "ofMillis" }

  override DurationUnit getHigherUnit() { result instanceof DurationSeconds }

  override int getHigherUnitFactor() { result = 1000 }
}

class DurationSeconds extends DurationUnit, TDurationSeconds {
  override string getTimeUnitName() { result = "SECONDS" }

  override string getDurationMethodName() { result = "ofSeconds" }

  override DurationUnit getHigherUnit() { result instanceof DurationMinutes }

  override int getHigherUnitFactor() { result = 60 }
}

class DurationMinutes extends DurationUnit, TDurationMinutes {
  override string getTimeUnitName() { result = "MINUTES" }

  override string getDurationMethodName() { result = "ofMinutes" }

  override DurationUnit getHigherUnit() { result instanceof DurationHours }

  override int getHigherUnitFactor() { result = 60 }
}

class DurationHours extends DurationUnit, TDurationHours {
  override string getTimeUnitName() { result = "HOURS" }

  override string getDurationMethodName() { result = "ofHours" }

  override DurationUnit getHigherUnit() { result instanceof DurationDays }

  override int getHigherUnitFactor() { result = 24 }
}

class DurationDays extends DurationUnit, TDurationDays {
  override string getTimeUnitName() { result = "DAYS" }

  override string getDurationMethodName() { result = "ofDays" }

  override DurationUnit getHigherUnit() { none() }

  override int getHigherUnitFactor() { none() }
}

bindingset[value, divisor]
int divExact(int value, int divisor) {
  result = value / divisor and
  value % divisor = 0
}

bindingset[valueIn]
predicate simplifyDuration(DurationUnit unitIn, int valueIn, DurationUnit unitOut, int valueOut) {
  unitOut = unitIn.getHigherUnit+() and
  valueOut = divExact(valueIn, unitIn.getFactorTo(unitOut))
}

class TypeTimeUnit extends Class {
  TypeTimeUnit() { hasQualifiedName("java.util.concurrent", "TimeUnit") }
}

bindingset[declaringType, callableName, valueParamIndex, timeUnitParamIndex]
predicate isTimeUnitParam(
  string declaringType, string callableName, int valueParamIndex, int timeUnitParamIndex
) {
  exists(string s |
    s =
      [
        "java.util.concurrent.TimeUnit,convert,0,1",
        "java.lang.Process,waitFor,0,1",
        "java.nio.channels.AsynchronousChannelGroup,awaitTermination,0,1",
        "java.nio.channels.AsynchronousSocketChannel,read,1,2",
        "java.nio.channels.AsynchronousSocketChannel,read,3,4",
        "java.nio.channels.AsynchronousSocketChannel,write,1,2",
        "java.nio.channels.AsynchronousSocketChannel,write,3,4",
        "java.nio.file.WatchService,poll,0,1",
        "java.nio.file.attribute.FileTime,from,0,1",
        "javax.swing.SwingWorker,get,0,1",
      ]
  |
    declaringType = s.splitAt(",", 0) and
    callableName = s.splitAt(",", 1) and
    valueParamIndex = s.splitAt(",", 2).toInt() and
    timeUnitParamIndex = s.splitAt(",", 3).toInt()
  )
  or
  // For simplicity don't list them all individually (maybe have to do that if this here is too errorprone)
  declaringType.matches("java.util.concurrent.%") and
  valueParamIndex + 1 = timeUnitParamIndex and
  // Ignore methods where time unit applies to multiple time values (and therefore would have to check
  // if all of the values can be simplified)
  not callableName = ["scheduleAtFixedRate", "scheduleWithFixedDelay"]
}

Callable getAnOverridden(Callable callable) {
  result = callable.getSourceDeclaration() or
  callable.(Method).getASourceOverriddenMethod+() = result
}

/** Simplifiable usage of `java.util.concurrent.TimeUnit` */
predicate simplifiableTimeUnitUsage(IntegerLiteral durationValueExpr, DurationUnit unitIn) {
  exists(EnumConstant unitConstant |
    unitConstant.getDeclaringType() instanceof TypeTimeUnit and
    unitConstant.getName() = unitIn.getTimeUnitName()
  |
    // Calling `to...` method on TimeUnit constant, e.g. `TimeUnit.SECONDS.toMinutes(60)`
    exists(MethodAccess call, Method m |
      m = call.getMethod() and
      m.getDeclaringType() instanceof TypeTimeUnit
    |
      m.getName().matches("to%") and
      m.getParameterType(0).hasName("long") and
      m.getReturnType().hasName("long") and
      call.getQualifier().(FieldRead).getField() = unitConstant and
      durationValueExpr = call.getArgument(0)
    )
    or
    // Calling callable with `value, timeUnit` args, e.g. `timeUnit.convert(60, TimeUnit.SECONDS)`
    exists(Call call, Callable callee, int valueParamIndex, int timeUnitParamIndex |
      callee = call.getCallee() and
      isTimeUnitParam(getAnOverridden(callee).getDeclaringType().getQualifiedName(),
        callee.getName(), valueParamIndex, timeUnitParamIndex) and
      call.getArgument(timeUnitParamIndex).(FieldRead).getField() = unitConstant and
      durationValueExpr = call.getArgument(valueParamIndex)
    )
  )
}

/** Simplifiable usage of `java.time.Duration` */
predicate simplifiableDurationUsage(IntegerLiteral durationValueExpr, DurationUnit unitIn) {
  exists(MethodAccess call, Method m |
    m = call.getMethod() and
    m.getDeclaringType().hasQualifiedName("java.time", "Duration")
  |
    m.getName() = unitIn.getDurationMethodName() and
    // Ignore `ofSeconds(seconds, nanos)` overload and any other future overloads
    m.getNumberOfParameters() = 1 and
    durationValueExpr = call.getArgument(0)
  )
}

from
  IntegerLiteral durationValueExpr, DurationUnit unitIn, int valueIn, DurationUnit unitOut,
  int valueOut, string suggestion
where
  (
    simplifiableTimeUnitUsage(durationValueExpr, unitIn) and
    suggestion = valueOut + " " + unitOut.getTimeUnitName()
    or
    simplifiableDurationUsage(durationValueExpr, unitIn) and
    suggestion = unitOut.getDurationMethodName() + "(" + valueOut + ")"
  ) and
  valueIn = durationValueExpr.getIntValue() and
  // Don't try to 'simplify' duration of 0
  valueIn != 0 and
  simplifyDuration(unitIn, valueIn, unitOut, valueOut)
select durationValueExpr, "Should use instead: " + suggestion

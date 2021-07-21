/**
 * Finds usage of `Float.MIN_VALUE` and `Double.MIN_VALUE`. Unlike the fields with the same name
 * of the integral wrapper classes, such as `Integer.MIN_VALUE`, whose value is the largest
 * negative value the data type can have, `Float` and `Double` `MIN_VALUE` is the positive,
 * non-zero value closest to 0.
 * 
 * Therefore `Float` and `Double` `MIN_VALUE` is only rarely useful. If a value representing
 * the largest negative value is desired, either `-MAX_VALUE` or `NEGATIVE_INFINITY` should
 * be used.
 * 
 * This query is based on [Java Puzzlers, Strange Loop Edition](https://youtu.be/qRTIpyd_snc?t=1974).
 */

import java

from FieldRead fieldRead, Field f
where
  f = fieldRead.getField()
  and f.getDeclaringType().hasQualifiedName("java.lang", ["Float", "Double"])
  and f.hasName("MIN_VALUE")
select fieldRead, "Usage of floating point MIN_VALUE"

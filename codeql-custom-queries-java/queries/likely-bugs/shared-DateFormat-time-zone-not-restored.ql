/**
 * Finds usage of cached `DateFormat` (or `SimpleDateFormat`) instances for parsing dates,
 * but for which the `DateFormat` is not properly reset after parsing. Parsing can have an
 * effect on some fields of the `DateFormat`, most notably it can change the time zone.
 * 
 * In general prefer the classes from the `java.time` package (added in Java 8), such as
 * [`DateTimeFormatter`](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/time/format/DateTimeFormatter.html)
 * or use the `parse` methods such as `ZonedDateTime.parse`.
 * 
 * See
 * - [`DateFormat.parse`](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/text/DateFormat.html#parse(java.lang.String,java.text.ParsePosition))
 * - [Tomcat issue](https://bz.apache.org/bugzilla/show_bug.cgi?id=64226) caused by this behavior
 * 
 * @kind problem
 */

/*
 * TODO:
 * - Maybe extend this to cover more cases of shared DateFormat instances, e.g. usage of Queue (used by Tomcat)
 * - Maybe reduce false positives by making sure date pattern supports time zone (verify that this is required for this issue)
 */

import java
import semmle.code.java.dataflow.DataFlow

class ThreadLocalType extends Class {
    ThreadLocalType() {
        getSourceDeclaration().getASourceSupertype*().hasQualifiedName("java.lang", "ThreadLocal")
    }
}

class DateFormatType extends Class {
    DateFormatType() {
        getSourceDeclaration().getASourceSupertype*().hasQualifiedName("java.text", "DateFormat")
    }
}

from MethodAccess threadLocalGet, MethodAccess parseCall
where
    threadLocalGet.getQualifier().getType() instanceof ThreadLocalType
    and threadLocalGet.getMethod().hasStringSignature("get()")
    and threadLocalGet.getType() instanceof DateFormatType
    and parseCall.getMethod().getName().matches("parse%")
    and DataFlow::localExprFlow(threadLocalGet, parseCall.getQualifier())
    // And time zone is not restored (or set before parse is called)
    // Note: Might also affect data? Documentation says other fields of `calendar` might be overwritten as well
    and not exists(MethodAccess setTimeZoneCall |
        setTimeZoneCall.getMethod().hasName("setTimeZone")
        and DataFlow::localExprFlow(threadLocalGet, setTimeZoneCall.getQualifier())
    )
select threadLocalGet, "Time zone of this shared DateFormat is not restored after parsing"

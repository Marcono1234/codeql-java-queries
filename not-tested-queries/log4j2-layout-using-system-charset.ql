/**
 * Finds Log4j2 XML configuration files which use a layout, which by default uses
 * the system charset, for a non-console appender. Especially under Windows the
 * system charset often does not support all Unicode characters so the logged
 * messages might include a `?` instead of the actual character, losing information.
 * This can be especially problematic if the log is used for security purposes.
 */

import java

class Log4j2ConfigFile extends XMLFile {
    Log4j2ConfigFile() {
        // https://logging.apache.org/log4j/2.x/manual/configuration.html#AutomaticConfiguration
        getBaseName() = ["log4j2-test.xml", "log4j2.xml"]
    }
    
    ConfigurationElement getConfiguration() {
        result = getAChild()
    }
}

// https://logging.apache.org/log4j/2.x/manual/configuration.html#XML

class ConfigurationElement extends XMLElement {
    ConfigurationElement() {
        hasName("Configuration")
    }
    
    AppendersElement getAppenders() {
        result = getAChild()
    }
}

class AppendersElement extends XMLElement {
    AppendersElement() {
        hasName("Appenders")
    }
    
    NonConsoleAppenderElement getNonConsoleAppender() {
        result = getAChild()
    }
}

// For everything other than Console appender, using system charset is likely undesired
class NonConsoleAppenderElement extends XMLElement {
    NonConsoleAppenderElement() {
        // Strict XML
        if hasName("Appender") then (
            getAttributeValue("type") != "Console"
        ) else not hasName("Console")
    }
    
    SystemCharsetUsingLayoutElement getLayout() {
        result = getAChild()
    }
}

// https://logging.apache.org/log4j/2.x/manual/layouts.html
class SystemCharsetUsingLayoutElement extends XMLElement {
    SystemCharsetUsingLayoutElement() {
        (
            hasName(["PatternLayout", "Rfc5424Layout"])
            // Strict XML
            or (
                hasName("Layout")
                and getAttributeValue("type") = ["PatternLayout", "Rfc5424Layout"]
            )
        )
        // Does not explicitly specify charset
        and not hasAttribute("charset")
    }
}

from Log4j2ConfigFile log4jConfig, SystemCharsetUsingLayoutElement layoutElement
where
    layoutElement = log4jConfig.getConfiguration().getAppenders().getNonConsoleAppender().getLayout()
select layoutElement, "Layout uses system charset by default and does not specify explicit `charset`."

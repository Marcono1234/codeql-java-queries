import semmle.code.xml.MavenPom

/**
 * A `build` element of a Maven POM.
 */
class BuildElement extends PomElement {
    BuildElement() {
        exists(Pom pom |
            this = pom.getAChild("build")
            or this = pom.getAChild("profiles").getAChild("profile").getAChild("build")
        )
    }
}

/**
 * A `plugins` element of a Maven POM.
 */
class PluginsElement extends PomElement {
    PluginsElement() {
        exists(BuildElement buildElement |
            this = buildElement.getAChild("plugins")
            or this = buildElement.getAChild("pluginManagement").getAChild("plugins")
        )
    }
}

/**
 * A `plugin` element of a Maven POM specifying a test plugin.
 */
class TestPluginElement extends PomElement {
    TestPluginElement() {
        exists(PluginsElement pluginsElement |
            this = pluginsElement.getAChild("plugin")
            // groupId is optional because it has a default value in the XSD (see https://stackoverflow.com/a/65533111)
            and (exists(getAChild("groupId")) implies getAChild("groupId").getTextValue() = "org.apache.maven.plugins")
            and getAChild("artifactId").getTextValue() = ["maven-surefire-plugin", "maven-failsafe-plugin"]
        )
    }
}

/**
 * A `configuration` element of a Maven POM specifying the configuration for a
 * test plugin.
 */
class TestPluginConfigElement extends PomElement {
    TestPluginConfigElement() {
        exists(TestPluginElement testPluginElement |
            // Configuration for all goals
            this = testPluginElement.getAChild("configuration")
            // Or configuration for specific goals
            or this = testPluginElement.getAChild("executions").getAChild("execution").getAChild("configuration")
        )
    }

    /**
     * Gets a configuration element specifying that tests should be skipped.
     */
    PomElement getASkippingElement() {
        // Surefire and Failsafe plugin
        result = getAChild([
            "skip",
            "skipExec",
            "skipITs", // Failsafe plugin
            "skipTests"
        ])
        and getValue() = "true"
    }

    /**
     * Gets a configuration element specifying that test results should be ignored.
     */
    PomElement getAResultIgnoringElement() {
        // Surefire and Failsafe plugin
        result = getAChild("testFailureIgnore")
        and result.getValue() = "true"
    }

    /**
     * Gets a configuration element which restricts which test classes should be executed,
     * e.g. by defining exclusions or defining that only certain tests should be executed.
     */
    XMLElement getARestrictingElement() {
        // Surefire and Failsafe plugin
        // Ignore `includes` since that is most likely used to correctly specify test file patterns
        result = getAChild([
            "excludedGroups", // Unit testing framework might not provide better / easier alternatives?
            "excludes",
            "excludesFile",
            "groups", // Unit testing framework might not provide better / easier alternatives?
            "test" // User should use includes and excludes instead?
        ])
    }
}


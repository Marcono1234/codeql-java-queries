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
 * A `plugin` element of a Maven POM.
 */
class PluginElement extends ProtoPom {
    PluginElement() {
        any(PluginsElement e).getAChild("plugin") = this
    }

    /**
     * Gets the effective `groupId` of this plugin declaration.
     */
    string getEffectiveGroupId() {
        if exists(getGroup()) then result = getGroup().getTextValue()
        // groupId is optional because it has a default value in the XSD (see https://stackoverflow.com/a/65533111)
        else result = "org.apache.maven.plugins"
    }

    predicate hasEffectiveCoordinates(string groupId, string artifactId) {
        getEffectiveGroupId() = groupId
        and getArtifact().getTextValue() = artifactId
    }

    /**
     * Gets a `configuration` element of this plugin; either the global configuration
     * or an execution specific configuration.
     */
    PomElement getAConfigElement() {
        // Configuration for all executions
        result = getAChild("configuration")
        // Or configuration for specific execution
        or result = getAChild("executions").getAChild("execution").getAChild("configuration")
    }
}

/**
 * A `plugin` element of a Maven POM specifying a test plugin.
 */
class TestPluginElement extends PluginElement {
    TestPluginElement() {
        hasEffectiveCoordinates("org.apache.maven.plugins", ["maven-surefire-plugin", "maven-failsafe-plugin"])
    }
}

/**
 * A `configuration` element of a Maven POM specifying the configuration for a
 * test plugin.
 */
class TestPluginConfigElement extends PomElement {
    TestPluginConfigElement() {
        this = any(TestPluginElement e).getAConfigElement()
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

/**
 * A `plugin` element of a Maven POM specifying the Maven Shade Plugin.
 */
class ShadePluginElement extends PluginElement {
    ShadePluginElement() {
        hasEffectiveCoordinates("org.apache.maven.plugins", "maven-shade-plugin")
    }
}

/**
 * A shade plugin transformer declaration.
 */
class ShadeTransformerElement extends PomElement {
    ShadeTransformerElement() {
        this = any(PluginElement e).getAConfigElement().getAChild("transformers").getAChild("transformer")
    }

    string getTransformerImplementationName() {
        result = getAttributeValue("implementation")
    }
}

/**
 * A shade plugin transformer declaration of type `ManifestResourceTransformer`.
 */
class ShadeManifestTransformerElement extends ShadeTransformerElement {
    ShadeManifestTransformerElement() {
        getTransformerImplementationName() = "org.apache.maven.plugins.shade.resource.ManifestResourceTransformer"
    }

    /**
     * Gets an element specifying the main class.
     */
    PomElement getAMainClassElement() {
        // See https://maven.apache.org/plugins/maven-shade-plugin/examples/executable-jar.html
        result = getAChild("mainClass")
        or result = getAChild("manifestEntries").getAChild("Main-Class")
    }
}

/**
 * A `plugin` element of a Maven POM specifying the Maven JAR Plugin.
 */
class JarPluginElement extends PluginElement {
    JarPluginElement() {
        hasEffectiveCoordinates("org.apache.maven.plugins", "maven-jar-plugin")
    }

    PomElement getAnArchiveConfig() {
        result = getAConfigElement().getAChild("archive")
    }

    /**
     * Gets an element of any of the archive configurations specifying the main class.
     */
    PomElement getAMainClassElement() {
        // See https://maven.apache.org/shared/maven-archiver/index.html
        result = getAnArchiveConfig().getAChild("manifest").getAChild("mainClass")
        or result = getAnArchiveConfig().getAChild("manifestEntries").getAChild("Main-Class")
    }
}

/**
 * An element which specifies the main class.
 */
class MainClassElement extends PomElement {
    MainClassElement() {
        this = any(ShadeManifestTransformerElement e).getAMainClassElement()
        or this = any(JarPluginElement e).getAMainClassElement()
    }
}

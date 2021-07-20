/**
 * Finds version requirements in a Maven POM which use a range without upper version bound.
 * This could lead to non-reproducible builds because new versions of dependencies or
 * plugins might be released between builds.
 */

// See https://maven.apache.org/pom.html#Dependency_Version_Requirement_Specification

import java
import semmle.code.xml.MavenPom
import lib.MavenLib

from Version version, string versionString
where
    // Restrict `version` element to reduce false positives; e.g. maven-enforcer-plugin has an
    // unrelated `version` element for its configuration
    // Note: Plugins don't actually seem to support version ranges, see for example
    // https://issues.apache.org/jira/browse/MNG-3799, but cover them nonetheless
    version = [any(Dependency d).getVersion(), any(PluginElement e).getVersion()]
    and versionString = version.getValue()
    // Only consider range without upper bound; version without lower bound is fine (assuming that upper
    // bound references existing version)
    and versionString.regexpMatch(".*,[\\])]")
select version, "Specifies version '" + versionString + "' without upper bound"

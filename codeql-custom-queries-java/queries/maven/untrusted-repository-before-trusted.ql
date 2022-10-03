/**
 * Finds repository declarations in Maven POM files which first list untrusted or little-known
 * repositories before (implicitly) listing trusted repositories such as Maven Central.
 * 
 * The order in which the repositories are declared will be used by Maven to look up dependencies
 * and plugins, see Maven guide "[Using Multiple Repositories](https://maven.apache.org/guides/mini/guide-multiple-repositories.html#repository-order)".
 * It is therefore important to make sure Maven uses the correct repository for downloading
 * a dependencies or plugin to avoid a "dependency confusion" attack. Well-curated repositories
 * should be listed first to make sure no adversary can publish an artifact to that repository
 * with the coordinates of an existing artifact from another repository.
 * 
 * See also:
 * - Blog post "[A Confusing Dependency](https://blog.autsoft.hu/a-confusing-dependency/)" by Márton Braun
 * - Blog post "[Dependency Confusion](https://medium.com/@alex.birsan/dependency-confusion-4a5d60fec610)" by Alex Birsan
 */

import java
import semmle.code.xml.MavenPom

class Repository extends DeclaredRepository {
    Repository() {
        // Ignore repository declaration for `distributionManagement`
        not getParent().(XmlElement).hasName("distributionManagement")
    }

    /** Holds if this declared repository is used for downloading release artifacts. */
    predicate servesReleases() {
        // Either implicitly or explicitly enabled
        not exists(getAChild("releases").getAChild("enabled"))
        or getAChild("releases").getAChild("enabled").(PomElement).getValue() = "true"
    }

    /** Holds if this declared repository is used for downloading snapshot artifacts. */
    predicate servesSnapshots() {
        // Either implicitly or explicitly enabled
        not exists(getAChild("snapshots").getAChild("enabled"))
        or getAChild("snapshots").getAChild("enabled").(PomElement).getValue() = "true"
    }
}

bindingset[url]
predicate isTrustedRepository(string url) {
    // Check prefix of URL
    url.indexOf([
        "https://repo1.maven.org/",
        "https://repo.maven.apache.org/",
        "https://oss.sonatype.org/",
        // Local `file` URI
        "file://",
        // Repositories synchronized with Central, see https://central.sonatype.org/publish/large-orgs/#large-organizationsforges-repository-sync
        "https://repository.jboss.org",
        "https://repository.apache.org/",
        "https://maven.java.net/"
    ]) = 0
}

// Note: Could possibly avoid false positives by ignoring declared repositories when custom inheritance settings
// are used (though likely rather rare), see https://maven.apache.org/pom.html#advanced_configuration_inheritance

from Repository repo, string url
where
    url = repo.getRepositoryUrl()
    and not isTrustedRepository(url)
    and (
        // Check if there is no preceding trusted repository serving the same kind of artifacts (releases or snapshots)
        (
            repo.servesReleases()
            and not exists(Repository trustedRepo |
                trustedRepo.getParent() = repo.getParent()
                and trustedRepo.getIndex() < repo.getIndex()
                and trustedRepo.servesReleases()
                and isTrustedRepository(trustedRepo.getRepositoryUrl())
            )
        )
        or (
            repo.servesSnapshots()
            and not exists(Repository trustedRepo |
                trustedRepo.getParent() = repo.getParent()
                and trustedRepo.getIndex() < repo.getIndex()
                and trustedRepo.servesSnapshots()
                and isTrustedRepository(trustedRepo.getRepositoryUrl())
            )
        )
    )
select repo, "Repository '" + url + "' is not preceded by trusted repository"

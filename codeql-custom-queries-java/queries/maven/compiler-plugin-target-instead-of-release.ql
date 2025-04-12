/**
 * Finds configurations of the Maven Compiler Plugin which use `<source>` and `<target>`
 * instead of `<release>`. When building with JDK >= 9 (regardless of `<target>` version)
 * the `<release>` parameter should be preferred because it additionally ensures that
 * only API of that release is used, and not accidentally newer API when building with
 * a newer JDK (but targeting an older version).
 *
 * See also the [Maven Compiler Plugin documentation](https://maven.apache.org/plugins/maven-compiler-plugin/examples/set-compiler-release.html).
 *
 * @kind problem
 * @id TODO
 */

import java
import lib.MavenLib

class CompilerPluginElement extends PluginElement {
  CompilerPluginElement() {
    hasEffectiveCoordinates("org.apache.maven.plugins", "maven-compiler-plugin")
  }
}

from PomElement reportedElement, int targetVersion, string replacement
where
  (
    // Parameter in plugin configuration
    // TODO: Corrently does not work because this project here uses too old codeql Java library which contains
    //   bug regarding `<target>` handling, see https://github.com/github/codeql/pull/15923/files#r2040662871
    exists(
      CompilerPluginElement compilerPlugin, PomElement configElement, PomElement targetElement,
      string elementName, string replacementName
    |
      reportedElement = targetElement and
      (
        elementName = "target" and replacementName = "release"
        or
        // Or `<testTarget>` for 'testCompile' goal
        elementName = "testTarget" and replacementName = "testRelease"
      )
    |
      configElement = compilerPlugin.getAConfigElement() and
      targetElement = configElement.getAChild(elementName) and
      targetVersion = targetElement.getValue().toInt() and
      replacement = "`<" + replacementName + ">" + targetVersion + "</" + replacementName + ">`" and
      // And config does not additionally define 'release' parameter as well
      // (Note that in newer versions of the Maven Compiler Plugin, this will likely lead to a javac error,
      // see https://github.com/apache/maven-compiler-plugin/pull/271)
      not exists(configElement.getAChild(replacementName))
    )
    or
    // Or property setting plugin parameter value
    exists(Pom pom, PomProperty targetProperty, string propertyName, string replacementName |
      reportedElement = targetProperty and
      (
        propertyName = "maven.compiler.target" and replacementName = "maven.compiler.release"
        or
        // Or `<maven.compiler.testTarget>` for 'testCompile' goal
        propertyName = "maven.compiler.testTarget" and
        replacementName = "maven.compiler.testRelease"
      )
    |
      targetProperty = pom.getALocalProperty() and
      targetProperty.hasName(propertyName) and
      targetVersion = targetProperty.getValue().toInt() and
      replacement = "`<" + replacementName + ">" + targetVersion + "</" + replacementName + ">`" and
      // And properties do not additionally define 'release' property as well
      not pom.getALocalProperty().hasName(replacementName)
    )
  ) and
  // If target is >= 9, then JDK must also be >= 9 and therefore supports `javac --release`
  targetVersion >= 9
select reportedElement, "Should instead use " + replacement

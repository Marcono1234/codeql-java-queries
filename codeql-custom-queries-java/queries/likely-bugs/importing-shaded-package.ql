/**
 * Finds import statements which import a package containing apparently classes
 * shaded / repackaged from another artifact. Such shaded classes are often
 * part of the implementation details and should not be used directly. Instead
 * the official classes should be used.
 *
 * For example:
 * ```java
 * import org.example.shaded.com.google.common.base.Strings;
 * // should instead import the official class:
 * import com.google.common.base.Strings;
 * ```
 *
 * @kind problem
 */

// Related to own `using-class-from-internal-package.ql` query

import java

Package getPackage(Import importStmt) {
  result =
    [
      importStmt.(ImportOnDemandFromPackage).getPackageHoldingImport(),
      importStmt.(ImportOnDemandFromType).getTypeHoldingImport().getPackage(),
      importStmt.(ImportStaticOnDemand).getTypeHoldingImport().getPackage(),
      importStmt.(ImportStaticTypeMember).getTypeHoldingImport().getPackage(),
      importStmt.(ImportType).getImportedType().getPackage(),
    ]
}

// Only consider import statements; ignore if fully qualified name is used within class
from Import importStmt, Package package, string shadedPackagePrefix
where
  package = getPackage(importStmt) and
  exists(string packageName, int index |
    packageName = package.getName() and
    // `shadow` is the default prefix of the Shadow Gradle plugin (https://github.com/johnrengelman/shadow)
    exists(packageName.regexpFind("((^|\\.)(shaded|repackaged)($|\\.))|(^shadow\\.)", 0, index)) and
    shadedPackagePrefix = packageName.prefix(index)
  ) and
  // And shaded classes are not somehow part of the sources
  not package.fromSource() and
  // And package is not shaded by the project itself, i.e. shaded package has same prefix
  // as other classes of project
  not exists(Package p | p.getName() = shadedPackagePrefix and p.fromSource())
select importStmt, "Imports shaded package"

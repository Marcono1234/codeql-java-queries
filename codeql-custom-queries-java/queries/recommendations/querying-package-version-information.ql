/**
 * Finds calls to `java.lang.Package` methods which query specification or implementation
 * version information, such as the method `getImplementationVersion()`.
 * 
 * These methods read the data from the `MANIFEST.MF` file of the JAR file. This is
 * problematic for users who build a JAR with dependencies (also called an "uber JAR"
 * or "fat JAR") which includes this project. This `MANIFEST.MF` information can often
 * not be preserved or would collide with the data of other bundled dependencies.
 * Additionally some class loaders might not support reading this data from the manifest.
 * 
 * It might therefore be better to choose other alternatives for including version
 * information, such as injecting it into template classes. Depending on the used build
 * tool or plugin, this often also allows including other useful information as well.
 */

import java

class PackageVersionMethod extends Method {
    PackageVersionMethod() {
        getDeclaringType().hasQualifiedName("java.lang", "Package")
        and hasStringSignature([
            "getImplementationTitle()",
            "getImplementationVendor()",
            "getImplementationVersion()",
            "getSpecificationTitle()",
            "getSpecificationVendor()",
            "getSpecificationVersion()",
            "isCompatibleWith(String)"
        ])
    }
}

from MethodAccess call
where call.getMethod() instanceof PackageVersionMethod
select call, "Queries package version information"

/**
 * Finds calls to `System.clearProperty` and `System.setProperty` where the property name
 * is one of the standard system properties defined in
 * [`System.getProperties()`](https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/lang/System.html#getProperties()).
 * As mentioned in the documentation of that method, changing standard system properties might
 * not work as desired because their values might be cached.
 */

import java

class SystemPropertyChangingCall extends MethodAccess {
    string propertyName;
    
    SystemPropertyChangingCall() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType() instanceof TypeSystem
        |
            m.hasName(["clearProperty", "setProperty"])
            and propertyName = getArgument(0).(CompileTimeConstantExpr).getStringValue()
        )
    }
    
    string getPropertyName() {
        result = propertyName
    }
}

from SystemPropertyChangingCall call, string propertyName
where
    propertyName = call.getPropertyName()
    // Based on https://docs.oracle.com/en/java/javase/17/docs/api/java.base/java/lang/System.html#getProperties()
    and propertyName = [
        "java.version",
        "java.version.date",
        "java.vendor",
        "java.vendor.url",
        "java.vendor.version",
        "java.home",
        "java.vm.specification.version",
        "java.vm.specification.vendor",
        "java.vm.specification.name",
        "java.vm.version",
        "java.vm.vendor",
        "java.vm.name",
        "java.specification.version",
        "java.specification.vendor",
        "java.specification.name",
        "java.class.version",
        "java.class.path",
        "java.library.path",
        "java.io.tmpdir",
        "java.compiler",
        "os.name",
        "os.arch",
        "os.version",
        "file.separator",
        "path.separator",
        "line.separator",
        "user.name",
        "user.home",
        "user.dir",
        "native.encoding",
        "jdk.module.path",
        "jdk.module.upgrade.path",
        "jdk.module.main",
        "jdk.module.main.class",
    ]
select call, "Modifies standard system property '" + propertyName + "'"

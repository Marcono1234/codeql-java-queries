/**
 * Finds System properties which are looked up through `System.getProperty`
 * despite there being a constant or static method returning this information
 * and therefore guaranteeing more type safety.
 */

import java

class GetPropertyMethod extends Method {
    GetPropertyMethod() {
        getDeclaringType() instanceof TypeSystem
        and hasStringSignature("getProperty(String)")
    }
}

/**
 * Gets the constant or static method name (if there is one) for the given
 * `System.getProperty` argument.
 */
string getPropertyConstant(CompileTimeConstantExpr arg) {
    exists (string strArg | strArg = arg.getStringValue() |
        (strArg = "file.separator" and result = "java.io.File.separatorChar")
        or (strArg = "path.separator" and result = "java.io.File.pathSeparatorChar")
        or (strArg = "line.separator" and result = "java.lang.System.lineSeparator()")
        // This is only correct if file.encoding value is set and is supported
        // Otherwise defaultCharset defaults to UTF-8
        or (strArg = "file.encoding" and result = "java.nio.charset.Charset.defaultCharset()")
        or (strArg = "java.io.tmpdir" and result = "java.nio.file.Files.createTempFile(...)")
        or (strArg = "user.language" and result = "java.util.Locale.getDefault()")
        or (strArg = "user.region" and result = "java.util.Locale.getDefault()")
        or (strArg = "user.script" and result = "java.util.Locale.getDefault()")
        or (strArg = "user.country" and result = "java.util.Locale.getDefault()")
        or (strArg = "user.variant" and result = "java.util.Locale.getDefault()")
        or (strArg = "user.extensions" and result = "java.util.Locale.getDefault()")
        or (strArg = "user.timezone" and result = "java.util.TimeZone.getDefault()")
    )
}

from MethodAccess call, string constant
where
    call.getMethod() instanceof GetPropertyMethod
    and constant = getPropertyConstant(call.getArgument(0))
select call, constant

/**
 * Finds creation of temporary files where the specified file name suffix appears to
 * be intended as file extension, but does not start with a `.`. The suffix is
 * appended directly to the name and therefore without a `.` the file name will have
 * no extension.
 */

import java

class CreateTempFileMethod extends Method {
    int suffixParamIndex;
    
    CreateTempFileMethod() {
        (
            getDeclaringType() instanceof TypeFile
            and hasName("createTempFile")
            and suffixParamIndex = 1
        )
        or (
            getDeclaringType().hasQualifiedName("java.nio.file", "Files")
            and hasName("createTempFile")
            and if (getParameterType(0) instanceof TypePath) then suffixParamIndex = 2
            else suffixParamIndex = 1
        )
    }
    
    int getSuffixParamIndex() {
        result = suffixParamIndex
    }
}

from MethodAccess createTempFileCall, CreateTempFileMethod createTempFileMethod, CompileTimeConstantExpr suffix, string suffixString
where
    createTempFileMethod = createTempFileCall.getMethod()
    and createTempFileCall.getArgument(createTempFileMethod.getSuffixParamIndex()) = suffix
    and suffixString = suffix.getStringValue()
    // Check if suffix could be intended as file extension, but has no leading '.'
    and suffixString.regexpMatch([
        "[a-z0-9]{1,5}",
        "[A-Z0-9]{1,5}"
    ])
    // Ignore if suffix only consists of digits
    and not suffixString.regexpMatch("\\d+")
select createTempFileCall, "Creates temp file with $@ which does not start with '.'", suffix, "suffix '" + suffixString + "'"

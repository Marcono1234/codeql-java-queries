/*
 * Finds code which appears to transfer data from an `InputStream` to an `OutputStream`.
 * When working with files, the `java.nio.file.Files` methods `copy(InputStream, Path)`
 * or `readAllBytes(Path)` should be preferred.
 * Otherwise `InputStream.transferTo(OutputStream)`, added in JDK 9, should be used.
 */

import java

class TypeInputStream extends RefType {
    TypeInputStream() {
        hasQualifiedName("java.io", "InputStream")
    }
}

class ReadToBufferMethod extends Method {
    ReadToBufferMethod() {
        exists (Method overridden | this.overridesOrInstantiates(overridden) |
            overridden.getDeclaringType() instanceof TypeInputStream
            and overridden.hasStringSignature([
                "read(byte[])",
                "read(byte[], int, int)",
                "readNBytes(byte[], int, int)"
            ])
        )
    }
    
    int bufferIndex() {
        // First argument is byte array
        result = 0
    }
}
            
class ReadMethod extends Method {
    ReadMethod() {
        exists (Method overridden | this.overridesOrInstantiates(overridden) |
            overridden.getDeclaringType() instanceof TypeInputStream
            and overridden.hasStringSignature([
                "readAllBytes()",
                "readNBytes(int)"
            ])
        )
    }
}

class WriteMethod extends Method {
    WriteMethod() {
        exists (Method overridden | this.overridesOrInstantiates(overridden) |
            overridden.getDeclaringType().hasQualifiedName("java.io", "OutputStream")
            and overridden.hasStringSignature([
                "write(byte[])",
                "write(byte[], int, int)"
            ])
        )
    }
    
    int bufferIndex() {
        // First argument is byte array
        result = 0
    }
}

from LocalScopeVariable var, MethodAccess readCall, MethodAccess writeCall
where
    var.getType().(Array).getComponentType().hasName("byte")
    and (
        var.getAnAccess() = readCall.getArgument(readCall.getMethod().(ReadToBufferMethod).bufferIndex())
        or (
            readCall.getMethod() instanceof ReadMethod
            and var.getAnAssignedValue() = readCall
        )
    )
    and var.getAnAccess() = writeCall.getArgument(writeCall.getMethod().(WriteMethod).bufferIndex())
select readCall, "Transfer of bytes to $@ can be simplified", writeCall, "here"

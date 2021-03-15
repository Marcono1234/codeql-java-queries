/**
 * Searches for array creations where the size of the array is based 
 * on remote input, user input or read from a `java.io` class, which 
 * usually also indicates that the data might come from remote input.
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.dataflow.FlowSources

abstract class ReadingMethods extends Method { }

class InputStreamMethods extends ReadingMethods {
    InputStreamMethods() {
        getDeclaringType().hasQualifiedName("java.io", "InputStream")
        and exists (string s | getSignature() = s |
            // Only returns a byte, but maybe code is combining multiple 
            // to create array size
            s = "read()"
        )
    }
}

class DataInputMethods extends ReadingMethods {
    DataInputMethods() {
        getDeclaringType().hasQualifiedName("java.io", "DataInput")
        and exists (string s | getSignature() = s |
            s = "readInt()"
            or s = "readLong()"
            // Also check smaller value types in case code combines them to larger ones
            or s = "readShort()"
            or s = "readUnsignedShort()"
            or s = "readByte()"
            or s = "readUnsignedByte()"
            // Unlikely that these are used for array size, but is possible
            or s = "readChar()"
            or s = "readFloat()"
            or s = "readDouble()"
        )
    }
}

// TODO: Maybe also consider ObjectInputStream methods?

class ReaderSource extends DataFlow::ExprNode {
    ReaderSource() {
        exists(Method m | m = this.asExpr().(MethodAccess).getMethod() |
            m instanceof ReadingMethods
        )
        /*
         * TODO: Would also be possible that array size is constructed
         * from data stored in array passed to / retrieved from read(...)
         * methods
         */
    }
}

class Configuration extends DataFlow::Configuration {
    Configuration() {
        this = "Untrusted array allocation Configuration"
    }

    override predicate isSource(DataFlow::Node source) {
        source instanceof ReaderSource
        or source instanceof RemoteFlowSource
        or source instanceof UserInput
    }

    override predicate isSink(DataFlow::Node sink) {
        exists(ArrayCreationExpr newArr |
            sink.asExpr() = newArr.getADimension()
        )
    }
    
    /*
     * TODO: Might have to override isSanitizer in case size is restricted, e.g.:
     *   int len = readInt() & 0xFF
     *   int len = Math.min(10, readInt())
     */
}

from DataFlow::Node src, DataFlow::Node sink, Configuration config
where config.hasFlow(src, sink)
select src, "Creates array of untrusted size $@.", sink, "here"

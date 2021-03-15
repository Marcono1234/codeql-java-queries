/**
 * Finds array creation expressions which create arrays with a large static
 * size. When such arrays are only used as buffer, allocating too much memory
 * might decrease the performance of the application, especially when multiple
 * instances of the buffer are created, or when other classes are using
 * similarly large buffers.
 */

import java

private int getPrimitiveBytesCount(PrimitiveType type) {
    type.hasName("boolean") and result = 1 // Size is not actually defined for boolean, pretend it is one byte
    or type.hasName("byte") and result = 1
    or type.hasName(["short", "char"]) and result = 2
    or type.hasName(["int", "float"]) and result = 4
    or type.hasName(["long", "double"]) and result = 8
}

private int getSize(ArrayCreationExpr newArray, int dimensionIndex) {
    result = newArray.getDimension(dimensionIndex).(CompileTimeConstantExpr).getIntValue()
}

private int getTotalSize(ArrayCreationExpr newArray, int startDimensionIndex) {
    if exists (newArray.getDimension(startDimensionIndex + 1)) then (
        result = getSize(newArray, startDimensionIndex) * getTotalSize(newArray, startDimensionIndex + 1)
    ) else (
        // Only take element type size for deepest nested dimension into account
        result = getPrimitiveBytesCount(newArray.getType().(Array).getElementType()) * getSize(newArray, startDimensionIndex)
    )
}

bindingset[bytesCount]
private string formatBytes(int bytesCount) {
    if bytesCount < 1024 then result = bytesCount + "B"
    else if bytesCount < 1024 * 1024 then result = bytesCount / 1000 + "KB (" + bytesCount / 1024 + "KiB)"
    else result = bytesCount / 1000000 + "MB (" + bytesCount / (1024 * 1024) + "MiB)"
}

from ArrayCreationExpr newArray, int totalSize
where 
    totalSize = getTotalSize(newArray, 0)
    and totalSize >= 100000
select newArray, "Array takes up more than " + formatBytes(totalSize)

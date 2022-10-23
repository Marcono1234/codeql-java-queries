/**
 * Finds usage of one of the empty collection constants of `Collections`, such as
 * `EMPTY_LIST`. Those constants use raw types and will therefore lead to compiler
 * warnings and potentially non type-safe code. Instead the type-safe factory methods
 * should be preferred, for example `Collections.emptyList()`.
 * 
 * @kind problem
 */

import java

from FieldRead fieldRead, Field field, string alternative
where
    field = fieldRead.getField()
    and field.getDeclaringType().hasQualifiedName("java.util", "Collections")
    and exists(string fieldName | fieldName = field.getName() |
        fieldName = "EMPTY_LIST" and alternative = "emptyList()"
        or fieldName = "EMPTY_SET" and alternative = "emptySet()"
        or fieldName = "EMPTY_MAP" and alternative = "emptyMap()"
    )
select fieldRead, "Could instead use Collections." + alternative + " which provides type-safety"

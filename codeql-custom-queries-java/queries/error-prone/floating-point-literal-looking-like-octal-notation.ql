/**
 * Finds floating point literals which have a leading 0 for their integral part or for
 * their exponent value. Floating point literals do not support an octal notation, the
 * leading 0 is simply ignored. To avoid confusion, it should be removed from the code.
 */

import java
import lib.Literals

from FloatingPointLiteral_ literal, string literalString
where
    literalString = literal.getLiteral()
    and literalString.regexpMatch([
        // Leading 0
        "0[0-9]+.*",
        // Leading 0 for exponent
        ".*[eEpP][+-]?0[0-9]+.*",
    ])
select literal, "Has misleading leading 0"

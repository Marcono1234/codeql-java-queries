/**
 * Finds abstract `toString()` method overrides with Javadoc in interfaces. This might
 * indicate that `toString()` is repurposed and the Javadoc specifies requirements
 * for the implementation.
 * 
 * This causes the following issues:
 * - Because `Object` already defines a `toString()` implementation, it is easy to
 *   forget to override it.
 * - When used for interfaces which might represent sensitive information, repurposing
 *   `toString()` might leak sensitive information when accidentially logged or included
 *   in exception messages.
 * 
 * It should therefore be avoided to repurpose `toString()` in interfaces. Instead it
 * might be better to define a separate method for the desired functionality.
 * Alternatively instead of an interface, an abstract class could be used, then
 * subclasses are required to override `toString()`.
 */

import java

from ToStringMethod toStringMethod, Javadoc javadoc
where
    toStringMethod.isAbstract()
    // Only consider interfaces; for abstract classes subclasses must override toString()
    and toStringMethod.getDeclaringType() instanceof Interface
    and javadoc.getCommentedElement() = toStringMethod
    // Ignore if javadoc inherits the documentation, then it might specify an additional
    // optional implementation note
    and not javadoc.getAChild().(JavadocText).getText().matches("%{@inheritDoc}%")
select toStringMethod, "toString() method is repurposed"

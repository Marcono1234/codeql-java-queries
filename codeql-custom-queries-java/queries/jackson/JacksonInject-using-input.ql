/**
 * Finds usage of `@JacksonInject` where no value for `useInput` is specified. By default
 * input is used, allowing it to overwrite injected values. This might be exploitable, for
 * example when an adversary can abuse this to disable an injected security configuration.
 * 
 * See also [jackson-annotations issue 186](https://github.com/FasterXML/jackson-annotations/issues/186).
 */

// TODO: Maybe maybe improve this to by ignoring @JacksonInject usage when
// @JsonProperty or similar annotation is used on same element

import java

class JacksonInjectAnnotation extends Annotation {
  JacksonInjectAnnotation() {
    getType().hasQualifiedName("com.fasterxml.jackson.annotation", "JacksonInject")
  }
  
  predicate implicitlyUsesInput() {
    // Only consider if not explicitly specified, then it uses input implicitly by default
    not exists(getValue("useInput"))
  }
}

from JacksonInjectAnnotation injectAnnotation
where injectAnnotation.implicitlyUsesInput()
select injectAnnotation, "Implicitly allows input to overwrite injected value"

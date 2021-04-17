/**
 * Finds annotations indicating whether an element can be `null` or not, placed
 * on an element of primitive type. Primitive types cannot be `null`, therefore
 * the annotation is redundant or possibly even incorrect.
 */

import java
import lib.Nullness

abstract class NullnessAnnotationOnPrimitive extends Annotation {
    NullnessAnnotationOnPrimitive() {
        this instanceof NullnessAnnotation
    }

    abstract PrimitiveType getPrimitiveType();
    abstract string getDescription();
}

class NullnessAnnotatedField extends NullnessAnnotationOnPrimitive {
    PrimitiveType primitiveType;

    NullnessAnnotatedField() {
        exists(Field f |
            f = getAnnotatedElement()
            // Ignore implicit fields of records, for them the component will already
            // be reported as parameter
            and not f.getDeclaringType() instanceof Record
        |
            primitiveType = f.getType()
        )
    }

    override
    PrimitiveType getPrimitiveType() {
        result = primitiveType
    }

    override
    string getDescription() {
        result = "field"
    }
}

class NullnessAnnotatedParameter extends NullnessAnnotationOnPrimitive {
    PrimitiveType primitiveType;

    NullnessAnnotatedParameter() {
        primitiveType = any(Parameter p | p = getAnnotatedElement()).getType()
    }

    override
    PrimitiveType getPrimitiveType() {
        result = primitiveType
    }

    override
    string getDescription() {
        result = "parameter"
    }
}

class NullnessAnnotatedVariable extends NullnessAnnotationOnPrimitive {
    PrimitiveType primitiveType;

    NullnessAnnotatedVariable() {
        primitiveType = any(LocalVariableDecl v | v = getAnnotatedElement()).getType()
    }

    override
    PrimitiveType getPrimitiveType() {
        result = primitiveType
    }

    override
    string getDescription() {
        result = "variable"
    }
}

class NullnessAnnotatedMethod extends NullnessAnnotationOnPrimitive {
    PrimitiveType primitiveType;

    NullnessAnnotatedMethod() {
        // Assume that annotation is supposed to apply to return type
        primitiveType = any(Method m | m = getAnnotatedElement()).getReturnType()
    }

    override
    PrimitiveType getPrimitiveType() {
        result = primitiveType
    }

    override
    string getDescription() {
        result = "method return type"
    }
}

class NullnessAnnotatedTypeUse extends NullnessAnnotationOnPrimitive {
    PrimitiveType primitiveType;

    NullnessAnnotatedTypeUse() {
        any(TypeAccess t | t = getAnnotatedElement()).getType() = primitiveType
    }

    override
    PrimitiveType getPrimitiveType() {
        result = primitiveType
    }

    override
    string getDescription() {
        result = "type use"
    }
}

from NullnessAnnotationOnPrimitive annotation
where annotation.getAnnotatedElement().fromSource()
select annotation, "Annotates " + annotation.getDescription() + " of primitive type " + annotation.getPrimitiveType().getName()

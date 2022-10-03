/**
 * Finds calls to methods checking for the presence of or retrieving annotations,
 * but where the target types of the annotation type do not support the element
 * from which the annotation is retrieved.
 * 
 * For example, for an annotation `@FieldAnn` with the meta-annotation
 * `@Target(ElementType.FIELD)`:
 * ```java
 * boolean hasAnnotation(Method method) {
 *     // Impossible: Checks whether a method has an annotation which can only
 *     // be placed on fields
 *     return method.isAnnotationPresent(FieldAnn.class);
 * }
 * ```
 */

// Similar to CodeQL's `java/ineffective-annotation-present-check` checking the RetentionPolicy

import java
import semmle.code.java.dataflow.SSA

import lib.Annotations

abstract class AnnotationRetrievingCall extends MethodAccess {
    abstract Expr getAnnotationTypeArg();
    abstract string getACheckedTarget();
}

// Covers methods of https://docs.oracle.com/en/java/javase/16/docs/api/java.base/java/lang/reflect/AnnotatedElement.html
abstract class AnnotatedElementAnnotationCheckingCall extends AnnotationRetrievingCall {
    AnnotatedElementAnnotationCheckingCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType().getSourceDeclaration().getASourceSupertype*().hasQualifiedName("java.lang.reflect", "AnnotatedElement")
            and m.hasName([
                "getAnnotation",
                "getAnnotationsByType",
                "getDeclaredAnnotation",
                "getDeclaredAnnotationsByType",
                "isAnnotationPresent"
            ])
        )
    }

    override
    Expr getAnnotationTypeArg() {
        result = getArgument(0)
    }
}

/*
 * See https://docs.oracle.com/javase/specs/jls/se16/html/jls-9.html#jls-9.6.4.1
 * for which target covers which element
 */

// Note: The following CodeQL classes cover Java base classes and interfaces as well in case they
// are used instead of more specified subtypes, e.g. calling `AccessibleObject.getAnnotation(...)`

class AnnotatedTypeAnnotationCall extends AnnotatedElementAnnotationCheckingCall {
    AnnotatedTypeAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getSourceDeclaration().getASourceSupertype*().hasQualifiedName("java.lang.reflect", "AnnotatedType")
    }

    override
    string getACheckedTarget() {
        result = "TYPE_USE"
    }
}

class GenericDeclarationAnnotationCall extends AnnotatedElementAnnotationCheckingCall {
    GenericDeclarationAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("java.lang.reflect", "GenericDeclaration")
        // Ignore standard Java classes, they are covered by the other CodeQL classes
        and not getReceiverType().getPackage().getName().matches(["java.lang.%", "javax.lang.%"])
    }

    override
    string getACheckedTarget() {
        result = [
            "CONSTRUCTOR", "METHOD",
            // Does not include `ANNOTATION_TYPE` because annotation types cannot be generic
            "TYPE", "TYPE_USE"
        ]
    }
}

class TypeVariableAnnotationCall extends AnnotatedElementAnnotationCheckingCall {
    TypeVariableAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getSourceDeclaration().getASourceSupertype*().hasQualifiedName("java.lang.reflect", "TypeVariable")
    }

    override
    string getACheckedTarget() {
        result = "TYPE_PARAMETER"
    }
}

class AccessibleObjectAnnotationCall extends AnnotatedElementAnnotationCheckingCall {
    AccessibleObjectAnnotationCall() {
        getReceiverType().hasQualifiedName("java.lang.reflect", "AccessibleObject")
    }

    override
    string getACheckedTarget() {
        result = ["CONSTRUCTOR", "FIELD", "METHOD"]
    }
}

class ClassAnnotationCall extends AnnotatedElementAnnotationCheckingCall {
    ClassAnnotationCall() {
        getReceiverType() instanceof TypeClass
    }

    override
    string getACheckedTarget() {
        // Note: Could possibly refine this in the future to consider type of Class on which method
        // is called, e.g. exclude ANNOTATION_TYPE when class is definitely not an annotation type
        result = ["TYPE", "TYPE_USE", "ANNOTATION_TYPE"]
    }
}

class ConstructorAnnotationCall extends AnnotatedElementAnnotationCheckingCall {
    ConstructorAnnotationCall() {
        // Constructor is generic class, need to get source declaration
        getReceiverType().getSourceDeclaration().hasQualifiedName("java.lang.reflect", "Constructor")
    }

    override
    string getACheckedTarget() {
        result = "CONSTRUCTOR"
    }
}

class ExecutableAnnotationCall extends AnnotatedElementAnnotationCheckingCall {
    ExecutableAnnotationCall() {
        getReceiverType().hasQualifiedName("java.lang.reflect", "Executable")
    }

    override
    string getACheckedTarget() {
        result = ["CONSTRUCTOR", "METHOD"]
    }
}

class FieldAnnotationCall extends AnnotatedElementAnnotationCheckingCall {
    FieldAnnotationCall() {
        getReceiverType().hasQualifiedName("java.lang.reflect", "Field")
    }

    override
    string getACheckedTarget() {
        result = "FIELD"
    }
}

class MethodAnnotationCall extends AnnotatedElementAnnotationCheckingCall {
    MethodAnnotationCall() {
        getReceiverType().hasQualifiedName("java.lang.reflect", "Method")
    }

    override
    string getACheckedTarget() {
        result = "METHOD"
    }
}

class ModuleAnnotationCall extends AnnotatedElementAnnotationCheckingCall {
    ModuleAnnotationCall() {
        getReceiverType().hasQualifiedName("java.lang", "Module")
    }

    override
    string getACheckedTarget() {
        result = "MODULE"
    }
}

class PackageAnnotationCall extends AnnotatedElementAnnotationCheckingCall {
    PackageAnnotationCall() {
        getReceiverType().hasQualifiedName("java.lang", "Package")
    }

    override
    string getACheckedTarget() {
        result = "PACKAGE"
    }
}

class ParameterAnnotationCall extends AnnotatedElementAnnotationCheckingCall {
    ParameterAnnotationCall() {
        getReceiverType().hasQualifiedName("java.lang.reflect", "Parameter")
    }

    override
    string getACheckedTarget() {
        result = "PARAMETER"
    }
}

class RecordComponentAnnotationCall extends AnnotatedElementAnnotationCheckingCall {
    RecordComponentAnnotationCall() {
        getReceiverType().hasQualifiedName("java.lang.reflect", "RecordComponent")
    }

    override
    string getACheckedTarget() {
        result = "RECORD_COMPONENT"
    }
}


// Covers methods of https://docs.oracle.com/en/java/javase/16/docs/api/java.compiler/javax/lang/model/AnnotatedConstruct.html
abstract class AnnotatedConstructAnnotationCheckingCall extends AnnotationRetrievingCall {
    AnnotatedConstructAnnotationCheckingCall() {
        exists(Method m | m = getMethod() |
            m.getDeclaringType().getSourceDeclaration().getASourceSupertype*().hasQualifiedName("javax.lang.model", "AnnotatedConstruct")
            and m.hasName([
                "getAnnotation",
                "getAnnotationsByType"
            ])
        )
    }

    override
    Expr getAnnotationTypeArg() {
        result = getArgument(0)
    }
}

class ElementModelElementAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    ElementModelElementAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.element", "Element")
        // Ignore standard Java classes, they are covered by the other CodeQL classes
        and not getReceiverType().getPackage().getName().matches(["java.lang.%", "javax.lang.%"])
    }

    override
    string getACheckedTarget() {
        // Everything except TYPE_USE
        result = [
            "ANNOTATION_TYPE",
            "CONSTRUCTOR",
            "FIELD",
            "LOCAL_VARIABLE",
            "METHOD",
            "MODULE",
            "PACKAGE",
            "PARAMETER",
            "RECORD_COMPONENT",
            "TYPE",
            "TYPE_PARAMETER"
        ]
    }
}

class ElementModelExecutableElementAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    ElementModelExecutableElementAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.element", "ExecutableElement")
    }

    override
    string getACheckedTarget() {
        result = ["CONSTRUCTOR", "METHOD"]
    }
}

class ElementModelModuleElementAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    ElementModelModuleElementAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.element", "ModuleElement")
    }

    override
    string getACheckedTarget() {
        result = "MODULE"
    }
}

class ElementModelPackageElementAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    ElementModelPackageElementAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.element", "PackageElement")
    }

    override
    string getACheckedTarget() {
        result = "PACKAGE"
    }
}

class ElementModelParameterizableAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    ElementModelParameterizableAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.element", "Parameterizable")
        // Ignore standard Java classes, they are covered by the other CodeQL classes
        and not getReceiverType().getPackage().getName().matches(["java.lang.%", "javax.lang.%"])
    }

    override
    string getACheckedTarget() {
        result = [
            "CONSTRUCTOR", "METHOD",
            // Does not include `ANNOTATION_TYPE` because annotation types cannot be generic
            "TYPE", "TYPE_USE"
        ]
    }
}

class ElementModelQualifiedNameableAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    ElementModelQualifiedNameableAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.element", "QualifiedNameable")
        // Ignore standard Java classes, they are covered by the other CodeQL classes
        and not getReceiverType().getPackage().getName().matches(["java.lang.%", "javax.lang.%"])
    }

    override
    string getACheckedTarget() {
        result = [
            "MODULE",
            "PACKAGE",
            "ANNOTATION_TYPE", "TYPE", "TYPE_USE"
        ]
    }
}

class ElementModelRecordComponentElementAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    ElementModelRecordComponentElementAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.element", "RecordComponentElement")
    }

    override
    string getACheckedTarget() {
        result = "RECORD_COMPONENT"
    }
}

class ElementModelTypeElementAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    ElementModelTypeElementAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.element", "TypeElement")
    }

    override
    string getACheckedTarget() {
        result = ["ANNOTATION_TYPE", "TYPE", "TYPE_USE"]
    }
}

class ElementModelTypeParameterElementAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    ElementModelTypeParameterElementAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.element", "TypeParameterElement")
    }

    override
    string getACheckedTarget() {
        result = "TYPE_PARAMETER"
    }
}

class ElementModelVariableElementAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    ElementModelVariableElementAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.element", "VariableElement")
    }

    override
    string getACheckedTarget() {
        result = ["FIELD", "LOCAL_VARIABLE", "PARAMETER"]
    }
}

class TypeModelTypeMirrorAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    TypeModelTypeMirrorAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.type", "TypeMirror")
        // Ignore standard Java classes, they are covered by the other CodeQL classes
        and not getReceiverType().getPackage().getName().matches(["java.lang.%", "javax.lang.%"])
    }

    override
    string getACheckedTarget() {
        // TODO: Not completely sure if this is correct
        result = [
            "MODULE",
            "PACKAGE",
            "ANNOTATION_TYPE", "TYPE", "TYPE_USE",
            "TYPE_PARAMETER"
        ]
    }
}

class TypeModelArrayTypeAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    TypeModelArrayTypeAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.type", "ArrayType")
    }

    override
    string getACheckedTarget() {
        // Cover `TYPE` in case this accounts for implicit annotations on the 'declaration'
        // of an array type; not sure if this is correct
        result = ["TYPE", "TYPE_USE"]
    }
}

class TypeModelDeclaredTypeAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    TypeModelDeclaredTypeAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.type", "DeclaredType")
    }

    override
    string getACheckedTarget() {
        result = ["ANNOTATION_TYPE", "TYPE", "TYPE_USE"]
    }
}

class TypeModelExecutableTypeAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    TypeModelExecutableTypeAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.type", "ExecutableType")
    }

    override
    string getACheckedTarget() {
        result = ["CONSTRUCTOR", "METHOD"]
    }
}

class TypeModelIntersectionTypeAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    TypeModelIntersectionTypeAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.type", "IntersectionType")
    }

    override
    string getACheckedTarget() {
        // TODO: Can an intersection type as a whole even be annotated?
        result = "TYPE_USE"
    }
}

class TypeModelNoTypeAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    TypeModelNoTypeAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.type", "NoType")
    }

    override
    string getACheckedTarget() {
        // See https://docs.oracle.com/en/java/javase/16/docs/api/java.compiler/javax/lang/model/type/NoType.html
        result = ["MODULE", "PACKAGE"]
    }
}

class TypeModelPrimitiveTypeAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    TypeModelPrimitiveTypeAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.type", "PrimitiveType")
    }

    override
    string getACheckedTarget() {
        // Cover `TYPE` in case this accounts for implicit annotations on the 'declaration'
        // of a primitive type; not sure if this is correct
        result = ["TYPE", "TYPE_USE"]
    }
}

class TypeModelReferenceTypeAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    TypeModelReferenceTypeAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.type", "ReferenceType")
        // Ignore standard Java classes, they are covered by the other CodeQL classes
        and not getReceiverType().getPackage().getName().matches(["java.lang.%", "javax.lang.%"])
    }

    override
    string getACheckedTarget() {
        result = [
            "ANNOTATION_TYPE", "TYPE", "TYPE_USE",
            "TYPE_PARAMETER"
        ]
    }
}

class TypeModelTypeVariableAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    TypeModelTypeVariableAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.type", "TypeVariable")
    }

    override
    string getACheckedTarget() {
        result = "TYPE_PARAMETER"
    }
}

class TypeModelUnionTypeAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    TypeModelUnionTypeAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.type", "UnionType")
    }

    override
    string getACheckedTarget() {
        // TODO: Can a union type as a whole even be annotated?
        result = "TYPE_USE"
    }
}

class TypeModelWildcardTypeAnnotationCall extends AnnotatedConstructAnnotationCheckingCall {
    TypeModelWildcardTypeAnnotationCall() {
        // Cover custom implementations
        getReceiverType().getASourceSupertype*().hasQualifiedName("javax.lang.model.type", "WildcardType")
    }

    override
    string getACheckedTarget() {
        result = "TYPE_USE"
    }
}

// Only use SSA but not local data flow to avoid false positives when variable
// is assigned at multiple locations or is re-assigned
Expr getDirectAccessOrSsa(Expr source) {
    source = result
    or exists (SsaExplicitUpdate ssaVar |
        ssaVar.getDefiningExpr().(VariableAssign).getSource() = source
        and result = ssaVar.getAUse()
    )
}

from AnnotationRetrievingCall retrievingCall, TypeLiteral annTypeLiteral, AnnotationType annType
where
    retrievingCall.getAnnotationTypeArg() = getDirectAccessOrSsa(annTypeLiteral)
    and annType = annTypeLiteral.getReferencedType()
    // Annotation type is not applicable to any of the targets
    and not exists(string target |
        target = retrievingCall.getACheckedTarget()
        and annType.isATargetType(target)
    )
    // Note: Don't need to handle repeatable annotation types in a special way because the JLS does not
    // permit more target types for the containing annotation type than for the repeated annotation type
select retrievingCall, "Call will never succeed; target is not supported by targets of annotation type $@: " + describeTargetTypes(annType),
    annType, "@" + annType.getName()

/**
 * Finds usage of Jackson which enables unsafe default typing of untrusted types.
 * 
 * See also Jackson blog post ["Jackson 2.10: Safe Default Typing"](https://cowtowncoder.medium.com/jackson-2-10-safe-default-typing-2d018f0ce2ba).
 */

import java

abstract class UnsafeDefaultTypingTop extends Top {
    /**
     * Gets a description for why this element represents unsafe usage.
     */
    abstract string getDescription();
}

class ClassObjectMapper extends Class {
    ClassObjectMapper() {
        hasQualifiedName("com.fasterxml.jackson.databind", "ObjectMapper")
    }
}

class MapperBuilderClass extends Class {
    MapperBuilderClass() {
        getSourceDeclaration().getASourceSupertype*().hasQualifiedName("com.fasterxml.jackson.databind.cfg", "MapperBuilder")
    }
}

class UnsafeDefaultTypingEnablingCall extends Call, UnsafeDefaultTypingTop {
    UnsafeDefaultTypingEnablingCall() {
        exists(Method m | m = getCallee() |
            m.getDeclaringType() instanceof ClassObjectMapper
            and m.hasName([
                "enableDefaultTyping",
                "enableDefaultTypingAsProperty"
            ])
        )
        or exists(Method m | m = getCallee() |
            (
                m.getDeclaringType() instanceof ClassObjectMapper
                or m.getDeclaringType() instanceof MapperBuilderClass
            )
            // For simplicity consider any usage of this method as unsafe; if this results in too many
            // false positives could later verify that unsafe TypeResolverBuidler is used as argument
            and m.hasName("setDefaultTyping")
        )
    }

    override
    string getDescription() {
        result = "enabled unsafe default typing"
    }
}

class UnsafeTypeResolverBuilderCreation extends ClassInstanceExpr, UnsafeDefaultTypingTop {
    UnsafeTypeResolverBuilderCreation() {
        exists(Constructor c, RefType constructed |
            c = getConstructor()
            and constructed = c.getDeclaringType().getSourceDeclaration()
        |
            // StdTypeResolverBuilder is always unsafe
            constructed.hasQualifiedName("com.fasterxml.jackson.databind.jsontype.impl", "StdTypeResolverBuilder")
            or (
                constructed.hasQualifiedName("com.fasterxml.jackson.databind", "ObjectMapper$DefaultTypeResolverBuilder")
                // Constructor with a single parameter is unsafe
                and c.getNumberOfParameters() = 1
            )
        )
    }

    override
    string getDescription() {
        result = "creates unsafe TypeResolverBuilder"
    }
}

/** Internal class `LaissezFaireSubTypeValidator`, which does not perform any validation at all. */
class ClassLaissezFaireSubTypeValidator extends Class {
    ClassLaissezFaireSubTypeValidator() {
        hasQualifiedName("com.fasterxml.jackson.databind.jsontype.impl", "LaissezFaireSubTypeValidator")
    }
}

class LaissezFaireSubTypeValidatorUsage extends Expr, UnsafeDefaultTypingTop {
    LaissezFaireSubTypeValidatorUsage() {
        exists(Field f | f = this.(FieldAccess).getField() |
            f.getDeclaringType() instanceof ClassLaissezFaireSubTypeValidator
            and f.hasName("instance")
        )
        or exists(ClassInstanceExpr c | c = this |
            c.getConstructedType() instanceof ClassLaissezFaireSubTypeValidator
        )
    }

    override
    string getDescription() {
        result = "uses type validator which allows all types"
    }
}

class InterfacePolymorphicTypeValidator extends Interface {
    InterfacePolymorphicTypeValidator() {
        hasQualifiedName("com.fasterxml.jackson.databind.jsontype", "PolymorphicTypeValidator")
    }
}

class ValidityAllowed extends EnumConstant {
    ValidityAllowed() {
        getDeclaringType().hasQualifiedName("com.fasterxml.jackson.databind.jsontype", "PolymorphicTypeValidator$Validity")
        and hasName("ALLOWED")
    }
}

class ClassDefaultBaseTypeLimitingValidator extends Class {
    ClassDefaultBaseTypeLimitingValidator() {
        hasQualifiedName("com.fasterxml.jackson.databind.jsontype", "DefaultBaseTypeLimitingValidator")
    }
}

class AllSubtypesAllowingMethod extends Method, UnsafeDefaultTypingTop {
    AllSubtypesAllowingMethod() {
        fromSource()
        and (
            // See also https://javadoc.io/doc/com.fasterxml.jackson.core/jackson-databind/latest/com/fasterxml/jackson/databind/jsontype/PolymorphicTypeValidator.html
            (
                getDeclaringType().getSourceDeclaration().getASourceSupertype*() instanceof InterfacePolymorphicTypeValidator
                and hasName([
                    "validateBaseType",
                    "validateSubClassName",
                    "validateSubType"
                ])
                and exists(BlockStmt body | body = getBody() |
                    body.getNumStmt() = 1
                    // Unconditionally returns ALLOWED
                    // Note: This could be safe if one of the other validation methods already denied the type;
                    // if this results in too many false positives this could be refined
                    and body.getAStmt().(ReturnStmt).getResult().(FieldAccess).getField() instanceof ValidityAllowed
                )
            )
            or (
                getDeclaringType().getSourceDeclaration().getASourceSupertype*() instanceof ClassDefaultBaseTypeLimitingValidator
                and hasName("isUnsafeBaseType")
                and exists(BlockStmt body | body = getBody() |
                    body.getNumStmt() = 1
                    // Unconditionally returns false
                    // Note: This could be safe if `isSafeSubType` is overridden to only allow user-controlled classes
                    and body.getAStmt().(ReturnStmt).getResult().(CompileTimeConstantExpr).getBooleanValue() = false
                )
            )
            or (
                getDeclaringType().getSourceDeclaration().getASourceSupertype*() instanceof ClassDefaultBaseTypeLimitingValidator
                and hasName("isSafeSubType")
                and exists(BlockStmt body | body = getBody() |
                    body.getNumStmt() = 1
                    // Unconditionally returns true
                    // Note: This could be safe if `isUnsafeBaseType` is overridden to only allow user-controlled classes,
                    // but default Jackson unsafe list might not be extensive enough
                    and body.getAStmt().(ReturnStmt).getResult().(CompileTimeConstantExpr).getBooleanValue() = true
                )
            )
        )
    }

    override
    string getDescription() {
        result = "unconditionally allows all subtypes"
    }
}

class ClassBasicPolymorphicTypeValidatorBuilder extends Class {
    ClassBasicPolymorphicTypeValidatorBuilder() {
        hasQualifiedName("com.fasterxml.jackson.databind.jsontype", "BasicPolymorphicTypeValidator$Builder")
    }
}

class UnsafeBaseType extends RefType {
    UnsafeBaseType() {
        this instanceof TypeObject
        // Any standard Java interface
        or this.(Interface).getPackage().getName().matches(["java.lang.%", "javax.lang.%"])
    }
}

class UnsafeValidatorBuilderConfiguration extends MethodAccess, UnsafeDefaultTypingTop {
    UnsafeValidatorBuilderConfiguration() {
        exists(Method m |
            m = getMethod()
            and m.getDeclaringType() instanceof ClassBasicPolymorphicTypeValidatorBuilder
        |
            (
                m.hasName("allowIfBaseType")
                and exists(Expr arg | arg = getArgument(0) |
                    arg.(TypeLiteral).getTypeName().getType() instanceof UnsafeBaseType
                    // Usage of `allowIfBaseType(String)`
                    or arg.(CompileTimeConstantExpr).getStringValue().matches([
                        "", // empty String
                        "java.lang.%",
                        "javax.lang.%"
                    ])
                )
            )
            or (
                m.hasStringSignature("allowIfSubType(String)")
                and getArgument(0).(CompileTimeConstantExpr).getStringValue().matches([
                    "", // empty String
                    "java.lang.%",
                    "javax.lang.%"
                ])
            )
            // TODO: Not sure if this is actually unsafe
            or m.hasStringSignature("allowIfSubTypeIsArray()")
        )
    }

    override
    string getDescription() {
        result = "allows potentially unsafe types"
    }
}

// Note: Matchers are currently only used by Jackson for "allow" checks
class UnsafeAllowMatcherMethod extends Method, UnsafeDefaultTypingTop {
    UnsafeAllowMatcherMethod() {
        fromSource()
        and getDeclaringType().getSourceDeclaration().getASourceSupertype*().hasQualifiedName("com.fasterxml.jackson.databind.jsontype", "BasicPolymorphicTypeValidator$" + ["NameMatcher", "TypeMatcher"])
        and hasName("match")
        and exists(BlockStmt body | body = getBody() |
            body.getNumStmt() = 1
            // Unconditionally returns true
            and body.getAStmt().(ReturnStmt).getResult().(CompileTimeConstantExpr).getBooleanValue() = true
        ) 
    }

    override
    string getDescription() {
        result = "matcher unconditionally allows all types"
    }
}

from UnsafeDefaultTypingTop unsafeDefaultTyping
select unsafeDefaultTyping, "Uses unsafe Jackson default typing: " + unsafeDefaultTyping.getDescription()

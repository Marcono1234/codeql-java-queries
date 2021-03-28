// TODO: Refactor other queries to use this library, if possible

import java

private newtype TTopLevelVisibility =
    TTopLevelPackagePrivate()
    or TTopLevelPublic()
    or TTopLevelSelectiveModules(ExportsDirective exports)
    or TTopLevelAllModules()

/**
 * Visibility of a top level type.
 */
abstract class TopLevelVisibility extends TTopLevelVisibility {
    /**
     * Gets the rank of this visibility, the higher the more visible it is.
     */
    abstract int getVisibilityRank();

    /**
     * Holds if this visibility indicates that a top level type is visible to
     * some or all other modules.
     */
    predicate isVisibleToOtherModules() {
        getVisibilityRank() >= 2
    }

    /**
     * Holds if this visibility can 'see' the other visibility, i.e.
     * the other one is at least as high.
     */
    predicate canSee(TopLevelVisibility other) {
        other.getVisibilityRank() >= getVisibilityRank()
    }

    /**
     * Gets the visibility which is lower, either `this` or `other`.
     */
    TopLevelVisibility getLower(TopLevelVisibility other) {
        // Other has lower visibility
        if not canSee(other) then result = other
        // Will also have `this` as result when neither `other.includes(this)`, e.g.
        // when both are exported to different specific modules
        else result = this
    }

    /**
     * Gets a string describing this visibility.
     */
    abstract string toString();
}

/**
 * Top level type is package-private, it cannot be seen by other modules.
 */
class PackagePrivateTopLevelVisibility extends TopLevelVisibility, TTopLevelPackagePrivate {
    override
    int getVisibilityRank() {
        result = 0
    }

    override
    string toString() {
        result = "package-private"
    }
}

/**
 * Top level type is `public` but is not exported to other modules.
 */
class PublicTopLevelVisibility extends TopLevelVisibility, TTopLevelPublic {
    override
    int getVisibilityRank() {
        result = 1
    }

    override
    string toString() {
        result = "public"
    }
}

/**
 * Top level type is `public` and is exported to some specific other modules.
 */
class SelectiveModulesTopLevelVisibility extends TopLevelVisibility, TTopLevelSelectiveModules {
    override
    predicate canSee(TopLevelVisibility other) {
        // Other has strictly greater visibility
        other.getVisibilityRank() > getVisibilityRank()
        // Or both are exported to the same modules
        or getAnExportedTo() = other.(SelectiveModulesTopLevelVisibility).getAnExportedTo()
    }

    override
    int getVisibilityRank() {
        result = 2
    }

    /**
     * Gets a module to which this top level type is exported.
     */
    Module getAnExportedTo() {
        result = any(ExportsDirective exports | this = TTopLevelSelectiveModules(exports)).getATargetModule()
    }

    override
    string toString() {
        result = "to modules " + concat(getAnExportedTo().getName(), ", ")
    }
}

/**
 * Top level type is `public` and is exported at all modules, either explicitly
 * in the module declaration, or implicitly because it does not have a module
 * delcaration.
 */
class AllModulesTopLevelVisibility extends TopLevelVisibility, TTopLevelAllModules {
    override
    int getVisibilityRank() {
        result = 3
    }

    override
    string toString() {
        result = "to all modules"
    }
}

private TopLevelVisibility getModuleExportsVisibility(ExportsDirective exports) {
    if exports.isQualified()
    then result = TTopLevelSelectiveModules(exports)
    // Visible to all modules
    else result instanceof AllModulesTopLevelVisibility
}

private ExportsDirective getRelevantExportsDirective(Module m, TopLevelType t) {
    result = m.getADirective()
    and result.getExportedPackage() = t.getPackage()
}

private TopLevelVisibility getModuleDeclarationVisibility(Module m, TopLevelType t) {
    if exists(getRelevantExportsDirective(m, t))
    then result = getModuleExportsVisibility(getRelevantExportsDirective(m, t))
    // Type is not listed in `exports` directive, so is only visible to public types
    else result instanceof PublicTopLevelVisibility
}

// TODO: Have to manually match compilation units because Module only reports `.class` files
// See https://github.com/github/codeql/issues/5556
private predicate areProbablySame(CompilationUnit classComp, CompilationUnit sourceComp) {
    classComp.getPackage() = sourceComp.getPackage()
    and classComp.getName() = sourceComp.getName()
}

private Module getDeclaringModule(TopLevelType t) {
    areProbablySame(result.getACompilationUnit(), t.getCompilationUnit())
}

pragma[noinline]
private TopLevelVisibility getEffectiveModuleVisibility(TopLevelType t) {
    if exists(getDeclaringModule(t))
    then result = getModuleDeclarationVisibility(getDeclaringModule(t), t)
    // Not using module system, so part of 'unnamed module' which exports all types
    else result instanceof AllModulesTopLevelVisibility
}

/**
 * Gets the visibility the top-level type (transitively) declaring `t` has on
 * the module level.
 */
TopLevelVisibility getTopLevelVisibility(RefType t) {
    exists(TopLevelType topLevelT |
        topLevelT = t.getEnclosingType*()
    |
        if topLevelT.isPublic() then result = getEffectiveModuleVisibility(topLevelT)
        else result instanceof PackagePrivateTopLevelVisibility
    )
}

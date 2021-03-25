/**
 * Finds code which appears to treat the subdomain `www.` in a special way.
 * Even though this subdomain often has redirects to the canonical URL,
 * this behavior is not required. Some websites require explicit usage of
 * this subdomain and might behave differently when the subdomain is not used.
 * Therefore treating this subdomain in a special way (e.g. removing it from
 * the host name) might result in incorrect behavior.
 */

import java

from CompileTimeConstantExpr subdomainStr
where
    // Match case-insensitively
    subdomainStr.getStringValue().toLowerCase() = "www."
    // And used as part of condition
    and any(ConditionNode c).getCondition() = subdomainStr.getParent+()
select subdomainStr, "Treats `www.` subdomain in a special way"

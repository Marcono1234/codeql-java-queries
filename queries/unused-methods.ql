/**
 * Finds unused private and package-private methods.
 */

import java

from Method m
where
    (m.isPrivate() or m.isPackageProtected())
    and not m.hasAnnotation()
    and not exists (m.getAReference())
    and not m instanceof InitializerMethod
select m

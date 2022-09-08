/**
 * Finds `Thread` subclasses which override `start()` but in that method do not call
 * `super.start()`. `Thread.start()` contains the actual logic for starting a new thread,
 * therefore if it is not called no new thread is started.
 * 
 * To implement the action which should be executed in the separate thread, override
 * `run()` or provide a `Runnable` to the `Thread` constructor and don't override `start()`.
 * 
 * @kind problem
 */

import java

class StartMethod extends Method {
    StartMethod() {
        hasStringSignature("start()")
    }
}

from StartMethod m
where
    m.fromSource()
    and m.getDeclaringType().getASourceSupertype+().hasQualifiedName("java.lang", "Thread")
    and not exists(SuperMethodAccess superStartCall |
        superStartCall.getEnclosingCallable() = m
        and superStartCall.getMethod() instanceof StartMethod
    )
select m, "Overrides Thread.start() but does not call super.start()"

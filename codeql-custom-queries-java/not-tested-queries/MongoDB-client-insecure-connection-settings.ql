import java

abstract class SecurityDisablingCall extends MethodAccess {
}

class SslSettingsBuilder extends Class {
  SslSettingsBuilder() {
    hasQualifiedName("com.mongodb.connection", "SslSettings$Builder")
  }
}

class DisableSslCall extends SecurityDisablingCall {
  DisableSslCall() {
    exists(Method m | m = getMethod() |
      m.getDeclaringType() instanceof SslSettingsBuilder
      and m.hasStringSignature("enabled(boolean)")
    )
    and getArgument(0).(CompileTimeConstantExpr).getBooleanValue() = false
  }
}

class AllowInvalidHostNamesCall extends SecurityDisablingCall {
  AllowInvalidHostNamesCall() {
    exists(Method m | m = getMethod() |
      m.getDeclaringType() instanceof SslSettingsBuilder
      and m.hasStringSignature("invalidHostNameAllowed(boolean)")
    )
    and getArgument(0).(CompileTimeConstantExpr).getBooleanValue() = true
  }
}

// Class from the legacy client API
class LegacyMongoClientOptionsBuilder extends Class {
  LegacyMongoClientOptionsBuilder() {
    hasQualifiedName("com.mongodb", "MongoClientOptions$Builder")
  }
}

class LegacyDisableSslCall extends SecurityDisablingCall {
  LegacyDisableSslCall() {
    exists(Method m | m = getMethod() |
      // Builder can be subclassed (but is unlikely)
      m.getDeclaringType().getASourceSupertype*() instanceof LegacyMongoClientOptionsBuilder
      and m.hasStringSignature("sslEnabled(boolean)")
    )
    and getArgument(0).(CompileTimeConstantExpr).getBooleanValue() = false
  }
}

class LegacyAllowInvalidHostNamesCall extends SecurityDisablingCall {
  LegacyAllowInvalidHostNamesCall() {
    exists(Method m | m = getMethod() |
      // Builder can be subclassed (but is unlikely)
      m.getDeclaringType().getASourceSupertype*() instanceof LegacyMongoClientOptionsBuilder
      and m.hasStringSignature("sslInvalidHostNameAllowed(boolean)")
    )
    and getArgument(0).(CompileTimeConstantExpr).getBooleanValue() = true
  }
}

from SecurityDisablingCall securityDisablingCall
select securityDisablingCall, "Reduces security of connections, might allow man-in-the-middle (MITM) attacks"

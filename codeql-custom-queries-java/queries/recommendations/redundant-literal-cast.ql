/**
 * Finds cast expressions which cast literals to their own type,
 * i.e. the cast is redundant. E.g.:
 * ```
 * char c = (char) 'a';
 * ```
 *
 * Such casts might confuse readers and could also indicate that
 * the author intended the cast to apply to enclosing expression
 * instead.
 * Note that in some situations such casts might be reasonable, e.g.
 * for literals where one has to look at the end of the literal to find
 * out its type, e.g. a `long` or `float` literal which have the type
 * suffix `L` respectively `f`.
 */

import java

PrimitiveType getLiteralType(Literal literal) {
    literal instanceof BooleanLiteral and result.hasName("boolean")
    or literal instanceof CharacterLiteral and result.hasName("char")
    or literal instanceof DoubleLiteral and result.hasName("double")
    or literal instanceof FloatingPointLiteral and result.hasName("float")
    or literal instanceof IntegerLiteral and result.hasName("int")
    or literal instanceof LongLiteral and result.hasName("long")
}

from CastExpr cast, PrimitiveType primitiveType
where
    cast.getTypeExpr().getType() = primitiveType
    and getLiteralType(cast.getExpr()) = primitiveType
select cast

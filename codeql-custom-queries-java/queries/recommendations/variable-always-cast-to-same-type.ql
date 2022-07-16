/**
 * Finds variables which are always cast to the same type before being used.
 * If possible it might be better to change the variable to that type or introduce
 * a new variable storing the cast result to avoid the repeated casts.
 * 
 * @kind problem
 */

/* 
 * Has some overlap with query 'same-cast-multiple-times.ql'
 * However, this query here is mostly about adjusting the type of a variable to
 * avoid redundant casts.
 */

/*
 * Could also consider arrays whose accessed elements are always cast to a
 * different type. However there are some issues:
 * - converting array to another type cannot be easily done
 *   (so introducing local variable of different array type would not be easy)
 * - converting Collection<Integer> or similar to primitive array is not directly possible
 * - sometimes smaller array element types are used to reduce memory usage, e.g.
 *   `byte[]` whose elements are then later cast to `char`
 */

import java

from Variable v, Type castType
where
    // Variable read only occurs as part of cast
    forex(RValue read | read.getVariable() = v |
        exists(CastExpr cast |
            cast.getExpr() = read
            and cast.getTypeExpr().getType() = castType
        )
    )
    // Ignore if cast is to supertype; might be done then to choose correct callable overload
    and not castType = v.getType().(RefType).getASupertype*()
    // And make sure variable is read at least two times
    and count(RValue read | read.getVariable() = v) >= 2
select v, "Variable is always cast to " + castType.getName()

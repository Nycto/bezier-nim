##
## Cubic bezier curve library
##
## Based off the work found here:
## * https://pomax.github.io/bezierinfo/
## * https://pomax.github.io/bezierjs/
## * https://github.com/Pomax/bezierjs
## * https://github.com/oysteinmyrmo/bezier
##

import vmath

type
    Bezier*[N: static[int]] = object
        ## A bezier curve of order `N`
        points: array[N + 1, Vec2]

proc newBezier*[N](points: varargs[Vec2]): Bezier[N] =
    ## Creates a new instance
    assert(points.len == N + 1)
    for i in 0..<points.len:
        result.points[i] = points[i]

proc computeForQuadOrCubic(p0, p1, p2, p3: Vec2; a, b, c, d: float): Vec2 {.inline.} =
    vec2(
        a * p0.x + b * p1.x + c * p2.x + d * p3.x,
        a * p0.y + b * p1.y + c * p2.y + d * p3.y,
    )

proc compute*[N](curve: Bezier[N], t: float): Vec2 =
    ## Computes the position of a point along the curve

    # Easy outs
    if t == 0:
        return curve.points[0]
    elif t == 1:
        return curve.points[N]

    let mt = 1 - t

    # Constant curve
    when N == 0:
        return curve.points[0]

    # Linear curve
    elif N == 1:
        return vec2(
            mt * curve.points[0].x + t * curve.points[1].x,
            mt * curve.points[0].y + t * curve.points[1].y
        )

    # Quadratic
    elif N == 2:
        return computeForQuadOrCubic(
            curve.points[0], curve.points[1], curve.points[2], vec2(0, 0),
            a = mt * mt,
            b = mt * t * 2,
            c = t * t,
            d = 0
        )

    # Cubic
    elif N == 3:
        return computeForQuadOrCubic(
            curve.points[0], curve.points[1], curve.points[2], curve.points[3],
            a = mt * mt * mt,
            b = mt * mt * t * 3,
            c = mt * t * t * 3,
            d = t * t * t
        )

    else:
        {. error("High order beziers are currently unsupported") .}

##
## Cubic bezier curve library
##
## Based off the work found here:
## * https://pomax.github.io/bezierinfo/
## * https://pomax.github.io/bezierjs/
## * https://github.com/Pomax/bezierjs
## * https://github.com/oysteinmyrmo/bezier
##

import vmath, sequtils, algorithm

type
    Bezier*[N: static[int]] = object
        ## A bezier curve of order `N`
        points: array[N + 1, Vec2]

proc newBezier*[N](points: varargs[Vec2]): Bezier[N] =
    ## Creates a new instance
    assert(points.len == N + 1)
    for i in 0..<points.len:
        result.points[i] = points[i]

proc `$`*[N](curve: Bezier[N]): string =
    result = "Bezier["
    var first = true
    for point in curve.points:
        if first:
            first = false
        else:
            result.add(", ")
        result.add("{")
        result.add($point.x)
        result.add(", ")
        result.add($point.y)
        result.add("}")
    result.add("]")

proc `[]`*[N](curve: Bezier[N], point: range[0..N]): Vec2 =
    ## Returns a control point within this curve
    curve.points[point]

iterator pairs*[N](curve: Bezier[N]): (int, Vec2) =
    ## Produces all the points in this curve as well as their index
    for i in 0..N:
        yield (i, curve.points[i])

iterator items*[N](curve: Bezier[N]): lent Vec2 =
    ## Produces all the points in this curve
    for i in 0..N:
        yield curve.points[i]

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

    let mt {.used.} = 1 - t

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

proc derivative*[N](curve: Bezier[N]): auto =
    ## Computes the derivative of a bezier curve
    when N <= 0:
        {. error("Can not take the derivative of a constant curve") .}

    var output: Bezier[N - 1]
    for i in 0..<N:
        output.points[i] = (curve.points[i + 1] - curve.points[i]) * N
    return output

iterator roots[N: static[int]](entries: array[N, float32]): float32 =
    ## Calculate the roots of the given points
    when N > 3:
        {. error("Cannot calculate roots for N over 3") .}

    elif N == 3:
        let a = entries[0]
        let b = entries[1]
        let c = entries[2]
        let d = a - 2 * b + c
        if d != 0:
            let m1 = -sqrt(b * b - a * c)
            let m2 = -a + b
            yield -(m1 + m2) / d
            yield -(-m1 + m2) / d
        elif b != c and d == 0:
            yield (2 * b - c) / (2 * (b - c))

    elif N == 2:
        let a = entries[0]
        let b = entries[1]
        if a != b:
            yield a / (a - b)

iterator extrema*[N](curve: Bezier[N]): float32 =
    ## Calculates all the extrema on a curve, extressed as a `t`. You can feed these values into
    ## the `compute` method to get their coordinates

    let deriv1 = curve.derivative()

    var output = newSeq[float32]()

    var xPoints: array[N, float32]
    for i, point in deriv1: xPoints[i] = point.x
    for t in roots(xPoints): output.add(t)

    var yPoints: array[N, float32]
    for i, point in deriv1: yPoints[i] = point.y
    for t in roots(yPoints): output.add(t)

    when N == 3:
        for t in deriv1.extrema():
            output.add(t)

    sort output

    for t in output.deduplicate(isSorted = true):
        if t >= 0 and t <= 1:
            yield abs(t)

proc boundingBox*[N](curve: Bezier[N]): tuple[minX, minY, maxX, maxY: float32] =
    ## Returns the bounding box for a curve

    result = (curve.points[0].x, curve.points[0].y, curve.points[0].x, curve.points[0].y)

    when N > 0:
        proc handlePoint(point: Vec2, output: var tuple[minX, minY, maxX, maxY: float32]) =
            output.minX = min(point.x, output.minX)
            output.minY = min(point.y, output.minY)
            output.maxX = max(point.x, output.maxX)
            output.maxY = max(point.y, output.maxY)

        handlePoint(curve.points[N], result)
        for extrema in curve.extrema():
            curve.compute(extrema).handlePoint(result)

when isMainModule:
    include bezier/cli
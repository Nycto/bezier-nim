##
## Cubic bezier curve library
##
## Based off the work found here:
## * https://pomax.github.io/bezierinfo/
## * https://pomax.github.io/bezierjs/
## * https://github.com/Pomax/bezierjs
## * https://github.com/oysteinmyrmo/bezier
##

import vmath, sequtils, algorithm, bezier/util

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

template mapIt*[N](curve: Bezier[N], mapper: untyped): Bezier[N] =
    ## Applies a mapping function to the points in this curve
    block:
        var output: Bezier[N]
        for i in 0..N:
            let it {.inject.} = curve.points[i]
            output.points[i] = mapper
        output

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

proc xs*[N](curve: Bezier[N]): array[N + 1, float32] =
    ## Returns all x values from the points in this curve
    for i, point in curve: result[i] = point.x

proc ys*[N](curve: Bezier[N]): array[N + 1, float32] =
    ## Returns all y values from the points in this curve
    for i, point in curve: result[i] = point.y

iterator extrema*[N](curve: Bezier[N]): float32 =
    ## Calculates all the extrema on a curve, extressed as a `t`. You can feed these values into
    ## the `compute` method to get their coordinates

    let deriv = curve.derivative()

    var output = newSeq[float32]()
    for t in roots(deriv.xs): output.add(t)
    for t in roots(deriv.ys): output.add(t)

    when N == 3:
        for t in deriv.extrema():
            output.add(t)

    sort output

    for t in output.deduplicate(isSorted = true):
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

template withAligned[N](curve: Bezier[N], p1, p2: Vec2, exec: untyped) =
    ## Execute a callback for code that needs to use a bezier curve aligned to a point with extra details
    let ang = -arctan2(p2.y - p1.y, p2.x - p1.x)
    let cosA {.inject.} = cos(ang)
    let sinA {.inject.} = sin(ang)
    let aligned {.inject.} = curve.mapIt:
        vec2((it.x - p1.x) * cosA - (it.y - p1.y) * sinA, (it.x - p1.x) * sinA + (it.y - p1.y) * cosA)
    exec

proc align*[N](curve: Bezier[N], p1, p2: Vec2): Bezier[N] =
    ## Rotates this bezier curve so it aligns with the given line
    withAligned(curve, p1, p2): return aligned

proc tightBoundingBox*[N](curve: Bezier[N]): array[4, Vec2] =
    ## Returns the corners of a bounding box that is tightly aligned to a curve
    when N == 0:
        for i in 0..3: result[i] = curve.points[0]
    else:
        withAligned(curve, curve[0], curve[N]):

            template corner(x, y: float): Vec2 =
                 vec2(curve.points[0].x + x * cosA - y * -sinA, curve.points[0].y + x * -sinA + y * cosA)

            let (minX, minY, maxX, maxY) = aligned.boundingBox()
            result[0] = corner(minX, minY)
            result[1] = corner(maxX, minY)
            result[2] = corner(maxX, maxY)
            result[3] = corner(minX, maxY)

iterator findY*[N](curve: Bezier[N], x: float): Vec2 =
    ## Produces the Y values for a given X
    when N == 0:
        if x == curve[0].x:
            yield curve[0]
    else:
        var xVals = curve.xs()
        for i in 0..N: xVals[i] -= x
        for root in roots(xVals):
            yield curve.compute(root)

iterator segments*[N](curve: Bezier[N], steps: Positive): (Vec2, Vec2) =
    ## Breaks the curve into straight lines. Also known as flattening the curve
    when N > 0:
        let step = 1 / steps
        var previous = curve.compute(0)
        for i in 1..steps:
            let current = curve.compute(step * i.float)
            yield (previous, current)
            previous = current

when isMainModule:
    include bezier/cli
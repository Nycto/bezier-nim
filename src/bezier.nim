##
## Bezier curve library
##
## Based off the work found here:
## * https://pomax.github.io/bezierinfo/
## * https://pomax.github.io/bezierjs/
## * https://github.com/Pomax/bezierjs
## * https://github.com/oysteinmyrmo/bezier
##

import vmath, sequtils, algorithm, bezier/util, options

type
    Bezier*[N: static[int]] = object
        ## A bezier curve of order `N`
        points: array[N + 1, Vec2]

    DynBezier* = object
        ## Bezier curve where the order isn't known at compile time
        points: seq[Vec2]

template assign(points: typed) =
    for i in 0..<points.len:
        result.points[i] = points[i]

proc newBezier*[N](points: varargs[Vec2]): Bezier[N] =
    ## Creates a new instance
    assert(points.len == N + 1)
    assign(points)

proc newDynBezier*(points: varargs[Vec2]): DynBezier =
    ## Creates a new instance
    result.points.setLen(points.len)
    assign(points)

proc order*(curve: DynBezier): Natural = curve.points.len - 1

proc order*[N](curve: Bezier[N]): Natural = N

proc `$`*(curve: Bezier | DynBezier): string =
    ## Create a string representation of a bezier curve
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

proc `[]`*[N](curve: Bezier[N], point: range[0..N]): Vec2 = curve.points[point]
    ## Returns a control point within this curve

proc `[]`*(curve: DynBezier, point: Natural): Vec2 = curve.points[point]
    ## Returns a control point within this curve

iterator pairs*(curve: DynBezier | Bezier): (int, Vec2) =
    ## Produces all the points in this curve as well as their index
    for i in 0..curve.order:
        yield (i, curve.points[i])

iterator items*(curve: DynBezier | Bezier): lent Vec2 =
    ## Produces all the points in this curve
    for i in 0..curve.order:
        yield curve.points[i]

template mapItTpl[OutputType](order, curve: typed, mapper: untyped): OutputType =
    ## Applies a mapping function to the points in this curve
    block:
        var output: OutputType
        when compiles(output.points.setLen(order + 1)): output.points.setLen(order + 1)
        for i in 0..order:
            let it {.inject.} = curve.points[i]
            output.points[i] = mapper
        output

template mapIt*[N](curve: Bezier[N], mapper: untyped): Bezier[N] =
    ## Applies a mapping function to the points in this curve
    mapItTpl[Bezier[N]](N, curve, mapper)

template mapIt*(curve: DynBezier, mapper: untyped): DynBezier =
    ## Applies a mapping function to the points in this curve
    mapItTpl[DynBezier](curve.order, curve, mapper)

proc computeForQuadOrCubic(p0, p1, p2, p3: Vec2; a, b, c, d: float): Vec2 {.inline.} =
    vec2(
        a * p0.x + b * p1.x + c * p2.x + d * p3.x,
        a * p0.y + b * p1.y + c * p2.y + d * p3.y,
    )

proc computeForLinear(curve: Bezier | DynBezier, t: float): Vec2 {.inline.} =
    let mt = 1 - t
    return vec2(
        mt * curve.points[0].x + t * curve.points[1].x,
        mt * curve.points[0].y + t * curve.points[1].y
    )

proc computeForQuad(curve: Bezier | DynBezier, t: float): Vec2 {.inline.} =
    let mt = 1 - t
    return computeForQuadOrCubic(
        curve.points[0], curve.points[1], curve.points[2], vec2(0, 0),
        a = mt * mt,
        b = mt * t * 2,
        c = t * t,
        d = 0
    )

proc computeForCubic(curve: Bezier | DynBezier, t: float): Vec2 {.inline.} =
    let mt = 1 - t
    return computeForQuadOrCubic(
        curve.points[0], curve.points[1], curve.points[2], curve.points[3],
        a = mt * mt * mt,
        b = mt * mt * t * 3,
        c = mt * t * t * 3,
        d = t * t * t
    )

proc compute*[N](curve: Bezier[N], t: float): Vec2 =
    ## Computes the position of a point along the curve
    when N == 0: return curve.points[0]
    elif N == 1: return computeForLinear(curve, t)
    elif N == 2: return computeForQuad(curve, t)
    elif N == 3: return computeForCubic(curve, t)
    else: {. error("High order beziers are currently unsupported") .}

proc compute*(curve: DynBezier, t: float): Vec2 =
    ## Computes the position of a point along the curve
    case curve.order
    of 0: return curve.points[0]
    of 1: return computeForLinear(curve, t)
    of 2: return computeForQuad(curve, t)
    of 3: return computeForCubic(curve, t)
    else: assert(false, "High order beziers are currently unsupported")

template xyTpl(curve: typed, prop: untyped) =
    when compiles(result.setLen(0)): result.setLen(curve.points.len)
    for i, point in curve: result[i] = point.`prop`

proc xs*[N](curve: Bezier[N]): array[N + 1, float32] = xyTpl(curve, x)
    ## Returns all x values from the points in this curve

proc xs*(curve: DynBezier): seq[float32] = xyTpl(curve, x)
    ## Returns all x values from the points in this curve

proc ys*[N](curve: Bezier[N]): array[N + 1, float32] = xyTpl(curve, y)
    ## Returns all y values from the points in this curve

proc ys*(curve: DynBezier): seq[float32] = xyTpl(curve, y)
    ## Returns all y values from the points in this curve

template derivativeTpl(curve: typed) =
    for i in 0..<curve.order:
        output.points[i] = (curve.points[i + 1] - curve.points[i]) * curve.order.float
    return output

proc derivative*[N](curve: Bezier[N]): auto =
    ## Computes the derivative of a bezier curve
    when N <= 0: {.error( "Can not take the derivative of a constant curve").}
    var output: Bezier[N - 1]
    derivativeTpl(curve)

proc derivative*(curve: DynBezier): DynBezier =
    ## Computes the derivative of a bezier curve
    assert(curve.order > 0, "Can not take the derivative of a constant curve")
    var output: DynBezier
    output.points.setLen(curve.points.len - 1)
    derivativeTpl(curve)

proc addExtrema(curve: Bezier | DynBezier, output: var seq[float32]) =
    for t in roots(curve.xs): output.add(t)
    for t in roots(curve.ys): output.add(t)

template extremaTpl(curve: typed) =
    let deriv = curve.derivative()

    var output = newSeq[float32]()
    addExtrema(deriv, output)

    if curve.order == 3:
        addExtrema(deriv.derivative(), output)

    sort output

    for t in output.deduplicate(isSorted = true):
        yield abs(t)

iterator extrema*[N](curve: Bezier[N]): float32 =
    ## Calculates all the extrema on a curve, extressed as a `t`. You can feed these values into
    ## the `compute` method to get their coordinates
    when N > 1: extremaTpl(curve)

iterator extrema*(curve: DynBezier): float32 = extremaTpl(curve)
    ## Calculates all the extrema on a curve, extressed as a `t`. You can feed these values into
    ## the `compute` method to get their coordinates

proc boundingBox*(curve: Bezier | DynBezier): tuple[minX, minY, maxX, maxY: float32] =
    ## Returns the bounding box for a curve

    result = (curve.points[0].x, curve.points[0].y, curve.points[0].x, curve.points[0].y)

    if curve.order > 0:
        proc handlePoint(point: Vec2, output: var tuple[minX, minY, maxX, maxY: float32]) =
            output.minX = min(point.x, output.minX)
            output.minY = min(point.y, output.minY)
            output.maxX = max(point.x, output.maxX)
            output.maxY = max(point.y, output.maxY)

        handlePoint(curve.points[curve.order], result)
        for extrema in curve.extrema():
            curve.compute(extrema).handlePoint(result)

template withAligned(curve: Bezier | DynBezier, p1, p2: Vec2, exec: untyped) =
    ## Execute a callback for code that needs to use a bezier curve aligned to a point with extra details
    let ang = -arctan2(p2.y - p1.y, p2.x - p1.x)
    let cosA {.inject.} = cos(ang)
    let sinA {.inject.} = sin(ang)
    let aligned {.inject.} = curve.mapIt:
        vec2((it.x - p1.x) * cosA - (it.y - p1.y) * sinA, (it.x - p1.x) * sinA + (it.y - p1.y) * cosA)
    exec

proc align*(curve: Bezier | DynBezier, p1, p2: Vec2): auto =
    ## Rotates this bezier curve so it aligns with the given line
    withAligned(curve, p1, p2): return aligned

proc tightBoundingBox*(curve: Bezier | DynBezier): array[4, Vec2] =
    ## Returns the corners of a bounding box that is tightly aligned to a curve
    if curve.order == 0:
        for i in 0..3: result[i] = curve.points[0]
    else:
        withAligned(curve, curve.points[0], curve.points[curve.order]):

            template corner(x, y: float): Vec2 =
                 vec2(curve.points[0].x + x * cosA - y * -sinA, curve.points[0].y + x * -sinA + y * cosA)

            let (minX, minY, maxX, maxY) = aligned.boundingBox()
            result[0] = corner(minX, minY)
            result[1] = corner(maxX, minY)
            result[2] = corner(maxX, maxY)
            result[3] = corner(minX, maxY)

iterator findY*(curve: Bezier | DynBezier, x: float): Vec2 =
    ## Produces the Y values for a given X
    if curve.order == 0:
        if x == curve.points[0].x:
            yield curve.points[0]
    else:
        var xVals = curve.xs()
        for i in 0..curve.order:
            xVals[i] -= x
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

proc tangent*[N](curve: Bezier[N], t: float): Vec2 =
    ## Returns the tangent vector at a given location
    curve.derivative().compute(t)

proc normal*[N](curve: Bezier[N], t: float): Vec2 =
    ## Returns the tangent vector at a given location
    let d = curve.tangent(t)
    let q = sqrt(d.x * d.x + d.y * d.y)
    return vec2(-d.y / q, d.x / q)

iterator intersects*[N](curve: Bezier[N], p1, p2: Vec2): Vec2 =
    ## Yields the points where a curve intersects a line
    when N == 0:
        if curve.points[0].isOnLine(p1, p2):
            yield curve.points[0]
    elif N == 1:
        let intersect = linesIntersect(curve.points[0], curve.points[1], p1, p2)
        if intersect.isSome:
            yield intersect.get
    else:
        let aligned = curve.align(p1, p2)
        for t in roots(aligned.ys):
            yield curve.compute(t)

when isMainModule:
    include bezier/cli
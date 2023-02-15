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
    else: return deCasteljau(curve.points, t)

proc compute*(curve: DynBezier, t: float): Vec2 =
    ## Computes the position of a point along the curve
    case curve.order
    of 0: return curve.points[0]
    of 1: return computeForLinear(curve, t)
    of 2: return computeForQuad(curve, t)
    of 3: return computeForCubic(curve, t)
    else: return deCasteljau(curve.points, t)

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
    for t in roots(curve.xs): output.add(abs(t))
    for t in roots(curve.ys): output.add(abs(t))

template extremaTpl(curve: typed) =
    let deriv = curve.derivative()

    var output = newSeq[float32]()
    addExtrema(deriv, output)

    if curve.order == 3:
        addExtrema(deriv.derivative(), output)

    sort(output)
    yieldAll(forDistinct(output))

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

iterator points*(curve: Bezier | DynBezier, steps: range[2..high(int)]): (float, Vec2) =
    ## Produces a set of points along the curve at the given number of steps
    let step: float = 1 / (steps - 1)
    var t: float = 0
    for i in 1..steps:
        if i == steps:
            t = 1.0
        yield (t, curve.compute(t))
        t += step

iterator segments*(curve: Bezier | DynBezier, steps: Positive): (Vec2, Vec2) =
    ## Breaks the curve into straight lines. Also known as flattening the curve
    if curve.order > 0:
        var previous: Vec2
        for (t, current) in points(curve, steps + 1):
            if t != 0.0:
                yield (previous, current)
            previous = current

proc tangent*(curve: Bezier | DynBezier, t: float): Vec2 =
    ## Returns the tangent vector at a given location
    curve.derivative().compute(t)

proc normal*(curve: Bezier | DynBezier, t: float): Vec2 =
    ## Returns the tangent vector at a given location
    let d = curve.tangent(t)
    let q = sqrt(d.x * d.x + d.y * d.y)
    return vec2(-d.y / q, d.x / q)

iterator intersects*(curve: Bezier | DynBezier, p1, p2: Vec2): Vec2 =
    ## Yields the points where a curve intersects a line
    case curve.order
    of 0:
        if curve.points[0].isOnLine(p1, p2):
            yield curve.points[0]
    of 1:
        let intersect = linesIntersect(curve.points[0], curve.points[curve.order], p1, p2)
        if intersect.isSome:
            yield intersect.get
    else:
        let aligned = curve.align(p1, p2)
        for t in roots(aligned.ys):
            yield curve.compute(t)

# Legendre-Gauss abscissae with n=24 (x_i values, defined at i=n
# as the roots of the nth order Legendre polynomial Pn(x))
const Tvalues = [
    -0.0640568928626056260850430826247450385909,
    0.0640568928626056260850430826247450385909,
    -0.1911188674736163091586398207570696318404,
    0.1911188674736163091586398207570696318404,
    -0.3150426796961633743867932913198102407864,
    0.3150426796961633743867932913198102407864,
    -0.4337935076260451384870842319133497124524,
    0.4337935076260451384870842319133497124524,
    -0.5454214713888395356583756172183723700107,
    0.5454214713888395356583756172183723700107,
    -0.6480936519369755692524957869107476266696,
    0.6480936519369755692524957869107476266696,
    -0.7401241915785543642438281030999784255232,
    0.7401241915785543642438281030999784255232,
    -0.8200019859739029219539498726697452080761,
    0.8200019859739029219539498726697452080761,
    -0.8864155270044010342131543419821967550873,
    0.8864155270044010342131543419821967550873,
    -0.9382745520027327585236490017087214496548,
    0.9382745520027327585236490017087214496548,
    -0.9747285559713094981983919930081690617411,
    0.9747285559713094981983919930081690617411,
    -0.9951872199970213601799974097007368118745,
    0.9951872199970213601799974097007368118745,
]

# Legendre-Gauss weights with n=24 (w_i values, defined by a function linked to in the Bezier primer article)
const Cvalues = [
    0.1279381953467521569740561652246953718517,
    0.1279381953467521569740561652246953718517,
    0.1258374563468282961213753825111836887264,
    0.1258374563468282961213753825111836887264,
    0.121670472927803391204463153476262425607,
    0.121670472927803391204463153476262425607,
    0.1155056680537256013533444839067835598622,
    0.1155056680537256013533444839067835598622,
    0.1074442701159656347825773424466062227946,
    0.1074442701159656347825773424466062227946,
    0.0976186521041138882698806644642471544279,
    0.0976186521041138882698806644642471544279,
    0.086190161531953275917185202983742667185,
    0.086190161531953275917185202983742667185,
    0.0733464814110803057340336152531165181193,
    0.0733464814110803057340336152531165181193,
    0.0592985849154367807463677585001085845412,
    0.0592985849154367807463677585001085845412,
    0.0442774388174198061686027482113382288593,
    0.0442774388174198061686027482113382288593,
    0.0285313886289336631813078159518782864491,
    0.0285313886289336631813078159518782864491,
    0.0123412297999871995468056670700372915759,
    0.0123412297999871995468056670700372915759,
]

proc length*(curve: Bezier | DynBezier): float =
    ## Calculates the length of a curve
    result = 0
    when compiles(curve.derivative()):
        if curve.order > 0:
            const z = 0.5
            let deriv = curve.derivative()
            for i, tvalue in Tvalues:
                let t = z * tvalue + z
                let d = deriv.compute(t)
                let l = d.x * d.x + d.y * d.y
                result += Cvalues[i] * sqrt(l)
            result *= z

proc approxLen*(curve: Bezier | DynBezier, steps: Positive): float =
    ## Calculates the approximate length of a curve
    for (a, b) in curve.segments(steps):
        result += (b - a).length

when isMainModule:
    include bezier/cli
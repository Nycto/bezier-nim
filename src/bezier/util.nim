import std/math, vmath, options

iterator cubicRoots(pa, pb, pc, pd: float): float =
    # Cardano's algorithm for calculating roots
    block earlyReturn:
        let a = 3 * pa - 6 * pb + 3 * pc
        let b = (-3 * pa + 3 * pb)
        let c = pa
        let d = -pa + 3 * pb - 3 * pc + pd

        # Check to see whether we even need cubic solving:
        if d.almostEqual 0:
            # Not a cubic curve.

            if a.almostEqual 0:
                # Not a quadratic curve either.

                if b.almostEqual 0:
                    # there are no solutions.
                    break earlyReturn

                # linear solution
                yield -c / b
                break earlyReturn

            # quadratic solution
            let q = sqrt(b * b - 4 * a * c)
            yield (q - b) / (2 * a)
            yield (-b - q) / (2 * a)
            break earlyReturn

        # at this point, we know we need a cubic solution.

        let ad = a / d
        let bd = b / d
        let cd = c / d

        let p = (3 * bd - ad * ad) / 3
        let p3 = p / 3
        let q = (2 * ad * ad * ad  - 9 * ad * bd + 27 * cd) / 27
        let q2 = q / 2
        let discriminant = q2 * q2 + p3 * p3 * p3

        # three possible real roots:
        if discriminant < 0:
            let mp3 = -p / 3
            let r = sqrt(mp3 * mp3 * mp3)
            let t = -q / (2 * r)
            let cosphi = t.clamp(-1, 1)
            let phi = arccos(cosphi)
            let t1 = 2 * cbrt(r)
            yield t1 * cos(phi / 3) - ad / 3
            yield t1 * cos((phi + TAU) / 3) - ad / 3
            yield t1 * cos((phi + 2 * TAU) / 3) - ad / 3

        # three real roots, but two of them are equal:
        elif discriminant == 0:
            let u1 = if q2 < 0: cbrt(-q2) else: -cbrt(q2)
            yield 2 * u1 - ad / 3
            yield -u1 - ad / 3

        # one real root, two complex roots
        else:
            let sd = sqrt(discriminant)
            let u1 = cbrt(sd - q2)
            let v1 = cbrt(sd + q2)
            yield u1 - v1 - ad/3

iterator computeRoots[N: static[int]](entries: array[N, float]): float =
    ## Calculate the roots of the given points
    when N > 4:
        {. error("Cannot calculate roots for N over 4") .}

    elif N == 4:
        for root in cubicRoots(entries[0], entries[1], entries[2], entries[3]):
            yield root

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

iterator roots*[N: static[int]](entries: array[N, float]): float =
    ## Calculate the roots of the given points
    for root in computeRoots(entries):
        if root ~= 0:
            yield 0
        elif root ~= 1.0:
            yield 1.0
        elif root >= 0 and root <= 1:
            yield root

template yieldAll*(iter: untyped) =
    for value in iter: yield value

template forIndexed*(i, value, iter, exec: untyped) =
    block:
        var i = 0
        for value in iter:
            exec
            i += 1

proc toArray[T](input: seq[T], N: static int): array[N, T] =
    for i in 0..<N: result[i] = input[i]

iterator roots*(entries: seq[float]): float =
    ## Calculate the roots of the given points
    assert(entries.len <= 4, "Can't yet calculate roots for N = " & $entries.len)
    if entries.len == 2: yieldAll(roots(entries.toArray(2)))
    elif entries.len == 3: yieldAll(roots(entries.toArray(3)))
    elif entries.len == 4: yieldAll(roots(entries.toArray(4)))

proc isOnLine*(point, p1, p2: Vec2): bool =
    # Returns whether `point` is on a line between `p1` and `p2`
    dist(p1, point) + dist(point, p2) == dist(p1, p2)

proc linesIntersect*(p1, p2, p3, p4: Vec2): Option[Vec2] =
    ## Returns the point at which two lines intersect
    let d = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x)
    if d != 0:
        let nx = (p1.x * p2.y - p1.y * p2.x) * (p3.x - p4.x) - (p1.x - p2.x) * (p3.x * p4.y - p3.y * p4.x)
        let ny = (p1.x * p2.y - p1.y * p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x * p4.y - p3.y * p4.x)
        return some(vec2(nx / d, ny / d))

iterator forDistinct*[T](input: seq[T]): T =
    ## Loops over the unique values in an input, assuming it has been pre-sorted
    var prev: Option[float]
    for value in input:
        assert(isNone(prev) or isSome(prev) and unsafeGet(prev) <= value, "Input must be sorted")
        if isNone(prev) or isSome(prev) and unsafeGet(prev) != value:
            yield value
        prev = some(value)

type DeCasteljau* {.byref.} = object
    ## The results of a de Casteljau execution against a set of points
    points: seq[Vec2]
    originalLen: Positive

proc deCasteljau*(points: openarray[Vec2], t: float): DeCasteljau =
    ## Uses de Casteljau's algorithm to determine the location of 't' on a curve
    var buffer = newSeq[Vec2](points.len * (points.len + 1) div 2)

    # Start by filling the buffer with the input points
    for i, value in points: buffer[i] = value

    var inputs = (start: 0, len: points.len)

    while inputs.len > 1:
        let newBlockStart = inputs.start + inputs.len
        for i in 0..<(inputs.len - 1):
            let pointIdx = inputs.start + i
            buffer[newBlockStart + i] = buffer[pointIdx] + (buffer[pointIdx + 1] - buffer[pointIdx]) * t
        inputs.len -= 1
        inputs.start = newBlockStart

    return DeCasteljau(points: buffer, originalLen: points.len)

proc finalPoint*(calculated: DeCasteljau): Vec2 = calculated.points[calculated.points.len - 1]
    ## Returns the caluclated result of running de Casteljau's algorithm

iterator left*(calculated: DeCasteljau): Vec2 =
    ## Yields the left-hand set of points for splitting a curve
    var index = 0
    for step in countDown(calculated.originalLen.int, 1):
        yield calculated.points[index]
        index += step

iterator right*(calculated: DeCasteljau): Vec2 =
    ## Yields the right-hand set of points for splitting a curve
    var index = calculated.points.len - 1
    for step in 1..calculated.originalLen:
        yield calculated.points[index]
        index -= step
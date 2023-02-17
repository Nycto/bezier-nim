import unittest, bezier, vmath, sequtils, sets, tools, options

template standardTests(create: untyped) =
    const b = create(vec2(120, 160))

    test "Can be converted to a string":
        check($b == "Bezier[{120.0, 160.0}]")

    test "Can be compared":
        check(b == create(vec2(120, 160)))
        check(b != create(vec2(130, 170)))

    test "Can be hashed":
        check(b in [b].toHashSet)

    test "Can return points":
        check(b[0] == vec2(120, 160))

    test "Can iterate over points":
        check(b.items.toSeq == @[vec2(120, 160)])

    test "Can iterate over pairs":
        check(b.pairs.toSeq == @[(0, vec2(120, 160))])

    test "Can be mapped":
        check(b.mapIt(vec2(it.x + 20, it.y + 30)) == create(vec2(140, 190)))

    test "Can compute":
        check(b.compute(0.0) == vec2(120.0, 160.0))
        check(b.compute(1.0) == vec2(120.0, 160.0))
        check(b.compute(500.0) == vec2(120.0, 160.0))

    test "Can return Xs and Ys":
        check(b.xs == [120f])
        check(b.ys == [160f])

    test "Can calculate bounding boxes":
        check(b.boundingBox() == (120f, 160f, 120f, 160f))

    test "Can align a line":
        check(b.align(vec2(0, 0), vec2(1, 1)) == create(vec2(197.9898986816406, 28.28427124023438)))

    test "Can create a tight bounding box":
        check(b.tightBoundingBox() == [
            vec2(120.0, 160.0),
            vec2(120.0, 160.0),
            vec2(120.0, 160.0),
            vec2(120.0, 160.0),
        ])

    test "Can produce y values for x":
        check(b.findY(120).toSeq == @[vec2(120, 160)])

    test "Can find max and min y":
        check(b.findMinY(120).get == vec2(120, 160))
        check(b.findMaxY(120).get == vec2(120, 160))

    test "Can produce points":
        check(b.points(5).toSeq == @[
            (0.0, vec2(120.0, 160.0)),
            (0.25, vec2(120.0, 160.0)),
            (0.5, vec2(120.0, 160.0)),
            (0.75, vec2(120.0, 160.0)),
            (1.0, vec2(120.0, 160.0))
        ])

    test "Can produce segments":
        check(b.segments(4).toSeq.len == 0)

    test "Cant calculate the derivative":
        fails:
            discard newDynBezier(vec2(120, 160)).derivative()

    test "Cant calculate extremas":
        fails:
            discard newDynBezier(vec2(120, 160)).extrema().toSeq

    test "Can produce tangents":
        fails:
            discard b.tangent(1.0)

    test "Can produce normals":
        fails:
            discard b.normal(1.0)

    test "Can produce line intersections":
        check(b.intersects(vec2(110, 150), vec2(130, 170)).toSeq == @[vec2(120, 160)])
        check(b.intersects(vec2(210, 250), vec2(230, 270)).toSeq.len == 0)

    test "Can produce lengths":
        check(b.length == 0.0)

    test "Can produce approximate lengths":
        check(b.approxLen(10) == 0.0)

    test "Can project a point":
        check(b.lut(100).project(vec2(100, 100)) == 0.0)

    test "Cant split a curve":
        fails:
            discard b.split(0.5)

    test "Can produce approximate lengths using a LUT":
        check(b.lut(100).approxLen() == 0.0)

    test "Can produce interval points":
        check(b.lut(100).intervals(3).toSeq == @[
            vec2(120, 160),
            vec2(120, 160),
            vec2(120, 160),
            vec2(120, 160),
        ])

suite "Dynamic Constant bezier":
    standardTests(newDynBezier)

suite "Static Constant bezier":
    standardTests(newBezier[0])
import unittest, bezier, vmath, sequtils, sets

template standardTests(create: untyped) =
    const b = create(vec2(0, 0), vec2(100, 100))

    test "Can be converted to a string":
        check($b == "Bezier[{0.0, 0.0}, {100.0, 100.0}]")

    test "Can be compared":
        check(b == create(vec2(0, 0), vec2(100, 100)))
        check(b != create(vec2(0, 0), vec2(110, 110)))

    test "Can be hashed":
        check(b in [b].toHashSet)

    test "Can return points":
        check(b[0] == vec2(0, 0))
        check(b[1] == vec2(100, 100))

    test "Can iterate over points":
        check(b.items.toSeq == @[vec2(0, 0), vec2(100, 100)])

    test "Can iterate over pairs":
        check(b.pairs.toSeq == @[(0, vec2(0, 0)), (1, vec2(100, 100))])

    test "Can be mapped":
        check(b.mapIt(vec2(it.x + 20, it.y + 30)) == create(vec2(20, 30), vec2(120, 130)))

    test "Can compute":
        check(b.compute(0.5) == vec2(50.0, 50.0))

    test "Can return Xs and Ys":
        check(b.xs == [0f, 100])
        check(b.ys == [0f, 100])

    test "Can calculate the derivative":
        let b0 = b.derivative()
        check(b0[0] == vec2(100.0, 100.0))

    test "Can calculate extremas":
        check(b.extrema().toSeq.len == 0)

    test "Can calculate bounding boxes":
        check(b.boundingBox() == (0f, 0f, 100f, 100f))

    test "Can align a line":
        check(b.align(vec2(0, 0), vec2(1, 1)) == create(vec2(0, 0), vec2(141.4213562373095, 0.0)))

    test "Can produce a tight bounding box":
        check(b.tightBoundingBox() == [vec2(0.0, 0.0), vec2(100.0, 100.0), vec2(100.0, 100.0), vec2(0.0, 0.0)])

    test "Can produce y values for x":
        check(b.findY(80).toSeq == @[vec2(80f, 80f)])

    test "Can produce points":
        check(b.points(5).toSeq == @[
            (0.0, vec2(0.0, 0.0)),
            (0.25, vec2(25.0, 25.0)),
            (0.5, vec2(50.0, 50.0)),
            (0.75, vec2(75.0, 75.0)),
            (1.0, vec2(100.0, 100.0))
        ])

    test "Can produce segments":
        check(b.segments(4).toSeq == @[
            (vec2(0.0, 0.0), vec2(25.0, 25.0)),
            (vec2(25.0, 25.0), vec2(50.0, 50.0)),
            (vec2(50.0, 50.0), vec2(75.0, 75.0)),
            (vec2(75.0, 75.0), vec2(100.0, 100.0))
        ])

    test "Can produce tangents":
        check(b.tangent(0.2) == vec2(100.0, 100.0))

    test "Can produce normals":
        check(b.normal(0.2) == vec2(-0.7071067690849304, 0.7071067690849304))

    test "Can produce line intersections":
        check(b.intersects(vec2(0, 100), vec2(100, 0)).toSeq == @[vec2(50, 50)])

    test "Can produce lengths":
        check(b.length == 141.4213562011719)

    test "Can produce approximate lengths":
        check(b.approxLen(10) ~= 141.4213562011719)

    test "Can project a point":
        check(b.lut(100).project(vec2(50, 20)) ~= 0.35)
        check(b.lut(100).project(vec2(-10, -10)) == 0.0)
        check(b.lut(100).project(vec2(200, 120)) == 1.0)

    test "Can split a curve":
        let (left, right) = b.split(0.5)
        check(left == create(vec2(0, 0), vec2(50, 50)))
        check(right == create(vec2(50, 50), vec2(100, 100)))

    test "Can produce approximate lengths using a LUT":
        check(b.lut(100).approxLen() ~= 141.4213562011719)

    test "Can produce interval points":
        check(b.lut(100).intervals(3).toSeq == @[
            vec2(0.0, 0.0),
            vec2(34.34343338012695, 34.34343338012695),
            vec2(67.67676544189453, 67.67676544189453),
            vec2(100.0, 100.0)
        ])

suite "Dynamic Linear bezier":
    standardTests(newDynBezier)

suite "Static Linear bezier":
    standardTests(newBezier[1])
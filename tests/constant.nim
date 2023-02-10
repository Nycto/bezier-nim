import unittest, bezier, vmath, sequtils, sets

suite "Constant bezier":
    const b = newBezier[0](vec2(120, 160))

    test "Can be compared":
        check(b == newBezier[0](vec2(120, 160)))
        check(b != newBezier[0](vec2(130, 170)))

    test "Can be hashed":
        check(b in [b].toHashSet)

    test "Can be mapped":
        check(b.mapIt(vec2(it.x + 20, it.y + 30)) == newBezier[0](vec2(140, 190)))

    test "Can return Xs and Ys":
        check(b.xs == [120f])
        check(b.ys == [160f])

    test "Can compute":
        check(b.compute(0.0) == vec2(120.0, 160.0))
        check(b.compute(1.0) == vec2(120.0, 160.0))
        check(b.compute(500.0) == vec2(120.0, 160.0))

    test "Can return points":
        check(b[0] == vec2(120, 160))

    test "Can iterate over points":
        check(b.items.toSeq == @[vec2(120, 160)])

    test "Can calculate the derivative":
        check(compiles(b.derivative()) == false)

    test "Can calculate extremas":
        check(compiles(b.extrema()) == false)

    test "Can calculate bounding boxes":
        check(b.boundingBox() == (120f, 160f, 120f, 160f))

    test "Can align a line":
        check(b.align(vec2(0, 0), vec2(1, 1)) == newBezier[0](vec2(197.9898986816406, 28.28427124023438)))

    test "Can create a tight bounding box":
        check(b.tightBoundingBox() == [
            vec2(120.0, 160.0),
            vec2(120.0, 160.0),
            vec2(120.0, 160.0),
            vec2(120.0, 160.0),
        ])

    test "Can produce y values for x":
        check(b.findY(120).toSeq == @[vec2(120, 160)])

    test "Can produce segments":
        check(b.segments(4).toSeq.len == 0)

    test "Can produce tangents":
        check(compiles(b.tangent(1.0)) == false)

    test "Can produce normals":
        check(compiles(b.normal(1.0)) == false)

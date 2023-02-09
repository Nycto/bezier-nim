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
import unittest, bezier, vmath, sequtils

suite "Constant bezier":
    const b = newBezier[0](vec2(120, 160))

    test "Can be compared":
        check(b == newBezier[0](vec2(120, 160)))
        check(b != newBezier[0](vec2(130, 170)))

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
import unittest, bezier, vmath, sequtils, sets

suite "Linear bezier":
    const b = newBezier[1](vec2(0, 0), vec2(100, 100))

    test "Can be compared":
        check(b == newBezier[1](vec2(0, 0), vec2(100, 100)))
        check(b != newBezier[1](vec2(0, 0), vec2(110, 110)))

    test "Can be hashed":
        check(b in [b].toHashSet)

    test "Can be mapped":
        check(b.mapIt(vec2(it.x + 20, it.y + 30)) == newBezier[1](vec2(20, 30), vec2(120, 130)))

    test "Can return Xs and Ys":
        check(b.xs == [0f, 100])
        check(b.ys == [0f, 100])

    test "Can compute":
        check(b.compute(0.5) == vec2(50.0, 50.0))

    test "Can return points":
        check(b[0] == vec2(0, 0))
        check(b[1] == vec2(100, 100))

    test "Can iterate over points":
        check(b.items.toSeq == @[vec2(0, 0), vec2(100, 100)])

    test "Can calculate the derivative":
        const b0 = b.derivative()
        check(b0[0] == vec2(100.0, 100.0))

    test "Can calculate extremas":
        check(b.extrema().toSeq.len == 0)

    test "Can calculate bounding boxes":
        check(b.boundingBox() == (0f, 0f, 100f, 100f))

    test "Can align a line":
        check(b.align(vec2(0, 0), vec2(1, 1)) == newBezier[1](vec2(0, 0), vec2(141.4213562373095, 0.0)))
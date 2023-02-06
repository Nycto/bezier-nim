import unittest, bezier, vmath, sequtils

suite "Quadratic bezier":
    const b = newBezier[2](vec2(70, 155), vec2(20, 110), vec2(100, 75))

    test "can compute":
        check(b.compute(0.0) == vec2(70, 155))
        check(b.compute(1) == vec2(100, 75))

    test "Can return points":
        check(b[0] == vec2(70, 155))
        check(b[1] == vec2(20, 110))
        check(b[2] == vec2(100, 75))

    test "Can iterate over points":
        check(b.items.toSeq == @[vec2(70, 155), vec2(20, 110), vec2(100, 75)])

    test "Can calculate the derivative":
        const b1 = b.derivative()
        check(b1[0] == vec2(-100.0, -90.0))
        check(b1[1] == vec2(160.0, -70.0))

    test "Can calculate extremas":
        check(b.extrema().toSeq == @[ 0.38461538461538464f ])
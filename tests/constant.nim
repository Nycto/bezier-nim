import unittest, bezier, vmath

suite "Constant bezier":
    const b = newBezier[0](vec2(120, 160))

    test "Can compute":
        check(b.compute(0.0) == vec2(120.0, 160.0))
        check(b.compute(1.0) == vec2(120.0, 160.0))
        check(b.compute(500.0) == vec2(120.0, 160.0))

    test "Can return points":
        check(b[0] == vec2(120, 160))
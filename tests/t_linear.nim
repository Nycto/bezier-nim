import unittest, bezier, vmath

suite "Linear bezier":
    const b = newBezier[1](vec2(0, 0), vec2(100, 100))

    test "Can compute":
        check(b.compute(0.5) == vec2(50.0, 50.0))

    test "Can return points":
        check(b[0] == vec2(0, 0))
        check(b[1] == vec2(100, 100))
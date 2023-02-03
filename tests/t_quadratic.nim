import unittest, bezier, vmath

suite "Quadratic bezier":
    const b = newBezier[2](vec2(70, 155), vec2(20, 110), vec2(100, 75))
    test "can compute":
        check(b.compute(0.0) == vec2(70, 155))
        check(b.compute(1) == vec2(100, 75))
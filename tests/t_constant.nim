import unittest, bezier, vmath

suite "Constant bezier":
    test "Can compute":
        const b = newBezier[0](vec2(120, 160))
        check(b.compute(0.0) == vec2(120.0, 160.0))
        check(b.compute(1.0) == vec2(120.0, 160.0))
        check(b.compute(500.0) == vec2(120.0, 160.0))
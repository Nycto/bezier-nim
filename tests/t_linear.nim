import unittest, bezier, vmath

suite "Linear bezier":
    test "Can compute":
        const b = newBezier[1](vec2(0, 0), vec2(100, 100))
        check(b.compute(0.5) == vec2(50.0, 50.0))
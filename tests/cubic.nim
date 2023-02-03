import unittest, bezier, vmath

suite "Cubic bezier":
    const b = newBezier[3](vec2(0, 15), vec2(3, 0), vec2(15, 2), vec2(10, 14))

    test "can compute":
        check(b.compute(0) == vec2(0, 15))
        check(b.compute(0.5) == vec2(8, 4.375))
        check(b.compute(1.0) == vec2(10, 14))

    test "Can return points":
        check(b[0] == vec2(0, 15))
        check(b[1] == vec2(3, 0))
        check(b[2] == vec2(15, 2))
        check(b[3] == vec2(10, 14))

    test "Can calculate the derivative":
        const b3 = newBezier[3](vec2(120, 160), vec2(35,  200), vec2(220, 260), vec2(220,  40))
        const b2 = b3.derivative()
        check(b2[0] == vec2(-255.0, 120.0))
        check(b2[1] == vec2(555.0, 180.0))
        check(b2[2] == vec2(0.0, -660.0))
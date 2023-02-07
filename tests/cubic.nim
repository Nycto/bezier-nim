import unittest, bezier, vmath, sequtils, sets

suite "Cubic bezier":
    const b = newBezier[3](vec2(0, 15), vec2(3, 0), vec2(15, 2), vec2(10, 14))
    const b2 = newBezier[3](vec2(120, 160), vec2(35,  200), vec2(220, 260), vec2(220,  40))

    test "Can be compared":
        check(b == newBezier[3](vec2(0, 15), vec2(3, 0), vec2(15, 2), vec2(10, 14)))
        check(b != newBezier[3](vec2(0, 15), vec2(3, 1), vec2(15, 2), vec2(10, 14)))

    test "Can be hashed":
        check(b in [b].toHashSet)

    test "Can be mapped":
        check(b.mapIt(vec2(it.x + 2, it.y + 3)) == newBezier[3](vec2(2, 18), vec2(5, 3), vec2(17, 5), vec2(12, 17)))

    test "Can return Xs and Ys":
        check(b.xs == [0f, 3, 15, 10])
        check(b.ys == [15f, 0, 2, 14])

    test "can compute":
        check(b.compute(0) == vec2(0, 15))
        check(b.compute(0.5) == vec2(8, 4.375))
        check(b.compute(1.0) == vec2(10, 14))

    test "Can return points":
        check(b[0] == vec2(0, 15))
        check(b[1] == vec2(3, 0))
        check(b[2] == vec2(15, 2))
        check(b[3] == vec2(10, 14))

    test "Can iterate over points":
        check(b.items.toSeq == @[vec2(0, 15), vec2(3, 0), vec2(15, 2), vec2(10, 14)])

    test "Can calculate the derivative":
        const deriv = b2.derivative()
        check(deriv[0] == vec2(-255.0, 120.0))
        check(deriv[1] == vec2(555.0, 180.0))
        check(deriv[2] == vec2(0.0, -660.0))

    test "Can calculate extremas":
        check(b2.extrema().toSeq == @[
            0.06666666666666667f,
            0.18681318681318682f,
            0.4378509575220014f,
            0.5934065934065934f,
            1f
        ])

    test "Can calculate bounding boxes":
        check(b2.boundingBox() == (97.66453326892888f, 40f, 220f, 198.86234582181876f))
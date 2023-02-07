import unittest, bezier, vmath, sequtils, sets

suite "Quadratic bezier":
    const b = newBezier[2](vec2(70, 155), vec2(20, 110), vec2(100, 75))

    test "Can be compared":
        check(b == newBezier[2](vec2(70, 155), vec2(20, 110), vec2(100, 75)))
        check(b != newBezier[2](vec2(70, 155), vec2(20, 110), vec2(200, 75)))

    test "Can be hashed":
        check(b in [b].toHashSet)

    test "Can be mapped":
        check(b.mapIt(vec2(it.x + 20, it.y + 30)) == newBezier[2](vec2(90, 185), vec2(40, 140), vec2(120, 105)))

    test "Can return Xs and Ys":
        check(b.xs == [70f, 20, 100])
        check(b.ys == [155f, 110, 75])

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

    test "Can calculate bounding boxes":
        check(b.boundingBox() == (50.76922988891602f, 75f, 100f, 155f))
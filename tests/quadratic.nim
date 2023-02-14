import unittest, bezier, vmath, sequtils, sets

template standardTests(create: untyped) =
    let b = create(vec2(70, 155), vec2(20, 110), vec2(100, 75))

    test "Can be converted to a string":
        check($b == "Bezier[{70.0, 155.0}, {20.0, 110.0}, {100.0, 75.0}]")

    test "Can be compared":
        check(b == create(vec2(70, 155), vec2(20, 110), vec2(100, 75)))
        check(b != create(vec2(70, 155), vec2(20, 110), vec2(200, 75)))

    test "Can be hashed":
        check(b in [b].toHashSet)

    test "Can return points":
        check(b[0] == vec2(70, 155))
        check(b[1] == vec2(20, 110))
        check(b[2] == vec2(100, 75))

    test "Can iterate over points":
        check(b.items.toSeq == @[vec2(70, 155), vec2(20, 110), vec2(100, 75)])

    test "Can iterate over pairs":
        check(b.pairs.toSeq == @[(0, vec2(70, 155)), (1, vec2(20, 110)), (2, vec2(100, 75))])

    test "Can be mapped":
        check(b.mapIt(vec2(it.x + 20, it.y + 30)) == create(vec2(90, 185), vec2(40, 140), vec2(120, 105)))

    test "can compute":
        check(b.compute(0.0) == vec2(70, 155))
        check(b.compute(1) == vec2(100, 75))

    test "Can return Xs and Ys":
        check(b.xs == [70f, 20, 100])
        check(b.ys == [155f, 110, 75])

    test "Can calculate the derivative":
        let b1 = b.derivative()
        check(b1[0] == vec2(-100.0, -90.0))
        check(b1[1] == vec2(160.0, -70.0))

    test "Can calculate extremas":
        check(b.extrema().toSeq == @[ 0.38461538461538464f ])

    test "Can calculate bounding boxes":
        check(b.boundingBox() == (50.76922988891602f, 75f, 100f, 155f))

    test "Can align a line":
        check(b.align(vec2(0, 0), vec2(1, 1)) == create(
            vec2(159.0990295410156, 60.10407257080078),
            vec2(91.92388153076172, 63.63961029052734),
            vec2(123.7436828613281, -17.67766952514648)
        ))

    test "Can produce a tight bounding box":
        check(b.tightBoundingBox() == [
            vec2(40.68492889404297, 144.0068511962891),
            vec2(70.68492889404297, 64.00685119628906),
            vec2(100.0, 75.0),
            vec2(70.0, 155.0)
        ])

    test "Can produce y values for x":
        check(b.findY(80).toSeq == @[vec2(79.99999237060547f, 85.08329772949219f)])

    test "Can produce segments":
        check(b.segments(4).toSeq == @[
            (vec2(70.0, 155.0), vec2(53.125, 133.125)),
            (vec2(53.125, 133.125), vec2(52.5, 112.5)),
            (vec2(52.5, 112.5), vec2(68.125, 93.125)),
            (vec2(68.125, 93.125), vec2(100.0, 75.0))
        ])

    test "Can produce tangents":
        check(b.tangent(0.2) == vec2(-48.0, -86.0))

    test "Can produce normals":
        check(b.normal(0.2) == vec2(0.8731976747512817, -0.4873661696910858))

    test "Can produce line intersections":
        check(b.intersects(vec2(60, 0), vec2(60, 200)).toSeq == @[
            vec2(59.99999618530273, 144.5064392089844),
            vec2(60.0, 100.641487121582)
        ])
        check(b.intersects(vec2(0, 16), vec2(30, 16)).toSeq.len == 0)

suite "Dynamic Quadratic bezier":
    standardTests(newDynBezier)

suite "Static Quadratic bezier":
    standardTests(newBezier[2])
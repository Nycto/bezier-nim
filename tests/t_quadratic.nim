import unittest, bezier, vmath, sequtils, sets, options

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
        check(b.xs == [70.0, 20, 100])
        check(b.ys == [155.0, 110, 75])

    test "Can calculate the derivative":
        let b1 = b.derivative()
        check(b1[0] == vec2(-100.0, -90.0))
        check(b1[1] == vec2(160.0, -70.0))

    test "Can calculate extremas":
        check(b.extrema().toSeq == @[ 0.38461538461538464 ])

    test "Can calculate bounding boxes":
        check(b.boundingBox().minX ~= 50.76922988891602)
        check(b.boundingBox().maxX == 100.0)
        check(b.boundingBox().minY == 75.0)
        check(b.boundingBox().maxY == 155.0)

    test "Can align a line":
        check(b.align(vec2(0, 0), vec2(1, 1)) == create(
            vec2(159.0990295410156, 60.10407257080078),
            vec2(91.92388153076172, 63.63961029052734),
            vec2(123.7436828613281, -17.67766952514648)
        ))

    test "Can produce a tight bounding box":
        check(b.tightBoundingBox() == [
            vec2(40.68492889404297, 144.0068511962891),
            vec2(70.68492889404297, 64.00684356689453),
            vec2(100.0, 75.0), vec2(70.0, 155.0)
        ])

    test "Can produce y values for x":
        check(b.findY(80).toSeq == @[vec2(80.0, 85.08329772949219)])

    test "Can find max and min y":
        check(b.findMinY(80).get == vec2(80.0, 85.08329772949219))
        check(b.findMaxY(80).get == vec2(80.0, 85.08329772949219))

    test "Can produce points":
        check(b.points(5).toSeq == @[
            (0.0, vec2(70.0, 155.0)),
            (0.25, vec2(53.125, 133.125)),
            (0.5, vec2(52.5, 112.5)),
            (0.75, vec2(68.125, 93.125)),
            (1.0, vec2(100.0, 75.0))
        ])

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
            vec2(59.99999237060547, 144.5064392089844),
            vec2(59.99999618530273, 100.6414947509766)
        ])
        check(b.intersects(vec2(0, 16), vec2(30, 16)).toSeq.len == 0)

    test "Can produce lengths":
        check(b.length ~= 110.9647527950121)

    test "Can produce approximate lengths":
        check(b.approxLen(10) ~= 110.7825956344604)

    test "Can project a point":
        check(b.lut(100).project(vec2(5, 5)) == 0.768)
        check(b.lut(100).project(vec2(50, 200)) == 0.0)
        check(b.lut(100).project(vec2(200, 50)) == 1.0)

    test "Can split a curve":
        let (left, right) = b.split(0.5)
        check(left == create(vec2(70, 155), vec2(45, 132.5), vec2(52.5, 112.5)))
        check(right == create(vec2(52.5, 112.5), vec2(60, 92.5), vec2(100, 75)))

    test "Can produce approximate lengths using a LUT":
        check(b.lut(100).approxLen() ~= 110.9628931283951)

    test "Can produce interval points":
        check(b.lut(100).intervals(3).toSeq == @[
            vec2(70.0, 155.0),
            vec2(50.82644653320312, 123.5950393676758),
            vec2(68.85215759277344, 92.55738830566406),
            vec2(100.0, 75.0)
        ])

suite "Dynamic Quadratic bezier":
    standardTests(newDynBezier)

suite "Static Quadratic bezier":
    standardTests(newBezier[2])
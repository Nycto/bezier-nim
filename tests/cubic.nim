import unittest, bezier, vmath, sequtils, sets

template standardTests(create: untyped) =
    const b = create(vec2(0, 15), vec2(3, 0), vec2(15, 2), vec2(10, 14))
    const b2 = create(vec2(120, 160), vec2(35,  200), vec2(220, 260), vec2(220,  40))

    test "Can be converted to a string":
        check($b == "Bezier[{0.0, 15.0}, {3.0, 0.0}, {15.0, 2.0}, {10.0, 14.0}]")

    test "Can be compared":
        check(b == create(vec2(0, 15), vec2(3, 0), vec2(15, 2), vec2(10, 14)))
        check(b != create(vec2(0, 15), vec2(3, 1), vec2(15, 2), vec2(10, 14)))

    test "Can be hashed":
        check(b in [b].toHashSet)

    test "Can return points":
        check(b[0] == vec2(0, 15))
        check(b[1] == vec2(3, 0))
        check(b[2] == vec2(15, 2))
        check(b[3] == vec2(10, 14))

    test "Can iterate over points":
        check(b.items.toSeq == @[vec2(0, 15), vec2(3, 0), vec2(15, 2), vec2(10, 14)])

    test "Can iterate over apris":
        check(b.pairs.toSeq == @[(0, vec2(0, 15)), (1, vec2(3, 0)), (2, vec2(15, 2)), (3, vec2(10, 14))])

    test "Can be mapped":
        check(b.mapIt(vec2(it.x + 2, it.y + 3)) == create(vec2(2, 18), vec2(5, 3), vec2(17, 5), vec2(12, 17)))

    test "can compute":
        check(b.compute(0) == vec2(0, 15))
        check(b.compute(0.5) == vec2(8, 4.375))
        check(b.compute(1.0) == vec2(10, 14))

    test "Can return Xs and Ys":
        check(b.xs == [0f, 3, 15, 10])
        check(b.ys == [15f, 0, 2, 14])

    test "Can calculate the derivative":
        let deriv = b2.derivative()
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

suite "Dynamic Cubic bezier":
    standardTests(newDynBezier)

suite "Static Cubic bezier":
    standardTests(newBezier[3])

    const b = newBezier[3](vec2(0, 15), vec2(3, 0), vec2(15, 2), vec2(10, 14))
    const b2 = newBezier[3](vec2(120, 160), vec2(35,  200), vec2(220, 260), vec2(220,  40))

    test "Can calculate bounding boxes":
        check(b2.boundingBox() == (97.66453326892888f, 40f, 220f, 198.86234582181876f))

    test "Can align a line":
        check(b.align(vec2(0, 0), vec2(1, 1)) == newBezier[3](
            vec2(10.60660171508789f, 10.60660171508789f),
            vec2(2.121320247650146f, -2.121320247650146f),
            vec2(12.02081489562988f, -9.192388534545898f),
            vec2(16.97056198120117f, 2.828427314758301f)
        ))

    test "Can produce a tight bounding box":
        check(b.tightBoundingBox() == [
            vec2(-0.9763734936714172, 5.236265182495117),
            vec2(10.76858520507812, 4.061769485473633),
            vec2(11.74495887756348, 13.82550430297852),
            vec2(0.0, 15.0)
        ])

    test "Can produce y values for x":
        check(b2.findY(115).toSeq == @[
            vec2(115.0000076293945f, 162.5425720214844f),
            vec2(115.0000152587891f, 197.7810821533203f)
        ])

    test "Can produce segments":
        check(b.segments(4).toSeq == @[
            (vec2(0.0, 15.0), vec2(3.53125, 6.828125)),
            (vec2(3.53125, 6.828125), vec2(8.0, 4.375)),
            (vec2(8.0, 4.375), vec2(10.96875, 6.984375)),
            (vec2(10.96875, 6.984375), vec2(10.0, 14.0))
        ])

    test "Can produce tangents":
        check(b.tangent(0.2) == vec2(16.68000030517578, -25.44000053405762))

    test "Can produce normals":
        check(b.normal(0.2) == vec2(0.8362740278244019, 0.5483117699623108))

    test "Can produce line intersections":
        check(b.intersects(vec2(0, 6), vec2(30, 6)).toSeq == @[
            vec2(4.319429874420166, 6.000003337860107),
            vec2(10.56313800811768, 6.000006198883057)
        ])
        check(b.intersects(vec2(0, 106), vec2(30, 106)).toSeq.len == 0)
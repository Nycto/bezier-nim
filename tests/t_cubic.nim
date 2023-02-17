import unittest, bezier, vmath, sequtils, sets, options

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
        check(b.xs == [0.0, 3, 15, 10])
        check(b.ys == [15.0, 0, 2, 14])

    test "Can calculate the derivative":
        let deriv = b2.derivative()
        check(deriv[0] == vec2(-255.0, 120.0))
        check(deriv[1] == vec2(555.0, 180.0))
        check(deriv[2] == vec2(0.0, -660.0))

    test "Can calculate extremas":
        check(b2.extrema().toSeq == @[
            0.06666666666666667,
            0.18681318681318682,
            0.4378509575220014,
            0.5934065934065934,
            1
        ])

    test "Can calculate bounding boxes":
        check(b2.boundingBox() == (minX: 97.66453552246094, minY: 40.0, maxX: 220.0, maxY: 198.8623504638672))

    test "Can align a line":
        check(b.align(vec2(0, 0), vec2(1, 1)) == create(
            vec2(10.60660171508789f, 10.60660171508789f),
            vec2(2.121320247650146f, -2.121320247650146f),
            vec2(12.02081489562988f, -9.192388534545898f),
            vec2(16.97056198120117f, 2.828427314758301f)
        ))

    test "Can produce a tight bounding box":
        check(b.tightBoundingBox() == [
            vec2(-0.9763734936714172, 5.236264705657959),
            vec2(10.76858520507812, 4.061769008636475),
            vec2(11.74495887756348, 13.82550430297852),
            vec2(0.0, 15.0)
        ])

    test "Can produce y values for x":
        check(b2.findY(115).toSeq == @[
            vec2(115.0, 162.5425720214844),
            vec2(115.0, 197.7810821533203)
        ])

    test "Can find max and min y":
        check(b2.findMinY(115).get == vec2(115.0, 162.5425720214844f))
        check(b2.findMaxY(115).get == vec2(115.0, 197.7810821533203))

    test "Can produce points":
        check(b.points(5).toSeq == @[
            (0.0, vec2(0.0, 15.0)),
            (0.25, vec2(3.53125, 6.828125)),
            (0.5, vec2(8.0, 4.375)),
            (0.75, vec2(10.96875, 6.984375)),
            (1.0, vec2(10.0, 14.0))
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
            vec2(4.319433212280273, 6.0), vec2(10.56313419342041, 6.0)
        ])
        check(b.intersects(vec2(0, 106), vec2(30, 106)).toSeq.len == 0)

    test "Can produce lengths":
        check(b.length == 25.71692271231104)

    test "Can produce approximate lengths":
        check(b.approxLen(10) ~= 25.60836708545685)

    test "Can project a point":
        check(b.lut(100).project(vec2(5, 5)) == 0.342)
        check(b.lut(100).project(vec2(-10, 40)) == 0.0)
        check(b.lut(100).project(vec2(50, 40)) == 1.0)

    test "Can split a curve":
        let (left, right) = b.split(0.5)
        check(left == create(vec2(0.0, 15.0), vec2(1.5, 7.5), vec2(5.25, 4.25), vec2(8.0, 4.375)))
        check(right == create(vec2(8.0, 4.375), vec2(10.75, 4.5), vec2(12.5, 8.0), vec2(10.0, 14.0)))

    test "Can produce approximate lengths using a LUT":
        check(b.lut(100).approxLen() ~= 25.71581511199474)

    test "Can produce interval points":
        check(b.lut(100).intervals(3).toSeq == @[
            vec2(0.0, 15.0),
            vec2(3.398169040679932, 6.988424301147461),
            vec2(10.49463272094727, 5.883729457855225),
            vec2(10.0, 14.0)
        ])

suite "Dynamic Cubic bezier":
    standardTests(newDynBezier)

suite "Static Cubic bezier":
    standardTests(newBezier[3])
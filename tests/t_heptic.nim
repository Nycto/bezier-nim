import unittest, bezier, vmath, sets, sequtils, tools

template standardTests(create: untyped) =
    const b = create(
        vec2(58.0, 24.0),
        vec2(43.0, 59.0),
        vec2(84.0, 117.0),
        vec2(205.0, 33.0),
        vec2(146.0, 143.0),
        vec2(33.0, 159.0),
        vec2(27.0, 267.0),
        vec2(114.0, 285.0),
        vec2(220.0, 250.0),
        vec2(175.0, 178.0),
    )

    test "Can be converted to a string":
        check($b == "Bezier[{58.0, 24.0}, {43.0, 59.0}, {84.0, 117.0}, {205.0, 33.0}, {146.0, 143.0}, {33.0, 159.0}, {27.0, 267.0}, {114.0, 285.0}, {220.0, 250.0}, {175.0, 178.0}]")

    test "Can be compared":
        check(b == create(
            vec2(58.0, 24.0),
            vec2(43.0, 59.0),
            vec2(84.0, 117.0),
            vec2(205.0, 33.0),
            vec2(146.0, 143.0),
            vec2(33.0, 159.0),
            vec2(27.0, 267.0),
            vec2(114.0, 285.0),
            vec2(220.0, 250.0),
            vec2(175.0, 178.0),
        ))
        check(b != create(
            vec2(0, 24.0),
            vec2(0, 59.0),
            vec2(0, 117.0),
            vec2(0, 33.0),
            vec2(0, 143.0),
            vec2(0, 159.0),
            vec2(0, 267.0),
            vec2(0, 285.0),
            vec2(0, 250.0),
            vec2(0, 178.0),
        ))

    test "Can be hashed":
        check(b in [b].toHashSet)

    test "Can iterate over points":
        check(b.items.toSeq == @[
            vec2(58.0, 24.0),
            vec2(43.0, 59.0),
            vec2(84.0, 117.0),
            vec2(205.0, 33.0),
            vec2(146.0, 143.0),
            vec2(33.0, 159.0),
            vec2(27.0, 267.0),
            vec2(114.0, 285.0),
            vec2(220.0, 250.0),
            vec2(175.0, 178.0),
        ])

    test "Can iterate over pairs":
        check(b.pairs.toSeq == @[
            (0, vec2(58.0, 24.0)),
            (1, vec2(43.0, 59.0)),
            (2, vec2(84.0, 117.0)),
            (3, vec2(205.0, 33.0)),
            (4, vec2(146.0, 143.0)),
            (5, vec2(33.0, 159.0)),
            (6, vec2(27.0, 267.0)),
            (7, vec2(114.0, 285.0)),
            (8, vec2(220.0, 250.0)),
            (9, vec2(175.0, 178.0)),
        ])

    test "Can be mapped":
        check(b.mapIt(vec2(it.x + 20, it.y + 30)) == create(
            vec2(78.0, 54.0),
            vec2(63.0, 89.0),
            vec2(104.0, 147.0),
            vec2(225.0, 63.0),
            vec2(166.0, 173.0),
            vec2(53.0, 189.0),
            vec2(47.0, 297.0),
            vec2(134.0, 315.0),
            vec2(240.0, 280.0),
            vec2(195.0, 208.0)
        ))

    test "Can compute":
        check(b.compute(0) == vec2(58.0, 24.0))
        check(b.compute(0.5) == vec2(101.11328125, 157.630859375))
        check(b.compute(1.0) == vec2(175, 178))

    test "Can return Xs and Ys":
        check(b.xs == [58.0f, 43.0, 84.0, 205.0, 146.0, 33.0, 27.0, 114.0, 220.0, 175.0])
        check(b.ys == [24.0f, 59.0, 117.0, 33.0, 143.0, 159.0, 267.0, 285.0, 250.0, 178.0])

    test "Can calculate the derivative":
        check(b.derivative().items.toSeq == @[
            vec2(-135.0, 315.0),
            vec2(369.0, 522.0),
            vec2(1089.0, -756.0),
            vec2(-531.0, 990.0),
            vec2(-1017.0, 144.0),
            vec2(-54.0, 972.0),
            vec2(783.0, 162.0),
            vec2(954.0, -315.0),
            vec2(-405.0, -648.0)
        ])

    test "Cant calculate extremas":
        fails:
            discard b.extrema().toSeq

    test "Cant calculate bounding boxes":
        fails:
            discard b.boundingBox()

    test "Can align a line":
        check(b.align(vec2(0, 0), vec2(1, 1)) == create(
            vec2(57.98275375366211, -24.04162979125977),
            vec2(72.12489318847656, 11.31370735168457),
            vec2(142.1284637451172, 23.33452224731445),
            vec2(168.2914123535156, -121.6223678588867),
            vec2(204.3538513183594, -2.121322631835938),
            vec2(135.7644958496094, 89.09545135498047),
            vec2(207.8893890380859, 169.7056121826172),
            vec2(282.1356201171875, 120.9152679443359),
            vec2(332.3401794433594, 21.21319580078125),
            vec2(249.6086883544922, 2.121322631835938)
        ))

    test "Cant produce a tight bounding box":
        fails:
            discard b.tightBoundingBox()

    test "Cant produce y values for x":
        fails:
            discard b.findY(0.5)

    test "Can produce points":
        check(b.points(5).toSeq == @[
            (0.0, vec2(58.0, 24.0)),
            (0.25, vec2(105.8918075561523, 83.52153015136719)),
            (0.5, vec2(101.11328125, 157.630859375)),
            (0.75, vec2(114.6620559692383, 242.2200927734375)),
            (1.0, vec2(175.0, 178.0))
        ])

    test "Can produce segments":
        check(b.segments(4).toSeq == @[
            (vec2(58.0, 24.0), vec2(105.8918075561523, 83.52153015136719)),
            (vec2(105.8918075561523, 83.52153015136719), vec2(101.11328125, 157.630859375)),
            (vec2(101.11328125, 157.630859375), vec2(114.6620559692383, 242.2200927734375)),
            (vec2(114.6620559692383, 242.2200927734375), vec2(175.0, 178.0))
        ])

    test "Can produce tangents":
        check(b.tangent(0.2) == vec2(296.7718811035156, 167.054931640625))

    test "Can produce normals":
        check(b.normal(0.2) == vec2(-0.4905305504798889, 0.8714239597320557))

    test "Cant produce line intersections":
        fails:
            discard b.intersects(vec2(0, 100), vec2(100, 0)).toSeq

    test "Can produce lengths":
        check(b.length == 380.961106309944)

    test "Can produce approximate lengths":
        check(b.approxLen(10) == 370.3347358703613)

    test "Can project a point":
        check(b.lut(100).project(vec2(10, 150)) == 0.544)
        check(b.lut(100).project(vec2(80, 0)) == 0.0)
        check(b.lut(100).project(vec2(200, 150)) == 1.0)

    test "Can split a curve":
        let (left, right) = b.split(0.5)
        check(left == create(
            vec2(58.0, 24.0),
            vec2(50.5, 41.5),
            vec2(57.0, 64.75),
            vec2(80.5, 73.125),
            vec2(106.25, 77.3125),
            vec2(122.6875, 84.15625),
            vec2(126.421875, 96.234375),
            vec2(120.34375, 113.6484375),
            vec2(110.1171875, 134.921875),
            vec2(101.11328125, 157.630859375)
        ))
        check(right == create(
            vec2(101.11328125, 157.630859375),
            vec2(92.109375, 180.33984375),
            vec2(84.328125, 204.484375),
            vec2(83.140625, 227.640625),
            vec2(93.625, 246.4375),
            vec2(117.5, 257.1875),
            vec2(150.5, 256.25),
            vec2(182.25, 240.75),
            vec2(197.5, 214.0),
            vec2(175.0, 178.0)
        ))

    test "Can produce approximate lengths using a LUT":
        check(b.lut(100).approxLen() ~= 380.8526604175568)

suite "Dynamic Decic bezier":
    standardTests(newDynBezier)

suite "Static Decic bezier":
    standardTests(newBezier[9])
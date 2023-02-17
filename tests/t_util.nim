import unittest, bezier/util, sequtils, vmath, tools

suite "Root calculation":

    test "Linear roots":
        check(roots[2]([ 20.0, 70 ]).toSeq.len == 0)
        check(roots[2]([ -20.0, 70 ]).toSeq == @[0.2222222222222222])

    test "Quadratic roots":
        check(roots[3]([ 70.0, 20, 100 ]).toSeq.len == 0)
        check(roots[3]([ -20.0, -70, 30 ]).toSeq == @[0.8277465658063775])

    test "Cubic roots":
        check(roots[4]([ 100.0, 100, 100, 100 ]).toSeq.len == 0)
        check(roots[4]([ 30.0, 20, 10, 0 ]).toSeq == @[1.0])
        check(roots[4]([ 60.0, 30, 10, 0 ]).toSeq == @[1.0])

        check(roots[4]([ -49.0, 107, -128, 64 ]).toSeq ~= @[
            0.8342678300291266, 0.1652736542911705, 0.4344438457530524
        ])

        check(roots[4]([ 7.5, 10, 10, 0 ]).toSeq == @[ 1.0 ])

        check(roots[4]([ -33.2183, -20, -10, 0 ]).toSeq == @[ 1.0 ])

        check(roots[4]([ 0.0, 40, 180, 400 ]).toSeq == @[ 0.0 ])

suite "de Casteljau's algorithm":
    const calc = deCasteljau([vec2(0, 15), vec2(3, 0), vec2(15, 2), vec2(10, 14)], 0.5)

    test "can produce the value for 't'":
        check(calc.finalPoint == vec2(8, 4.375))

    test "can produce the left hand values for a split":
        check(calc.left.toSeq == @[ vec2(0.0, 15.0), vec2(1.5, 7.5), vec2(5.25, 4.25), vec2(8.0, 4.375) ])

    test "can produce the right hand values for a split":
        check(calc.right.toSeq == @[ vec2(8.0, 4.375), vec2(10.75, 4.5), vec2(12.5, 8.0), vec2(10.0, 14.0) ])

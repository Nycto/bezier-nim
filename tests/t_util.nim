import unittest, bezier/util, sequtils

suite "Root calculation":

    test "Linear roots":
        check(roots[2]([ 20f, 70f ]).toSeq.len == 0)
        check(roots[2]([ -20f, 70f ]).toSeq == @[0.2222222238779068f])

    test "Quadratic roots":
        check(roots[3]([ 70f, 20f, 100f ]).toSeq.len == 0)
        check(roots[3]([ -20f, -70f, 30f ]).toSeq == @[0.8277465658063775f])

    test "Cubic roots":
        check(roots[4]([ 100f, 100f, 100f, 100f ]).toSeq.len == 0)
        check(roots[4]([ 30f, 20f, 10f, 0f ]).toSeq == @[1.0f])
        check(roots[4]([ 60f, 30f, 10f, 0f ]).toSeq == @[1.0f])

        check(roots[4]([ -49f, 107, -128, 64 ]).toSeq == @[
            0.8342677354812622f,
            0.1652735769748688f,
            0.4344440698623657f
        ])

        check(roots[4]([ 7.5f, 10, 10, 0 ]).toSeq == @[ 1.0f ])

        check(roots[4]([ -33.2183f, -20, -10, 0 ]).toSeq == @[ 1.0f ])
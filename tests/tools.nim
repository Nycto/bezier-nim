
template fails*(exec: untyped) =
    when compiles(exec):
        expect(AssertionDefect):
            exec
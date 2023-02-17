import vmath, unittest

template fails*(exec: untyped) =
    when compiles(exec):
        expect(AssertionDefect):
            exec

proc `~=`*(a, b: openarray[SomeFloat]): bool =
    if a.len != b.len:
        return false
    else:
        for i, aValue in a:
            if not (aValue ~= b[i]):
                checkpoint($aValue & " is not about equal to " & $b[i] & " at index " & $i)
                return false
    return true
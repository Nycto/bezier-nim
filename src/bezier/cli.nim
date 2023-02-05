import std/[parseopt, strutils, sequtils], simplepng

# Quick fix for IDE integration
when not (compiles(Bezier)): import ../bezier, vmath

var filename: string = "bezier.png"
var width: int = 500
var height: int = 500
var cliParser = initOptParser()
const linePoints = 500

var nums = newSeq[float32]()

for kind, key, val in cliParser.getopt():
    case kind
    of cmdArgument:
        nums.add(key.parseFloat)
    of cmdLongOption, cmdShortOption:
        case key
        of "filename": filename = val
        of "width", "w": width = val.parseInt
        of "height", "h": height = val.parseInt
        else: assert(false, "Unsupported option: " & key)
    of cmdEnd: assert(false) # cannot happen

assert(nums.len in [ 2, 4, 6, 8 ])

proc draw[N](curve: Bezier[N]) =
    var image = initPixels(width, height)

    for t in 0..linePoints:
        let point = curve.compute(1.0 / linePoints.float * t.float)
        image[point.x.int, height - point.y.int].setColor(0, 0, 0, 255)

    simplePng(filename, image)

let points = countup(0, nums.len - 1, 2).toSeq.mapIt(vec2(nums[it], nums[it + 1]))

case points.len
of 1: draw(newBezier[0](points))
of 2: draw(newBezier[1](points))
of 3: draw(newBezier[2](points))
of 4: draw(newBezier[3](points))
else: assert(false)
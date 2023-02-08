import std/[parseopt, strutils], strformat

# Quick fix for IDE integration
when not (compiles(Bezier)): import ../bezier, vmath

var filename: string = "bezier.html"
var width: int = 500
var height: int = 500
var cliParser = initOptParser()
var showExtrema = false
var showBoundingBox = false
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
        of "extrema", "e": showExtrema = true
        of "boundingBox", "b": showBoundingBox = true
        else: assert(false, "Unsupported option: " & key)
    of cmdEnd: assert(false) # cannot happen

assert(nums.len in [ 2, 4, 6, 8 ])

proc line(p1, p2: Vec2, color: string = "black"): string =
    let p1y = height.float - p1.y
    let p2y = height.float - p2.y
    return &"""<line x1="{p1.x}" y1="{p1y}" x2="{p2.x}" y2="{p2y}" stroke="{color}" />{"\n"}"""

proc dot(center: Vec2, color: string = "red"): string =
    let y = height.float - center.y
    &"""<circle cx="{center.x}" cy="{y}" r="2" fill="{color}" />"""

proc rect(p1, p2: Vec2, color: string): string =
    result.add(line(vec2(p1.x, p1.y), vec2(p1.x, p2.y), color))
    result.add(line(vec2(p1.x, p2.y), vec2(p2.x, p2.y), color))
    result.add(line(vec2(p2.x, p2.y), vec2(p2.x, p1.y), color))
    result.add(line(vec2(p2.x, p1.y), vec2(p1.x, p1.y), color))

proc draw[N](curve: Bezier[N]) =
    var svg = ""

    var previous = -1
    for t in 0..linePoints:
        if previous >= 0:
            let p1 = curve.compute(1.0 / linePoints.float * previous.float)
            let p2 = curve.compute(1.0 / linePoints.float * t.float)
            svg.add(line(p1, p2))
        previous = t

    when compiles(curve.derivative):
        if showExtrema:
            for extrema in curve.extrema:
                svg.add(dot(curve.compute(extrema)))

    if showBoundingBox:
        let box = curve.boundingBox()
        svg.add(rect(vec2(box.minX, box.minY), vec2(box.maxX, box.maxY), "lightgreen"))

    #simplePng(filename, image)
    filename.writeFile([
        """<!DOCTYPE html>""",
        """<html lang="en">""",
        """<body>""",
        &"""<svg width="{width}" height="{height}" xmlns="http://www.w3.org/2000/svg">""",
            """<defs>""",
                """<pattern id="smallGrid" width="10" height="10" patternUnits="userSpaceOnUse">""",
                    """<path d="M 10 0 L 0 0 0 10" fill="none" stroke="#ccc" stroke-width="0.5"/>""",
                """</pattern>""",
                """<pattern id="grid" width="100" height="100" patternUnits="userSpaceOnUse">""",
                    """<rect width="100" height="100" fill="url(#smallGrid)"/>""",
                    """<path d="M 100 0 L 0 0 0 100" fill="none" stroke="#aaa" stroke-width="1"/>""",
                """</pattern>""",
            """</defs>""",
            """<rect width="100%" height="100%" fill="url(#grid)" />""",
            svg,
        """</svg>""",
        """</body>""",
        """</html>"""
    ].join("\n"))

let points = countup(0, nums.len - 1, 2).toSeq.mapIt(vec2(nums[it], nums[it + 1]))

case points.len
of 1: draw(newBezier[0](points))
of 2: draw(newBezier[1](points))
of 3: draw(newBezier[2](points))
of 4: draw(newBezier[3](points))
else: assert(false)
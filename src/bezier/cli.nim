import std/[parseopt, strutils], strformat

# Quick fix for IDE integration
when not (compiles(Bezier)): import ../bezier, vmath

var filename: string = "bezier.html"
var width: int = 500
var height: int = 500
var minX: int = -100
var minY: int = -100
var cliParser = initOptParser()
var showExtrema = false
var showBoundingBox = false
var aligned = false
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
        of "minX": minX = val.parseInt
        of "minY": minY = val.parseInt
        of "extrema", "e": showExtrema = true
        of "boundingBox", "b": showBoundingBox = true
        of "aligned", "a": aligned = true
        else: assert(false, "Unsupported option: " & key)
    of cmdEnd: assert(false) # cannot happen

assert(nums.len in [ 2, 4, 6, 8 ])

proc rawLine(x1, y1, x2, y2: float, color: string): string =
    return &"""<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" />{"\n"}"""

proc line(p1, p2: Vec2, color: string = "black"): string =
    let p1x = p1.x - minX.float
    let p1y = height.float - p1.y + minY.float
    let p2x = p2.x - minX.float
    let p2y = height.float - p2.y + minY.float
    return rawLine(p1x, p1y, p2x, p2y, color)

proc dot(center: Vec2, color: string = "red"): string =
    let y = height.float - center.y + minY.float
    let x = center.x - minX.float
    &"""<circle cx="{x}" cy="{y}" r="2" fill="{color}" />"""

proc rect(p1, p2: Vec2, color: string): string =
    result.add(line(vec2(p1.x, p1.y), vec2(p1.x, p2.y), color))
    result.add(line(vec2(p1.x, p2.y), vec2(p2.x, p2.y), color))
    result.add(line(vec2(p2.x, p2.y), vec2(p2.x, p1.y), color))
    result.add(line(vec2(p2.x, p1.y), vec2(p1.x, p1.y), color))

proc createSvgBody[N](curve: Bezier[N]): string =
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

    return [
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
        rawLine(0, height.float + minY.float, width.float, height.float + minY.float, "blue"),
        rawLine(-minX.float, 0, -minX.float, height.float, "blue"),
        svg,
    ].join("\n")

proc draw[N](curve: Bezier[N]) =
    let body = if aligned:
        createSvgBody(curve.align(curve[0], curve[N]))
    else:
        createSvgBody(curve)
    filename.writeFile([
        """<!DOCTYPE html>""",
        """<html lang="en">""",
        """<body>""",
        &"""<svg width="{width}" height="{height}" xmlns="http://www.w3.org/2000/svg">""",
        body,
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
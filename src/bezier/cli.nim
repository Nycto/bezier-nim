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
var showTightBoundingBox = false
var aligned = false
var x = ""
var showTangent: string = ""
var showNormal: string = ""
var showIntersects: string = ""

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
        of "tightBoundingBox", "t": showTightBoundingBox = true
        of "x": x = val
        of "tan", "tangent": showTangent = val
        of "n", "normal": showNormal = val
        of "i", "intersects": showIntersects = val
        else: assert(false, "Unsupported option: " & key)
    of cmdEnd: assert(false) # cannot happen

assert(nums.len mod 2 == 0)

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

proc createSvgBody(curve: Bezier | DynBezier): string =
    var svg = ""

    for (a, b) in curve.segments(100):
        svg.add(line(a, b))

    when compiles(curve.derivative):
        if showExtrema:
            for extrema in curve.extrema:
                svg.add(dot(curve.compute(extrema)))

    if showBoundingBox:
        let box = curve.boundingBox()
        svg.add(rect(vec2(box.minX, box.minY), vec2(box.maxX, box.maxY), "lightgreen"))

    if showTightBoundingBox:
        let box = curve.tightBoundingBox()
        for i in 0..3: svg.add(line(box[i], box[(i + 1) mod 4], "green"))

    if x != "":
        for point in curve.findY(parseFloat(x)):
            svg.add(dot(point, "darkorange"))

    when compiles(curve.tangent(1.0)):
        if showTangent != "":
            let t = parseFloat(showTangent)
            let pt = curve.compute(t)
            let dv = curve.tangent(t).normalize() * 100
            svg.add(line(vec2(pt.x - dv.x, pt.y - dv.y), vec2(pt.x + dv.x, pt.y + dv.y), "red"))

    when compiles(curve.normal(1.0)):
        if showNormal != "":
            let t = parseFloat(showNormal)
            let pt = curve.compute(t)
            let nv = curve.normal(t).normalize() * 20
            svg.add(line(pt, vec2(pt.x + nv.x, pt.y + nv.y), "red"))

    if showIntersects != "":
        let lineNums = showIntersects.split(",").mapIt(parseFloat(it))
        assert(lineNums.len == 4)
        let point1 = vec2(lineNums[0], lineNums[1])
        let point2 = vec2(lineNums[2], lineNums[3])
        svg.add(line(point1, point2, "lightblue"))
        for point in curve.intersects(point1, point2):
            svg.add(dot(point, "red"))

    return svg

proc draw(curve: Bezier | DynBezier) =
    let body = if aligned:
        createSvgBody(curve.align(curve[0], curve[curve.order]))
    else:
        createSvgBody(curve)
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
        rawLine(0, height.float + minY.float, width.float, height.float + minY.float, "blue"),
        rawLine(-minX.float, 0, -minX.float, height.float, "blue"),
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
else: draw(newDynBezier(points))
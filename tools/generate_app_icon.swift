import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = root.appendingPathComponent("Resources/AppIcon.iconset", isDirectory: true)
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

struct IconOutput {
    let points: Int
    let scale: Int

    var pixels: Int { points * scale }
    var filename: String {
        scale == 1
            ? "icon_\(points)x\(points).png"
            : "icon_\(points)x\(points)@\(scale)x.png"
    }
}

let outputs = [
    IconOutput(points: 16, scale: 1),
    IconOutput(points: 16, scale: 2),
    IconOutput(points: 32, scale: 1),
    IconOutput(points: 32, scale: 2),
    IconOutput(points: 128, scale: 1),
    IconOutput(points: 128, scale: 2),
    IconOutput(points: 256, scale: 1),
    IconOutput(points: 256, scale: 2),
    IconOutput(points: 512, scale: 1),
    IconOutput(points: 512, scale: 2)
]

func drawIconPNG(size: Int) -> Data {
    let canvas = NSRect(x: 0, y: 0, width: size, height: size)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Could not create bitmap rep")
    }

    rep.size = canvas.size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    NSColor.clear.setFill()
    canvas.fill()

    let outer = canvas

    let background = NSBezierPath(
        roundedRect: outer,
        xRadius: CGFloat(size) * 0.21,
        yRadius: CGFloat(size) * 0.21
    )

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.82, green: 0.96, blue: 1.0, alpha: 1),
        NSColor(calibratedRed: 0.23, green: 0.69, blue: 0.93, alpha: 1),
        NSColor(calibratedRed: 0.34, green: 0.47, blue: 0.95, alpha: 1)
    ])!
    gradient.draw(in: background, angle: -35)

    let highlight = NSBezierPath(
        roundedRect: outer.insetBy(dx: CGFloat(size) * 0.08, dy: CGFloat(size) * 0.10),
        xRadius: CGFloat(size) * 0.18,
        yRadius: CGFloat(size) * 0.18
    )
    NSColor.white.withAlphaComponent(0.22).setFill()
    highlight.fill()

    let stroke = NSBezierPath()
    stroke.lineCapStyle = .round
    stroke.lineJoinStyle = .round
    stroke.lineWidth = max(2, CGFloat(size) * 0.052)
    NSColor.white.setStroke()

    let left = CGFloat(size) * 0.30
    let right = CGFloat(size) * 0.70
    let topRight = CGFloat(size) * 0.60
    let ys = [0.36, 0.50, 0.64].map { CGFloat(size) * CGFloat($0) }

    stroke.move(to: NSPoint(x: left, y: ys[0]))
    stroke.line(to: NSPoint(x: right, y: ys[0]))
    stroke.move(to: NSPoint(x: left, y: ys[1]))
    stroke.line(to: NSPoint(x: right, y: ys[1]))
    stroke.move(to: NSPoint(x: left, y: ys[2]))
    stroke.line(to: NSPoint(x: topRight, y: ys[2]))
    stroke.stroke()

    let dotSize = max(3, CGFloat(size) * 0.09)
    let dot = NSBezierPath(ovalIn: NSRect(
        x: CGFloat(size) * 0.68,
        y: CGFloat(size) * 0.60,
        width: dotSize,
        height: dotSize
    ))
    NSColor.white.setFill()
    dot.fill()

    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Could not render PNG")
    }
    return png
}

for output in outputs {
    let png = drawIconPNG(size: output.pixels)
    try png.write(to: iconset.appendingPathComponent(output.filename))
}

print(iconset.path)

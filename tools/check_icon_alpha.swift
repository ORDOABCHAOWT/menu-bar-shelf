import AppKit
import Foundation

let path = CommandLine.arguments.dropFirst().first ?? "Resources/AppIcon.iconset/icon_512x512@2x.png"
guard let image = NSImage(contentsOfFile: path),
      let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff) else {
    fatalError("Could not read \(path)")
}

let transparentCorners = [
    (0, 0),
    (rep.pixelsWide - 1, 0),
    (0, rep.pixelsHigh - 1),
    (rep.pixelsWide - 1, rep.pixelsHigh - 1)
]

for (x, y) in transparentCorners {
    let alpha = rep.colorAt(x: x, y: y)?.alphaComponent ?? 0
    if alpha > 0.001 {
        print("FAIL expected transparent corner at \(x),\(y), alpha: \(alpha)")
        exit(1)
    }
}

let opaqueEdges = [
    (rep.pixelsWide / 2, 0),
    (rep.pixelsWide / 2, rep.pixelsHigh - 1),
    (0, rep.pixelsHigh / 2),
    (rep.pixelsWide - 1, rep.pixelsHigh / 2)
]

for (x, y) in opaqueEdges {
    let alpha = rep.colorAt(x: x, y: y)?.alphaComponent ?? 0
    if alpha < 0.999 {
        print("FAIL expected opaque icon edge at \(x),\(y), alpha: \(alpha)")
        exit(1)
    }
}

print("Icon alpha check passed: transparent corners and opaque icon edges")

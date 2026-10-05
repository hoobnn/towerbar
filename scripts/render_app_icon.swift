// Renders Resources/app_icon.png (1024 px): a cell-tower glyph on a squircle.
// Usage: xcrun swift scripts/render_app_icon.swift Resources/app_icon.png
import AppKit

let output = CommandLine.arguments.dropFirst().first ?? "Resources/app_icon.png"
let size: CGFloat = 1024
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// macOS icon grid: 824 px body centred in a 1024 canvas.
let body = NSRect(x: 100, y: 100, width: 824, height: 824)
let squircle = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)
NSGradient(colors: [
    NSColor(srgbRed: 0.98, green: 0.55, blue: 0.20, alpha: 1),
    NSColor(srgbRed: 0.86, green: 0.22, blue: 0.30, alpha: 1)
])!.draw(in: squircle, angle: -90)

let config = NSImage.SymbolConfiguration(pointSize: 470, weight: .semibold)
    .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
let glyph = NSImage(systemSymbolName: "antenna.radiowaves.left.and.right",
                    accessibilityDescription: nil)!.withSymbolConfiguration(config)!
let glyphRect = NSRect(
    x: body.midX - glyph.size.width / 2, y: body.midY - glyph.size.height / 2,
    width: glyph.size.width, height: glyph.size.height
)
glyph.draw(in: glyphRect)

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
print("Rendered \(output)")

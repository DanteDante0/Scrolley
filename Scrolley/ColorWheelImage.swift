import AppKit
import SwiftUI

enum ColorWheelImage {
    static let rep: NSBitmapImageRep? = {
        guard let image = NSImage(named: "ColorWheel"),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        return NSBitmapImageRep(cgImage: cgImage)
    }()

    static func color(atFraction point: CGPoint) -> Color? {
        guard let rep else { return nil }
        let x = Int((point.x * CGFloat(rep.pixelsWide)).rounded())
        let y = Int((point.y * CGFloat(rep.pixelsHigh)).rounded())
        guard x >= 0, y >= 0, x < rep.pixelsWide, y < rep.pixelsHigh else { return nil }
        guard let sampled = rep.colorAt(x: x, y: y) else { return nil }
        let srgb = sampled.usingColorSpace(.sRGB) ?? sampled
        guard srgb.alphaComponent >= 0.02 else { return nil }
        return Color(.sRGB,
                     red: Double(srgb.redComponent),
                     green: Double(srgb.greenComponent),
                     blue: Double(srgb.blueComponent),
                     opacity: 1)
    }
}

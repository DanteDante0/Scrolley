import AppKit
import SwiftUI

struct OverlayStyle: Sendable {
    var shape: OverlayShape
    var frosted: Bool
    var cursor: RGBAColor
    var background: RGBAColor
    var ring: RGBAColor
}

private extension RGBAColor {
    var swiftUIColor: Color {
        Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    var opaqueColor: Color {
        Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) / 2
        let cx = rect.midX
        let cy = rect.midY
        let k: CGFloat = 0.8660254037844386
        let points: [CGPoint] = [
            CGPoint(x: cx, y: cy - r),
            CGPoint(x: cx + k * r, y: cy - r / 2),
            CGPoint(x: cx + k * r, y: cy + r / 2),
            CGPoint(x: cx, y: cy + r),
            CGPoint(x: cx - k * r, y: cy + r / 2),
            CGPoint(x: cx - k * r, y: cy - r / 2),
        ]
        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() { path.addLine(to: point) }
        path.closeSubpath()
        return path
    }
}

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct RoundedSquareShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) * 0.22
        return Path(roundedRect: rect, cornerRadius: radius)
    }
}

extension OverlayShape {
    var anyShape: AnyShape {
        switch self {
        case .none: return AnyShape(Rectangle())
        case .circle: return AnyShape(Circle())
        case .roundedSquare: return AnyShape(RoundedSquareShape())
        case .square: return AnyShape(Rectangle())
        case .hexagon: return AnyShape(HexagonShape())
        case .diamond: return AnyShape(DiamondShape())
        }
    }
}

struct OverlayIcon: View {
    let style: OverlayStyle
    var size: CGFloat = 52

    var body: some View {
        let shape = style.shape.anyShape
        ZStack {
            if style.shape != .none {
                if style.frosted {
                    ZStack {
                        shape.fill(.ultraThinMaterial)
                        shape.fill(style.background.opaqueColor.opacity(0.3))
                    }
                    .opacity(style.background.a)
                } else {
                    shape.fill(style.background.swiftUIColor)
                }
                shape.stroke(style.ring.swiftUIColor, lineWidth: max(1, size / 35))
            }
            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(style.cursor.swiftUIColor)
        }
        .frame(width: size, height: size)
    }
}

@MainActor
final class OverlayWindow {
    private let panel: NSPanel
    private let hosting: NSHostingView<OverlayIcon>

    init() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 52, height: 52),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .screenSaver
        panel.ignoresMouseEvents = true
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]

        let initialStyle = OverlayStyle(
            shape: .circle,
            frosted: true,
            cursor: RGBAColor(r: 0.18, g: 0.18, b: 0.20),
            background: RGBAColor(r: 1.0, g: 1.0, b: 1.0),
            ring: RGBAColor(r: 0.45, g: 0.45, b: 0.48)
        )
        hosting = NSHostingView(rootView: OverlayIcon(style: initialStyle))
        hosting.frame = NSRect(x: 0, y: 0, width: 52, height: 52)
        panel.contentView = hosting
    }

    func show(atGlobal cgPoint: CGPoint, opacity: Double, style: OverlayStyle, size: CGFloat) {
        let s = min(max(size, 36), 144)
        hosting.rootView = OverlayIcon(style: style, size: s)
        hosting.frame = NSRect(x: 0, y: 0, width: s, height: s)
        panel.setContentSize(NSSize(width: s, height: s))
        let cocoa = Self.cocoaPoint(fromCG: cgPoint)
        let frameSize = panel.frame.size
        panel.alphaValue = CGFloat(min(max(opacity, 0.0), 1.0))
        panel.setFrameOrigin(NSPoint(x: cocoa.x - frameSize.width / 2, y: cocoa.y - frameSize.height / 2))
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    static func cocoaPoint(fromCG p: CGPoint) -> NSPoint {
        let primary = NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.main
        let height = primary?.frame.height ?? 0
        return NSPoint(x: p.x, y: height - p.y)
    }
}

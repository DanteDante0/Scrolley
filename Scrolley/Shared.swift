import CoreGraphics

let kScrolleySentinel: Int64 = 0x5C011E7

enum ScrolleyConstants {
    static let dragThreshold: CGFloat = 6.0
    static let autoScrollDeadzone: Double = 8.0
    static let escKeyCode: Int64 = 53
    static let middleButtonNumber: Int64 = 2
    static let tickRate: Double = 120.0
}

enum OverlayShape: String, CaseIterable, Sendable {
    case circle
    case roundedSquare
    case square
    case hexagon
    case diamond
    case none

    var displayName: String {
        switch self {
        case .circle: return "Circle"
        case .roundedSquare: return "Rounded Square"
        case .square: return "Square"
        case .hexagon: return "Hexagon"
        case .diamond: return "Diamond"
        case .none: return "None"
        }
    }
}

struct RGBAColor: Sendable, Equatable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double

    init(r: Double, g: Double, b: Double, a: Double = 1.0) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}

nonisolated struct ScrollSettings: Sendable {
    var verticalSensitivity: Double = 1.0
    var horizontalSensitivity: Double = 1.0
    var smoothness: Double = 0.5
    var holdActivationMs: Double = 150.0
    var showOverlay: Bool = true
    var overlayOpacity: Double = 0.5
    var overlaySize: Double = 52.0
    var naturalDirection: Bool = false
    var excludedApps: Set<String> = []
    var overlayShape: OverlayShape = .circle
    var frostedBackground: Bool = true
    var cursorColor: RGBAColor = RGBAColor(r: 0.18, g: 0.18, b: 0.20)
    var backgroundColor: RGBAColor = RGBAColor(r: 1.0, g: 1.0, b: 1.0)
    var ringColor: RGBAColor = RGBAColor(r: 0.45, g: 0.45, b: 0.48)
    var ringMatchesCursor: Bool = true
}

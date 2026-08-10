import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    private let defaults = UserDefaults.standard

    var onEnabledChange: ((Bool) -> Void)?
    var onLaunchAtLoginChange: ((Bool) -> Void)?
    var onSettingsChange: (() -> Void)?

    static let defaultCursorColor = Color(.sRGB, red: 0.18, green: 0.18, blue: 0.20, opacity: 1.0)
    static let defaultBackgroundColor = Color(.sRGB, red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0)
    static let defaultRingColor = Color(.sRGB, red: 0.45, green: 0.45, blue: 0.48, opacity: 1.0)

    var snapshot: ScrollSettings {
        ScrollSettings(
            verticalSensitivity: verticalSensitivity,
            horizontalSensitivity: horizontalSensitivity,
            smoothness: smoothness,
            holdActivationMs: holdActivationMs,
            showOverlay: showOverlay,
            overlayOpacity: overlayOpacity,
            overlaySize: overlaySize,
            naturalDirection: naturalDirection,
            excludedApps: Set(excludedApps),
            overlayShape: overlayShape,
            frostedBackground: frostedBackground,
            cursorColor: Self.rgba(from: cursorColor),
            backgroundColor: Self.rgba(from: overlayBackgroundColor),
            ringColor: Self.rgba(from: ringColor),
            ringMatchesCursor: ringMatchesCursor
        )
    }

    @Published var enabled: Bool {
        didSet { defaults.set(enabled, forKey: Keys.enabled); onEnabledChange?(enabled) }
    }
    @Published var verticalSensitivity: Double {
        didSet { defaults.set(verticalSensitivity, forKey: Keys.verticalSensitivity); onSettingsChange?() }
    }
    @Published var horizontalSensitivity: Double {
        didSet { defaults.set(horizontalSensitivity, forKey: Keys.horizontalSensitivity); onSettingsChange?() }
    }
    @Published var smoothness: Double {
        didSet { defaults.set(smoothness, forKey: Keys.smoothness); onSettingsChange?() }
    }
    @Published var holdActivationMs: Double {
        didSet { defaults.set(holdActivationMs, forKey: Keys.holdActivationMs); onSettingsChange?() }
    }
    @Published var showOverlay: Bool {
        didSet { defaults.set(showOverlay, forKey: Keys.showOverlay); onSettingsChange?() }
    }
    @Published var overlayOpacity: Double {
        didSet { defaults.set(overlayOpacity, forKey: Keys.overlayOpacity); onSettingsChange?() }
    }
    @Published var overlaySize: Double {
        didSet { defaults.set(overlaySize, forKey: Keys.overlaySize); onSettingsChange?() }
    }
    @Published var naturalDirection: Bool {
        didSet { defaults.set(naturalDirection, forKey: Keys.naturalDirection); onSettingsChange?() }
    }
    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin); onLaunchAtLoginChange?(launchAtLogin) }
    }
    @Published var excludedApps: [String] {
        didSet { defaults.set(excludedApps, forKey: Keys.excludedApps); onSettingsChange?() }
    }
    @Published var overlayShape: OverlayShape {
        didSet { defaults.set(overlayShape.rawValue, forKey: Keys.overlayShape); onSettingsChange?() }
    }
    @Published var frostedBackground: Bool {
        didSet { defaults.set(frostedBackground, forKey: Keys.frostedBackground); onSettingsChange?() }
    }
    @Published var ringMatchesCursor: Bool {
        didSet { defaults.set(ringMatchesCursor, forKey: Keys.ringMatchesCursor); onSettingsChange?() }
    }
    @Published var cursorColor: Color {
        didSet { defaults.set(Self.components(cursorColor), forKey: Keys.cursorColor); onSettingsChange?() }
    }
    @Published var overlayBackgroundColor: Color {
        didSet { defaults.set(Self.components(overlayBackgroundColor), forKey: Keys.backgroundColor); onSettingsChange?() }
    }
    @Published var ringColor: Color {
        didSet { defaults.set(Self.components(ringColor), forKey: Keys.ringColor); onSettingsChange?() }
    }

    init() {
        defaults.register(defaults: [
            Keys.enabled: true,
            Keys.verticalSensitivity: 1.0,
            Keys.horizontalSensitivity: 1.0,
            Keys.smoothness: 0.5,
            Keys.holdActivationMs: 150.0,
            Keys.showOverlay: true,
            Keys.overlayOpacity: 0.5,
            Keys.overlaySize: 52.0,
            Keys.naturalDirection: false,
            Keys.launchAtLogin: true,
            Keys.overlayShape: OverlayShape.circle.rawValue,
            Keys.frostedBackground: true,
            Keys.ringMatchesCursor: true,
        ])
        enabled = defaults.bool(forKey: Keys.enabled)
        verticalSensitivity = defaults.double(forKey: Keys.verticalSensitivity)
        horizontalSensitivity = defaults.double(forKey: Keys.horizontalSensitivity)
        smoothness = defaults.double(forKey: Keys.smoothness)
        holdActivationMs = defaults.double(forKey: Keys.holdActivationMs)
        showOverlay = defaults.bool(forKey: Keys.showOverlay)
        overlayOpacity = defaults.double(forKey: Keys.overlayOpacity)
        overlaySize = defaults.double(forKey: Keys.overlaySize)
        naturalDirection = defaults.bool(forKey: Keys.naturalDirection)
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        excludedApps = defaults.stringArray(forKey: Keys.excludedApps) ?? []
        overlayShape = OverlayShape(rawValue: defaults.string(forKey: Keys.overlayShape) ?? "") ?? .circle
        frostedBackground = defaults.bool(forKey: Keys.frostedBackground)
        ringMatchesCursor = defaults.bool(forKey: Keys.ringMatchesCursor)
        cursorColor = Self.color(from: defaults.array(forKey: Keys.cursorColor) as? [Double], fallback: Self.defaultCursorColor)
        overlayBackgroundColor = Self.color(from: defaults.array(forKey: Keys.backgroundColor) as? [Double], fallback: Self.defaultBackgroundColor)
        ringColor = Self.color(from: defaults.array(forKey: Keys.ringColor) as? [Double], fallback: Self.defaultRingColor)
    }

    func addExcluded(_ bundleID: String) {
        guard !bundleID.isEmpty, !excludedApps.contains(bundleID) else { return }
        excludedApps.append(bundleID)
    }

    func removeExcluded(_ bundleID: String) {
        excludedApps.removeAll { $0 == bundleID }
    }

    nonisolated static func rgba(from color: Color) -> RGBAColor {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
        return RGBAColor(r: Double(ns.redComponent), g: Double(ns.greenComponent), b: Double(ns.blueComponent), a: Double(ns.alphaComponent))
    }

    private nonisolated static func components(_ color: Color) -> [Double] {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
        return [Double(ns.redComponent), Double(ns.greenComponent), Double(ns.blueComponent), Double(ns.alphaComponent)]
    }

    private nonisolated static func color(from comps: [Double]?, fallback: Color) -> Color {
        guard let comps, comps.count == 4 else { return fallback }
        return Color(.sRGB, red: comps[0], green: comps[1], blue: comps[2], opacity: comps[3])
    }

    private enum Keys {
        static let enabled = "enabled"
        static let verticalSensitivity = "verticalSensitivity"
        static let horizontalSensitivity = "horizontalSensitivity"
        static let smoothness = "smoothness"
        static let holdActivationMs = "holdActivationMs"
        static let showOverlay = "showOverlay"
        static let overlayOpacity = "overlayOpacity"
        static let overlaySize = "overlaySize"
        static let naturalDirection = "naturalDirection"
        static let launchAtLogin = "launchAtLogin"
        static let excludedApps = "excludedApps"
        static let overlayShape = "overlayShape"
        static let frostedBackground = "frostedBackground"
        static let ringMatchesCursor = "ringMatchesCursor"
        static let cursorColor = "cursorColor"
        static let backgroundColor = "overlayBackgroundColor"
        static let ringColor = "ringColor"
    }
}

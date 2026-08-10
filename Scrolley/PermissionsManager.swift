import AppKit
import ApplicationServices
import Combine
import IOKit.hid

@MainActor
final class PermissionsManager: NSObject, ObservableObject {
    @Published private(set) var accessibilityGranted = false
    @Published private(set) var inputMonitoringGranted = false

    var onChange: (() -> Void)?
    private var timer: Timer?

    func start() {
        refresh()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
    }

    @objc private func timerFired() {
        refresh()
    }

    func refresh() {
        let ax = AXIsProcessTrusted()
        let im = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
        let changed = (ax != accessibilityGranted) || (im != inputMonitoringGranted)
        accessibilityGranted = ax
        inputMonitoringGranted = im
        if changed { onChange?() }
    }

    func promptAccessibility() {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        openAccessibilitySettings()
    }

    func requestInputMonitoring() {
        _ = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
        openInputMonitoringSettings()
    }

    func openAccessibilitySettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    func openInputMonitoringSettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
    }

    private func open(_ string: String) {
        if let url = URL(string: string) {
            NSWorkspace.shared.open(url)
        }
    }
}

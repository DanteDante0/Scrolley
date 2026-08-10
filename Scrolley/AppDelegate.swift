import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = AppState()
    let permissions = PermissionsManager()

    private let overlay = OverlayWindow()
    private let engine = ScrollEngine()
    private lazy var controller = ModeController(engine: engine, overlay: overlay)
    private lazy var tap = EventTapManager(controller: controller)

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        state.onEnabledChange = { [weak self] _ in self?.applyEnabled() }
        state.onLaunchAtLoginChange = { enabled in LoginItem.setEnabled(enabled) }
        state.onSettingsChange = { [weak self] in self?.pushSettings() }
        permissions.onChange = { [weak self] in self?.applyEnabled() }

        pushSettings()
        permissions.start()
        LoginItem.setEnabled(state.launchAtLogin)
        applyEnabled()
    }

    private func pushSettings() {
        controller.updateConfig(state.snapshot)
    }

    private func applyEnabled() {
        if state.enabled && permissions.accessibilityGranted {
            tap.start()
        } else {
            tap.stop()
        }
    }

    func addExcludedFrontmostApp() {
        if let bundle = FrontmostApp.frontmostBundleID() {
            state.addExcluded(bundle)
        }
    }

    func openSupport() {
        if let url = URL(string: "https://www.paypal.com/ncp/payment/CFZVJGT2335HL") {
            NSWorkspace.shared.open(url)
        }
    }

    func quit() {
        NSApp.terminate(nil)
    }
}

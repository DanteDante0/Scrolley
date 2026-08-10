import SwiftUI

@main
struct ScrolleyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Scrolley", systemImage: "arrow.up.and.down.and.arrow.left.and.right") {
            MenuContent(coordinator: appDelegate)
                .environmentObject(appDelegate.state)
                .environmentObject(appDelegate.permissions)
        }
        .menuBarExtraStyle(.window)
    }
}

import AppKit
import CoreGraphics

nonisolated enum FrontmostApp {
    static func bundleID(at point: CGPoint) -> String? {
        if let pid = ownerPID(at: point),
           let app = NSRunningApplication(processIdentifier: pid),
           let bundle = app.bundleIdentifier {
            return bundle
        }
        return NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    static func frontmostBundleID() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    private static func ownerPID(at point: CGPoint) -> pid_t? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        for window in windows {
            guard let layer = window[kCGWindowLayer as String] as? Int, layer == 0,
                  let boundsDict = window[kCGWindowBounds as String] as? [String: CGFloat],
                  let pid = window[kCGWindowOwnerPID as String] as? pid_t else {
                continue
            }
            let rect = CGRect(
                x: boundsDict["X"] ?? 0,
                y: boundsDict["Y"] ?? 0,
                width: boundsDict["Width"] ?? 0,
                height: boundsDict["Height"] ?? 0
            )
            if rect.contains(point) {
                return pid
            }
        }
        return nil
    }
}

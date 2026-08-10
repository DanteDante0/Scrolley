import Foundation
import ServiceManagement

enum LoginItem {
    static func setEnabled(_ enabled: Bool) {
        do {
            let service = SMAppService.mainApp
            if enabled {
                if service.status != .enabled {
                    try service.register()
                }
            } else {
                if service.status == .enabled {
                    try service.unregister()
                }
            }
        } catch {
            NSLog("Scrolley login item error: \(error.localizedDescription)")
        }
    }
}

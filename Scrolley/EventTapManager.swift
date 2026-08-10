import CoreGraphics
import Foundation

private nonisolated func scrolleyTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passUnretained(event) }
    let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        manager.reenable()
        return Unmanaged.passUnretained(event)
    }

    let passthrough = manager.controller.handle(type: type, event: event)
    return passthrough ? Unmanaged.passUnretained(event) : nil
}

nonisolated final class EventTapManager {
    let controller: ModeController
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(controller: ModeController) {
        self.controller = controller
    }

    var isActive: Bool { tap != nil }

    func start() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: true)
            return
        }

        let mask: CGEventMask =
            (UInt64(1) << CGEventType.otherMouseDown.rawValue) |
            (UInt64(1) << CGEventType.otherMouseUp.rawValue) |
            (UInt64(1) << CGEventType.otherMouseDragged.rawValue) |
            (UInt64(1) << CGEventType.mouseMoved.rawValue) |
            (UInt64(1) << CGEventType.leftMouseDown.rawValue) |
            (UInt64(1) << CGEventType.leftMouseDragged.rawValue) |
            (UInt64(1) << CGEventType.keyDown.rawValue)

        guard let newTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: scrolleyTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return
        }

        tap = newTap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, newTap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: newTap, enable: true)
    }

    func stop() {
        controller.forceIdle()
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        runLoopSource = nil
        tap = nil
    }

    func reenable() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }
}

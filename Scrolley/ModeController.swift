import Cocoa
import CoreGraphics
import Foundation

nonisolated final class ModeController: NSObject {
    private enum State {
        case idle
        case pending
        case autoScroll
        case dragScroll
    }

    private let engine: ScrollEngine
    private let overlay: OverlayWindow

    private var config = ScrollSettings()
    private var state: State = .idle
    private var origin: CGPoint = .zero
    private var lastDragPoint: CGPoint = .zero
    private var weOwnMiddle = false
    private var holdTimer: Timer?

    private let eventSource = CGEventSource(stateID: .combinedSessionState)

    init(engine: ScrollEngine, overlay: OverlayWindow) {
        self.engine = engine
        self.overlay = overlay
        super.init()
    }

    func updateConfig(_ newConfig: ScrollSettings) {
        config = newConfig
    }

    func handle(type: CGEventType, event: CGEvent) -> Bool {
        if event.getIntegerValueField(.eventSourceUserData) == kScrolleySentinel {
            return true
        }

        switch type {
        case .otherMouseDown:
            guard event.getIntegerValueField(.mouseEventButtonNumber) == ScrolleyConstants.middleButtonNumber else { return true }
            return handleMiddleDown(event)
        case .otherMouseUp:
            guard event.getIntegerValueField(.mouseEventButtonNumber) == ScrolleyConstants.middleButtonNumber else { return true }
            return handleMiddleUp(event)
        case .otherMouseDragged, .mouseMoved, .leftMouseDragged:
            return handleMove(event)
        case .leftMouseDown:
            return handleLeftDown()
        case .keyDown:
            return handleKeyDown(event)
        default:
            return true
        }
    }

    func forceIdle() {
        cancelHoldTimer()
        engine.stop()
        hideOverlay()
        state = .idle
        weOwnMiddle = false
    }

    private func handleMiddleDown(_ event: CGEvent) -> Bool {
        let point = event.location
        switch state {
        case .autoScroll:
            exitAutoScroll()
            weOwnMiddle = true
            return false
        case .idle:
            if let bundle = FrontmostApp.bundleID(at: point), config.excludedApps.contains(bundle) {
                return true
            }
            origin = point
            lastDragPoint = point
            weOwnMiddle = true
            state = .pending
            startHoldTimer()
            return false
        default:
            return false
        }
    }

    private func handleMiddleUp(_ event: CGEvent) -> Bool {
        guard weOwnMiddle else { return true }
        switch state {
        case .pending:
            cancelHoldTimer()
            synthesizeMiddleClick(at: origin)
            state = .idle
            weOwnMiddle = false
            return false
        case .dragScroll:
            engine.stop()
            state = .idle
            weOwnMiddle = false
            return false
        case .autoScroll:
            weOwnMiddle = false
            return false
        case .idle:
            weOwnMiddle = false
            return false
        }
    }

    private func handleMove(_ event: CGEvent) -> Bool {
        let point = event.location
        switch state {
        case .pending:
            let dx = point.x - origin.x
            let dy = point.y - origin.y
            if hypot(dx, dy) > ScrolleyConstants.dragThreshold {
                cancelHoldTimer()
                beginDrag(at: point)
            }
        case .dragScroll:
            let delta = CGVector(dx: point.x - lastDragPoint.x, dy: point.y - lastDragPoint.y)
            lastDragPoint = point
            feedDrag(delta)
        case .autoScroll:
            updateAutoScroll(current: point)
        case .idle:
            break
        }
        return true
    }

    private func handleLeftDown() -> Bool {
        if state == .autoScroll {
            exitAutoScroll()
            return false
        }
        return true
    }

    private func handleKeyDown(_ event: CGEvent) -> Bool {
        guard event.getIntegerValueField(.keyboardEventKeycode) == ScrolleyConstants.escKeyCode else { return true }
        if state == .autoScroll {
            exitAutoScroll()
            return false
        }
        return true
    }

    private func startHoldTimer() {
        cancelHoldTimer()
        let delay = max(0.001, config.holdActivationMs / 1000.0)
        holdTimer = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(holdTimerFired), userInfo: nil, repeats: false)
    }

    private func cancelHoldTimer() {
        holdTimer?.invalidate()
        holdTimer = nil
    }

    @objc private func holdTimerFired() {
        holdFired()
    }

    private func holdFired() {
        guard state == .pending else { return }
        state = .autoScroll
        showOverlay()
        engine.start(mode: .autoScroll, smoothness: config.smoothness)
        engine.setAutoScrollTarget(.zero)
    }

    private func showOverlay() {
        guard config.showOverlay else { return }
        let panel = overlay
        let point = origin
        let opacity = config.overlayOpacity
        let size = CGFloat(config.overlaySize)
        let ring = config.ringMatchesCursor ? config.cursorColor : config.ringColor
        let style = OverlayStyle(
            shape: config.overlayShape,
            frosted: config.frostedBackground,
            cursor: config.cursorColor,
            background: config.backgroundColor,
            ring: ring
        )
        Task { @MainActor in panel.show(atGlobal: point, opacity: opacity, style: style, size: size) }
    }

    private func hideOverlay() {
        let panel = overlay
        Task { @MainActor in panel.hide() }
    }

    private func beginDrag(at point: CGPoint) {
        state = .dragScroll
        lastDragPoint = point
        engine.start(mode: .dragScroll, smoothness: config.smoothness)
    }

    private func feedDrag(_ delta: CGVector) {
        let sign = config.naturalDirection ? -1.0 : 1.0
        let vx = Double(delta.dx) * config.horizontalSensitivity * sign
        let vy = Double(delta.dy) * config.verticalSensitivity * sign
        engine.addDragDelta(CGVector(dx: vx, dy: vy))
    }

    private func updateAutoScroll(current: CGPoint) {
        let dir = config.naturalDirection ? 1.0 : -1.0
        let vx = velocityCurve(Double(current.x - origin.x)) * config.horizontalSensitivity * dir
        let vy = velocityCurve(Double(current.y - origin.y)) * config.verticalSensitivity * dir
        engine.setAutoScrollTarget(CGVector(dx: vx, dy: vy))
    }

    private func velocityCurve(_ value: Double) -> Double {
        let magnitude = abs(value) - ScrolleyConstants.autoScrollDeadzone
        if magnitude <= 0 { return 0 }
        let speed = pow(magnitude, 1.6)
        return value < 0 ? -speed : speed
    }

    private func exitAutoScroll() {
        engine.stop()
        hideOverlay()
        state = .idle
        weOwnMiddle = false
    }

    private func synthesizeMiddleClick(at point: CGPoint) {
        guard let down = CGEvent(mouseEventSource: eventSource, mouseType: .otherMouseDown, mouseCursorPosition: point, mouseButton: .center),
              let up = CGEvent(mouseEventSource: eventSource, mouseType: .otherMouseUp, mouseCursorPosition: point, mouseButton: .center) else {
            return
        }
        down.setIntegerValueField(.eventSourceUserData, value: kScrolleySentinel)
        up.setIntegerValueField(.eventSourceUserData, value: kScrolleySentinel)
        down.post(tap: .cgSessionEventTap)
        up.post(tap: .cgSessionEventTap)
    }
}

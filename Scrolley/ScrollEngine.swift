import CoreGraphics
import Foundation

private func + (a: CGVector, b: CGVector) -> CGVector { CGVector(dx: a.dx + b.dx, dy: a.dy + b.dy) }
private func - (a: CGVector, b: CGVector) -> CGVector { CGVector(dx: a.dx - b.dx, dy: a.dy - b.dy) }
private func * (a: CGVector, s: Double) -> CGVector { CGVector(dx: a.dx * s, dy: a.dy * s) }

enum EngineMode {
    case idle
    case autoScroll
    case dragScroll
}

nonisolated final class ScrollEngine: @unchecked Sendable {
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "com.scrolley.engine", qos: .userInteractive)
    private var timer: DispatchSourceTimer?

    private var mode: EngineMode = .idle
    private var smoothness: Double = 0.5
    private var targetVelocity = CGVector.zero
    private var currentVelocity = CGVector.zero
    private var dragRemainder = CGVector.zero
    private var pixelRemainder = CGVector.zero

    private let source = CGEventSource(stateID: .combinedSessionState)
    private let interval = 1.0 / ScrolleyConstants.tickRate

    func start(mode: EngineMode, smoothness: Double) {
        lock.lock()
        self.mode = mode
        self.smoothness = smoothness
        self.targetVelocity = .zero
        self.currentVelocity = .zero
        self.dragRemainder = .zero
        self.pixelRemainder = .zero
        let alreadyRunning = timer != nil
        lock.unlock()

        guard !alreadyRunning else { return }
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: interval)
        t.setEventHandler { [weak self] in self?.tick() }
        lock.lock(); timer = t; lock.unlock()
        t.resume()
    }

    func stop() {
        lock.lock()
        let t = timer
        timer = nil
        mode = .idle
        targetVelocity = .zero
        currentVelocity = .zero
        dragRemainder = .zero
        pixelRemainder = .zero
        lock.unlock()
        t?.cancel()
    }

    func updateSmoothness(_ value: Double) {
        lock.lock(); smoothness = value; lock.unlock()
    }

    func setAutoScrollTarget(_ velocity: CGVector) {
        lock.lock(); targetVelocity = velocity; lock.unlock()
    }

    func addDragDelta(_ delta: CGVector) {
        lock.lock(); dragRemainder = dragRemainder + delta; lock.unlock()
    }

    private func tick() {
        lock.lock()
        let mode = self.mode
        let smoothness = self.smoothness
        var delta = CGVector.zero

        switch mode {
        case .idle:
            lock.unlock()
            return
        case .autoScroll:
            let approach = (1.0 - smoothness) * 0.85 + 0.03
            currentVelocity = currentVelocity + (targetVelocity - currentVelocity) * approach
            delta = currentVelocity * interval
        case .dragScroll:
            let drain = (1.0 - smoothness) * 0.75 + 0.05
            delta = dragRemainder * drain
            dragRemainder = dragRemainder - delta
        }

        let fx = delta.dx + pixelRemainder.dx
        let fy = delta.dy + pixelRemainder.dy
        let ix = (fx < 0 ? (fx).rounded(.up) : (fx).rounded(.down))
        let iy = (fy < 0 ? (fy).rounded(.up) : (fy).rounded(.down))
        pixelRemainder = CGVector(dx: fx - ix, dy: fy - iy)
        lock.unlock()

        if ix == 0 && iy == 0 { return }
        postScroll(vertical: Int32(iy), horizontal: Int32(ix))
    }

    private func postScroll(vertical: Int32, horizontal: Int32) {
        guard let event = CGEvent(
            scrollWheelEvent2Source: source,
            units: .pixel,
            wheelCount: 2,
            wheel1: vertical,
            wheel2: horizontal,
            wheel3: 0
        ) else { return }
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        event.setIntegerValueField(.eventSourceUserData, value: kScrolleySentinel)
        event.post(tap: .cgSessionEventTap)
    }
}

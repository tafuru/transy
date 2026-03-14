import Foundation

/// Stateful value type. Thread-safety is the caller's responsibility (used only on @MainActor).
struct DoublePressDetector {
    var lastPressDate: Date?          // internal (not private) for test-visibility
    let threshold: TimeInterval = 0.4

    /// Records a press and returns true if it constitutes the second press of a double-press gesture.
    /// Resets after firing so a triple-press fires only once.
    mutating func record() -> Bool {
        let now = Date()
        guard let last = lastPressDate else {
            lastPressDate = now
            return false
        }
        let elapsed = now.timeIntervalSince(last)
        if elapsed < threshold {
            lastPressDate = nil   // reset so third press starts a new sequence
            return true
        }
        lastPressDate = now
        return false
    }
}

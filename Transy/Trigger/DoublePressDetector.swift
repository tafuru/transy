import Foundation

/// The result of recording a single key press in the double-press detector.
enum PressResult: Equatable {
    /// This press is the first of a potential double-press gesture.
    case firstPress
    /// This press completes a double-press gesture within the threshold.
    case doublePress
}

/// Stateful value type. Thread-safety is the caller's responsibility (used only on @MainActor).
struct DoublePressDetector {
    var lastPressDate: Date?          // internal (not private) for test-visibility
    let threshold: TimeInterval = 0.4

    /// Records a press and returns whether it is the first press of a new sequence or the
    /// second press that completes a double-press gesture. Resets after firing so a triple-press
    /// fires only once.
    mutating func record() -> PressResult {
        let now = Date()
        guard let last = lastPressDate else {
            lastPressDate = now
            return .firstPress
        }
        let elapsed = now.timeIntervalSince(last)
        if elapsed < threshold {
            lastPressDate = nil   // reset so third press starts a new sequence
            return .doublePress
        }
        lastPressDate = now
        return .firstPress
    }
}

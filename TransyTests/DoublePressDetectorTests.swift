import Foundation
import Testing
@testable import Transy

struct DoublePressDetectorTests {
    @Test("first press returns .firstPress")
    func firstPressReturnsFirstPress() {
        var detector = DoublePressDetector()
        #expect(detector.record() == .firstPress)
    }

    @Test("second press within threshold returns .doublePress")
    func doublePressFires() {
        var detector = DoublePressDetector()
        _ = detector.record()
        // Simulate 100ms gap (well within 400ms threshold)
        detector.lastPressDate = Date().addingTimeInterval(-0.1)
        #expect(detector.record() == .doublePress)
    }

    @Test("second press outside threshold returns .firstPress (new sequence)")
    func slowPressRestartsSequence() {
        var detector = DoublePressDetector()
        _ = detector.record()
        // Simulate 500ms gap (outside 400ms threshold)
        detector.lastPressDate = Date().addingTimeInterval(-0.5)
        #expect(detector.record() == .firstPress)
    }

    @Test("triple press fires exactly once then resets")
    func triplePressFiresOnce() {
        var detector = DoublePressDetector()
        _ = detector.record() // press 1: .firstPress
        detector.lastPressDate = Date().addingTimeInterval(-0.1)
        let second = detector.record() // press 2: .doublePress, lastPressDate = nil
        #expect(second == .doublePress)
        // Third press called immediately — lastPressDate is nil after reset, so starts a new sequence
        let third = detector.record() // press 3: .firstPress (new sequence)
        #expect(third == .firstPress)
    }

    @Test("threshold boundary: at or past threshold returns .firstPress")
    func atThresholdReturnsFirstPress() {
        var detector = DoublePressDetector()
        _ = detector.record()
        // Set last press to threshold + 1ms ago — elapsed will exceed threshold, must not fire
        detector.lastPressDate = Date().addingTimeInterval(-(detector.threshold + 0.001))
        #expect(detector.record() == .firstPress) // strictly less than threshold required to fire
    }
}

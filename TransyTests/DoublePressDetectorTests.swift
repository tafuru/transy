import Foundation
import Testing
@testable import Transy

@Suite("DoublePressDetector")
struct DoublePressDetectorTests {

    @Test("first press returns .firstPress")
    func firstPressReturnsFirstPress() {
        var d = DoublePressDetector()
        #expect(d.record() == .firstPress)
    }

    @Test("second press within threshold returns .doublePress")
    func doublePressFires() {
        var d = DoublePressDetector()
        _ = d.record()
        // Simulate 100ms gap (well within 400ms threshold)
        d.lastPressDate = Date().addingTimeInterval(-0.1)
        #expect(d.record() == .doublePress)
    }

    @Test("second press outside threshold returns .firstPress (new sequence)")
    func slowPressRestartsSequence() {
        var d = DoublePressDetector()
        _ = d.record()
        // Simulate 500ms gap (outside 400ms threshold)
        d.lastPressDate = Date().addingTimeInterval(-0.5)
        #expect(d.record() == .firstPress)
    }

    @Test("triple press fires exactly once then resets")
    func triplePressFiresOnce() {
        var d = DoublePressDetector()
        _ = d.record()                                           // press 1: .firstPress
        d.lastPressDate = Date().addingTimeInterval(-0.1)
        let second = d.record()                                  // press 2: .doublePress, lastPressDate = nil
        #expect(second == .doublePress)
        // Third press called immediately — lastPressDate is nil after reset, so starts a new sequence
        let third = d.record()                                   // press 3: .firstPress (new sequence)
        #expect(third == .firstPress)
    }

    @Test("threshold boundary: at or past threshold returns .firstPress")
    func atThresholdReturnsFirstPress() {
        var d = DoublePressDetector()
        _ = d.record()
        // Set last press to threshold + 1ms ago — elapsed will exceed threshold, must not fire
        d.lastPressDate = Date().addingTimeInterval(-(d.threshold + 0.001))
        #expect(d.record() == .firstPress)   // strictly less than threshold required to fire
    }
}

import Foundation
import Testing
@testable import Transy

@Suite("DoublePressDetector")
struct DoublePressDetectorTests {

    @Test("first press never fires")
    func firstPressDoesNotFire() {
        var d = DoublePressDetector()
        #expect(d.record() == false)
    }

    @Test("second press within threshold fires")
    func doublePressFires() {
        var d = DoublePressDetector()
        _ = d.record()
        // Simulate 100ms gap (well within 400ms threshold)
        d.lastPressDate = Date().addingTimeInterval(-0.1)
        #expect(d.record() == true)
    }

    @Test("second press outside threshold does not fire")
    func slowPressDoesNotFire() {
        var d = DoublePressDetector()
        _ = d.record()
        // Simulate 500ms gap (outside 400ms threshold)
        d.lastPressDate = Date().addingTimeInterval(-0.5)
        #expect(d.record() == false)
    }

    @Test("triple press fires exactly once then resets")
    func triplePressFiresOnce() {
        var d = DoublePressDetector()
        _ = d.record()                                           // press 1: false
        d.lastPressDate = Date().addingTimeInterval(-0.1)
        let second = d.record()                                  // press 2: true (fires), lastPressDate = nil
        #expect(second == true)
        // Third press called immediately — lastPressDate is nil after reset, so starts a new sequence
        let third = d.record()                                   // press 3: false (new sequence)
        #expect(third == false)
    }

    @Test("threshold boundary: at or past threshold does not fire")
    func atThresholdDoesNotFire() {
        var d = DoublePressDetector()
        _ = d.record()
        // Set last press to threshold + 1ms ago — elapsed will exceed threshold, must not fire
        d.lastPressDate = Date().addingTimeInterval(-(d.threshold + 0.001))
        #expect(d.record() == false)   // strictly less than threshold required to fire
    }
}

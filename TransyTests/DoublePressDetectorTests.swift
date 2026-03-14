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
        let second = d.record()                                  // press 2: true (fires)
        #expect(second == true)
        d.lastPressDate = Date().addingTimeInterval(-0.1)
        let third = d.record()                                   // press 3: false (reset after fire)
        #expect(third == false)
    }

    @Test("threshold boundary: exactly at threshold does not fire")
    func exactlyAtThresholdDoesNotFire() {
        var d = DoublePressDetector()
        _ = d.record()
        d.lastPressDate = Date().addingTimeInterval(-d.threshold)
        #expect(d.record() == false)   // strictly less than threshold required
    }
}

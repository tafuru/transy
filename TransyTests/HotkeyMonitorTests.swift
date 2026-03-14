import Testing
@testable import Transy

@Suite("HotkeyMonitor")
struct HotkeyMonitorTests {

    @Test("HotkeyMonitor can be instantiated")
    @MainActor
    func canInstantiate() {
        let monitor = HotkeyMonitor()
        // Just confirms the type exists and can be created
        _ = monitor
    }

    @Test("start and stop do not crash when called on main actor")
    @MainActor
    func startStopNoCrash() {
        let monitor = HotkeyMonitor()
        monitor.start(onDoubleCmdC: {})
        monitor.stop()
    }
}

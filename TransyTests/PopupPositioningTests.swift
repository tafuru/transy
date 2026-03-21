import Foundation
import Testing
@testable import Transy

@Suite("PopupPositionCalculator")
struct PopupPositioningTests {

    // MARK: - Test 1: Below cursor, centered horizontally (happy path)

    @Test("Places popup below cursor with 8pt offset, horizontally centered on cursor X")
    func belowCursorCenteredHorizontally() {
        let origin = PopupPositionCalculator.calculateOrigin(
            cursorLocation: CGPoint(x: 500, y: 400),
            panelSize: CGSize(width: 300, height: 100),
            screenFrame: CGRect(x: 0, y: 0, width: 1000, height: 800)
        )
        // x = 500 - 300/2 = 350, y = 400 - 8 - 100 = 292
        #expect(origin.x == 350)
        #expect(origin.y == 292)
    }

    // MARK: - Test 2: Flip above when bottom overflows

    @Test("Flips popup above cursor when below-placement would overflow bottom of screen")
    func flipAboveWhenBottomOverflows() {
        let origin = PopupPositionCalculator.calculateOrigin(
            cursorLocation: CGPoint(x: 500, y: 50),
            panelSize: CGSize(width: 300, height: 100),
            screenFrame: CGRect(x: 0, y: 0, width: 1000, height: 800)
        )
        // Below y = 50 - 8 - 100 = -58 → flip, y = 50 + 8 = 58
        #expect(origin.x == 350)
        #expect(origin.y == 58)
    }

    // MARK: - Test 3: Left edge clamp

    @Test("Clamps horizontal position to keep popup within left screen edge with 8pt margin")
    func leftEdgeClamp() {
        let origin = PopupPositionCalculator.calculateOrigin(
            cursorLocation: CGPoint(x: 50, y: 400),
            panelSize: CGSize(width: 300, height: 100),
            screenFrame: CGRect(x: 0, y: 0, width: 1000, height: 800)
        )
        // x = 50 - 150 = -100 → clamp to 0 + 8 = 8
        #expect(origin.x == 8)
        #expect(origin.y == 292)
    }

    // MARK: - Test 4: Right edge clamp

    @Test("Clamps horizontal position to keep popup within right screen edge with 8pt margin")
    func rightEdgeClamp() {
        let origin = PopupPositionCalculator.calculateOrigin(
            cursorLocation: CGPoint(x: 950, y: 400),
            panelSize: CGSize(width: 300, height: 100),
            screenFrame: CGRect(x: 0, y: 0, width: 1000, height: 800)
        )
        // x = 950 - 150 = 800 → clamp to 1000 - 300 - 8 = 692
        #expect(origin.x == 692)
        #expect(origin.y == 292)
    }

    // MARK: - Test 5: Flipped popup overflows top → clamp

    @Test("Clamps vertical position when flipped popup would overflow top of screen")
    func flippedPopupOverflowsTopClamp() {
        let origin = PopupPositionCalculator.calculateOrigin(
            cursorLocation: CGPoint(x: 500, y: 50),
            panelSize: CGSize(width: 300, height: 780),
            screenFrame: CGRect(x: 0, y: 0, width: 1000, height: 800)
        )
        // Below y = 50 - 8 - 780 = -738 → flip
        // Above y = 50 + 8 = 58, top = 58 + 780 = 838 > 800 - 8 = 792
        // Clamp: y = 800 - 780 - 8 = 12
        #expect(origin.x == 350)
        #expect(origin.y == 12)
    }

    // MARK: - Test 6: Non-zero screen origin (Dock offset)

    @Test("Works correctly with non-zero screen origins (Dock/menu bar offsets)")
    func nonZeroScreenOriginDockOffset() {
        let origin = PopupPositionCalculator.calculateOrigin(
            cursorLocation: CGPoint(x: 500, y: 400),
            panelSize: CGSize(width: 300, height: 100),
            screenFrame: CGRect(x: 0, y: 100, width: 1000, height: 700)
        )
        // visibleFrame: minY=100, maxY=800
        // Below y = 400 - 8 - 100 = 292, 292 >= 100 + 8 = 108 ✓
        #expect(origin.x == 350)
        #expect(origin.y == 292)
    }

    // MARK: - Test 7: Bottom overflow with non-zero screen origin

    @Test("Flips above cursor with non-zero screen origin when below-placement overflows")
    func bottomOverflowNonZeroScreenOrigin() {
        let origin = PopupPositionCalculator.calculateOrigin(
            cursorLocation: CGPoint(x: 500, y: 150),
            panelSize: CGSize(width: 300, height: 100),
            screenFrame: CGRect(x: 0, y: 100, width: 1000, height: 700)
        )
        // Below y = 150 - 8 - 100 = 42, 42 < 100 + 8 = 108 → flip
        // Above y = 150 + 8 = 158
        #expect(origin.x == 350)
        #expect(origin.y == 158)
    }

    // MARK: - Test 8: Bottom-right corner (flip + right clamp combined)

    @Test("Handles combined flip and right edge clamp at bottom-right corner")
    func bottomRightCornerFlipAndClamp() {
        let origin = PopupPositionCalculator.calculateOrigin(
            cursorLocation: CGPoint(x: 950, y: 50),
            panelSize: CGSize(width: 300, height: 100),
            screenFrame: CGRect(x: 0, y: 0, width: 1000, height: 800)
        )
        // x = 950 - 150 = 800 → clamp to 692
        // Below y = -58 → flip, y = 50 + 8 = 58
        #expect(origin.x == 692)
        #expect(origin.y == 58)
    }

    // MARK: - Test 9: Default constants are 8pt

    @Test("Default constants for offset and margin are 8pt")
    func defaultConstantsAre8pt() {
        #expect(PopupPositionCalculator.defaultOffset == 8)
        #expect(PopupPositionCalculator.defaultMargin == 8)
    }
}

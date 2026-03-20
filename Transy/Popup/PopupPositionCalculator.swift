import Foundation

struct PopupPositionCalculator {
    static let defaultOffset: CGFloat = 8
    static let defaultMargin: CGFloat = 8

    static func calculateOrigin(
        cursorLocation: CGPoint,
        panelSize: CGSize,
        screenFrame: CGRect,
        offset: CGFloat = defaultOffset,
        margin: CGFloat = defaultMargin
    ) -> CGPoint {
        // 1. Horizontal: center on cursor X, clamp to screen edges
        var x = cursorLocation.x - panelSize.width / 2
        x = max(screenFrame.minX + margin, x)
        x = min(screenFrame.maxX - panelSize.width - margin, x)

        // 2. Vertical: try below cursor first
        let belowY = cursorLocation.y - offset - panelSize.height

        let y: CGFloat
        if belowY >= screenFrame.minY + margin {
            // Fits below cursor
            y = belowY
        } else {
            // Flip above cursor
            var aboveY = cursorLocation.y + offset
            // Clamp to top if flipped popup still overflows
            if aboveY + panelSize.height > screenFrame.maxY - margin {
                aboveY = screenFrame.maxY - panelSize.height - margin
            }
            y = aboveY
        }

        return CGPoint(x: x, y: y)
    }
}

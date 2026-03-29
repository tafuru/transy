import Foundation

enum PopupPositionCalculator {
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
        let availableWidth = screenFrame.width - 2 * margin
        let x: CGFloat
        if panelSize.width >= availableWidth {
            x = screenFrame.minX + margin
        } else {
            var candidateX = cursorLocation.x - panelSize.width / 2
            candidateX = max(screenFrame.minX + margin, candidateX)
            candidateX = min(screenFrame.maxX - panelSize.width - margin, candidateX)
            x = candidateX
        }

        // 2. Vertical: try below cursor first
        let belowY = cursorLocation.y - offset - panelSize.height
        let minY = screenFrame.minY + margin
        let maxY = screenFrame.maxY - margin

        let y: CGFloat
        if belowY >= minY, belowY + panelSize.height <= maxY {
            // Fits below cursor within screen bounds
            y = belowY
        } else if belowY >= minY {
            // Below fits at bottom but top overflows (cursor outside visibleFrame)
            y = belowY
        } else {
            // Flip above cursor
            var aboveY = cursorLocation.y + offset
            let topLimit = maxY - panelSize.height
            if topLimit >= minY {
                aboveY = min(max(aboveY, minY), topLimit)
            } else {
                aboveY = minY
            }
            y = aboveY
        }

        return CGPoint(x: x, y: y)
    }
}

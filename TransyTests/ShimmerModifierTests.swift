import SwiftUI
import Testing
@testable import Transy

struct ShimmerModifierTests {
    @Test("shimmer() extension returns a ModifiedContent view")
    @MainActor
    func shimmerExtensionReturnsModifiedContent() {
        let result = Text("Test").shimmer()
        let typeName = String(describing: type(of: result))
        #expect(typeName.contains("ModifiedContent"), "shimmer() should wrap content in ModifiedContent")
    }

    @Test("ShimmerModifier is accessible via @testable import")
    @MainActor
    func shimmerModifierIsAccessible() {
        let modifier = ShimmerModifier()
        let typeName = String(describing: type(of: modifier))
        #expect(typeName == "ShimmerModifier", "Type should be ShimmerModifier")
    }

    @Test("shimmer modifier can be applied to non-Text views")
    @MainActor
    func shimmerWorksOnAnyView() {
        let result = Color.red.shimmer()
        let typeName = String(describing: type(of: result))
        #expect(typeName.contains("ModifiedContent"), "shimmer() should work on any View type")
    }
}

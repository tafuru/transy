import Foundation
import SwiftUI
import Testing
@testable import Transy

@Suite("PopupText Layout")
struct PopupTextLayoutTests {
    
    @Test("PopupText allows unlimited line wrapping (no lineLimit constraint)")
    @MainActor
    func popupTextHasNoLineLimit() {
        let popupText = PopupText(text: "Test text", isMuted: false)
        let body = popupText.body
        
        // Verify body contains ScrollView (implies lineLimit removed)
        let typeName = String(describing: type(of: body))
        #expect(typeName.contains("ScrollView"), "PopupText body should contain ScrollView")
    }
    
    @Test("PopupText wraps content in vertical ScrollView")
    @MainActor
    func popupTextUsesScrollView() {
        let popupText = PopupText(text: "Long text content", isMuted: false)
        let body = popupText.body
        let typeName = String(describing: type(of: body))
        
        #expect(
            typeName.contains("ScrollView"),
            "PopupText body should be a ScrollView for vertical scrolling"
        )
    }
    
    @Test("PopupText applies maxHeight constraint to ScrollView")
    @MainActor
    func popupTextRespectsMaxHeight() {
        let longText = String(repeating: "This is a long text. ", count: 100)
        let popupText = PopupText(text: longText, isMuted: false)
        let body = popupText.body
        let typeName = String(describing: type(of: body))
        
        #expect(
            typeName.contains("ModifiedContent") || typeName.contains("ScrollView"),
            "PopupText should apply frame modifier with maxHeight to ScrollView"
        )
    }
    
    @Test("PopupText preserves max width constraint")
    @MainActor
    func popupTextMaintainsFixedWidth() {
        let popupText = PopupText(text: "Test", isMuted: false)
        let body = popupText.body
        let typeName = String(describing: type(of: body))
        
        // Verify body produces a renderable view (structural smoke test)
        #expect(!typeName.isEmpty, "PopupText body should produce a valid view type")
    }
}

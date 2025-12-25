import Foundation
import Testing

@testable import SharedUI

@Test
func demoSectionHasAllCases() {
    #expect(DemoSection.allCases.count == 6)
}

@Test
func demoSectionTitlesNotEmpty() {
    for section in DemoSection.allCases {
        #expect(!section.title.isEmpty)
        #expect(!section.systemImage.isEmpty)
    }
}

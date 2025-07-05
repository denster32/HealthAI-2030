import XCTest
import SwiftUI
import SnapshotTesting
@testable import HealthAI_2030

final class SkillMarketplaceViewSnapshot: XCTestCase {
    func testSkillMarketplaceView() {
        let view = SkillMarketplaceView()
        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }
}

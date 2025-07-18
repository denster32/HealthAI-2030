import XCTest
import SwiftUI
@testable import HealthAI_2030

import SnapshotTesting
import SwiftUI

final class SkillMarketplaceViewSnapshotTests: XCTestCase {
    func testSkillMarketplaceViewSnapshot() {
        let view = SkillMarketplaceView().frame(width: 375, height: 812)
        assertSnapshot(matching: view, as: .image)
        XCTAssertNotNil(view)
    }
}

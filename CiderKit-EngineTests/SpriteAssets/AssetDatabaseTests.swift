import XCTest
import CiderKit_Engine

class AssetDatabaseTests: XCTestCase {

    func testIdSanitation() throws {
        XCTAssertEqual(AssetDatabase.sanitizeId("-"), "")
        XCTAssertEqual(AssetDatabase.sanitizeId("aBc"), "abc")
        XCTAssertEqual(AssetDatabase.sanitizeId("A Super Long Test"), "a-super-long-test")
        XCTAssertEqual(AssetDatabase.sanitizeId("A _ Super _ Long _ Test"), "a-super-long-test")
        XCTAssertEqual(AssetDatabase.sanitizeId("éà@"), "")
    }

}

import XCTest
import CiderKit_Engine

class AssetDatabaseTests: XCTestCase {

    func testIdSanitation() throws {
        XCTAssertEqual(AssetDatabase.idFromFilename("-"), "")
        XCTAssertEqual(AssetDatabase.idFromFilename("aBc"), "abc")
        XCTAssertEqual(AssetDatabase.idFromFilename("A Super Long Test"), "a-super-long-test")
        XCTAssertEqual(AssetDatabase.idFromFilename("A _ Super _ Long _ Test"), "a-super-long-test")
        XCTAssertEqual(AssetDatabase.idFromFilename("éà@"), "")
    }

}

import XCTest
import CiderKit_Engine

class SpriteAssetDatabaseTests: XCTestCase {

    func testExample() throws {
        XCTAssertEqual(SpriteAssetDatabase.idFromFilename("-"), "")
        XCTAssertEqual(SpriteAssetDatabase.idFromFilename("aBc"), "abc")
        XCTAssertEqual(SpriteAssetDatabase.idFromFilename("A Super Long Test"), "a-super-long-test")
        XCTAssertEqual(SpriteAssetDatabase.idFromFilename("A _ Super _ Long _ Test"), "a-super-long-test")
        XCTAssertEqual(SpriteAssetDatabase.idFromFilename("éà@"), "")
    }

}

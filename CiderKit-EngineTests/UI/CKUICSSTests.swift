import XCTest
import CiderCSSKit
@testable import CiderKit_Engine

final class CKUICSSTests: XCTestCase {

    func testExample() throws {
        let spriteAttributeValue = "sprite(\"test\", sliced, 0.1, 0.2, 0.3, 0.4), sprite(\"test2\", scaled), spriteref(\"named_sprite\")"
        let values = try CSSParser.parse(attributeValue: spriteAttributeValue, validationConfiguration: CKUICSSValidationConfiguration())
        XCTAssertEqual(values.count, 3)
        
        guard case let .custom(customValue1) = values[0] else {
            XCTFail("First value must be custom")
            return
        }
        let firstAttribute = CKUISpriteDescriptor.sprite("test", CKUIScalingMethod.sliced, 0.1, 0.2, 0.3, 0.4)
        XCTAssertTrue(customValue1.isEqual(firstAttribute))
        
        guard case let .custom(customValue2) = values[1] else {
            XCTFail("Second value must be custom")
            return
        }
        let secondAttribute = CKUISpriteDescriptor.sprite("test2", CKUIScalingMethod.scaled, 0, 0, 0, 0)
        XCTAssertTrue(customValue2.isEqual(secondAttribute))
        
        guard case let .custom(customValue3) = values[2] else {
            XCTFail("Third value must be custom")
            return
        }
        let thirdAttribute = CKUISpriteDescriptor.spriteref("named_sprite")
        XCTAssertTrue(customValue3.isEqual(thirdAttribute))
    }

}

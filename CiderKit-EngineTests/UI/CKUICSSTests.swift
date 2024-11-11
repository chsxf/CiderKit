import XCTest
import CiderCSSKit
@testable import CiderKit_Engine

final class CKUICSSTests: XCTestCase {

    func testAnchoredPosition() throws {
        let attribute = CKUICSSAttributes.anchoredPosition
        var attributeValue = "0 0"
        var values = try CSSParser.parse(attributeName: attribute, attributeValue: attributeValue, validationConfiguration: CKUICSSValidationConfiguration.default)
        XCTAssertEqual(values.count, 2)

        attributeValue = "50px -123in"
        values = try CSSParser.parse(attributeName: attribute, attributeValue: attributeValue, validationConfiguration: CKUICSSValidationConfiguration.default)
        XCTAssertEqual(values.count, 2)

        guard case let .length(length1, unit1) = values[0] else {
            XCTFail("First value is not a length")
            return
        }
        XCTAssertEqual(length1, 50)
        XCTAssertEqual(unit1, CSSLengthUnit.px)

        guard case let .length(length2, unit2) = values[1] else {
            XCTFail("Second value is not a length")
            return
        }
        XCTAssertEqual(length2, -123)
        XCTAssertEqual(unit2, CSSLengthUnit.in)
    }

    func testAnchors() throws {
        let attribute = CKUICSSAttributes.anchors
        var attributeValue = "0 0 0 0"
        var values = try CSSParser.parse(attributeName: attribute, attributeValue: attributeValue, validationConfiguration: CKUICSSValidationConfiguration.default)
        XCTAssertEqual(values.count, 4)

        attributeValue = "bottom right"
        values = try CSSParser.parse(attributeName: attribute, attributeValue: attributeValue, validationConfiguration: CKUICSSValidationConfiguration.default)
        XCTAssertEqual(values.count, 2)

        guard case let .percentage(percent1) = values[0] else {
            XCTFail("First value is not a percent")
            return
        }
        XCTAssertEqual(percent1, 0)

        guard case let .percentage(percent2) = values[1] else {
            XCTFail("Second value is not a percent")
            return
        }
        XCTAssertEqual(percent2, 100)
    }

    func testSizeDelta() throws {
        let attribute = CKUICSSAttributes.sizeDelta
        var attributeValue = "0 0"
        var values = try CSSParser.parse(attributeName: attribute, attributeValue: attributeValue, validationConfiguration: CKUICSSValidationConfiguration.default)
        XCTAssertEqual(values.count, 2)

        attributeValue = "50px -123in"
        values = try CSSParser.parse(attributeName: attribute, attributeValue: attributeValue, validationConfiguration: CKUICSSValidationConfiguration.default)
        XCTAssertEqual(values.count, 2)

        guard case let .length(length1, unit1) = values[0] else {
            XCTFail("First value is not a length")
            return
        }
        XCTAssertEqual(length1, 50)
        XCTAssertEqual(unit1, CSSLengthUnit.px)

        guard case let .length(length2, unit2) = values[1] else {
            XCTFail("Second value is not a length")
            return
        }
        XCTAssertEqual(length2, -123)
        XCTAssertEqual(unit2, CSSLengthUnit.in)
    }

}

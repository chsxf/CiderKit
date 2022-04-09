import XCTest
import CiderKit_Engine

class MapAreaTests: XCTestCase {

    func testInit() throws {
        let area = MapArea(x: 2, y: 4, width: 8, height: 2)
        
        XCTAssertEqual(area.x, 2)
        XCTAssertEqual(area.y, 4)
        XCTAssertEqual(area.width, 8)
        XCTAssertEqual(area.height, 2)
    }
    
    func testInitFromCGRect() throws {
        let cgRect = CGRect(x: 3.2, y: 1.6, width: 10.4, height: 11.8)
        let area = MapArea(from: cgRect)
        
        XCTAssertEqual(area.x, 3)
        XCTAssertEqual(area.y, 1)
        XCTAssertEqual(area.width, 11)
        XCTAssertEqual(area.height, 13)
    }

    func testContains() throws {
        let containerArea = MapArea(x: 10, y: 10, width: 100, height: 100)
        
        let containedArea = MapArea(x: 20, y: 20, width: 40, height: 40)
        XCTAssertTrue(containerArea.contains(containedArea))
        
        let matchingArea = MapArea(x: 10, y: 10, width: 100, height: 100)
        XCTAssertTrue(containerArea.contains(matchingArea))
        
        let notContainedArea = MapArea(x: 0, y: 0, width: 100, height: 100)
        XCTAssertFalse(containerArea.contains(notContainedArea))
    }
    
    func testIntersects() throws {
        let intersectorArea = MapArea(x: 10, y: 10, width: 100, height: 100)
        
        let containedArea = MapArea(x: 20, y: 20, width: 40, height: 40)
        XCTAssertTrue(intersectorArea.intersects(containedArea))
        
        let matchingArea = MapArea(x: 10, y: 10, width: 100, height: 100)
        XCTAssertTrue(intersectorArea.intersects(matchingArea))
        
        let intersectingArea = MapArea(x: 0, y: 0, width: 100, height: 100)
        XCTAssertTrue(intersectorArea.intersects(intersectingArea))
        
        let notIntersectingArea = MapArea(x: 0, y: 0, width: 5, height: 5)
        XCTAssertFalse(intersectorArea.intersects(notIntersectingArea))
    }
    
    func testIntersection() throws {
        let intersectorArea = MapArea(x: 10, y: 10, width: 100, height: 100)
        
        let containedArea = MapArea(x: 20, y: 20, width: 40, height: 40)
        XCTAssertEqual(intersectorArea.intersection(containedArea), containedArea)
        
        let matchingArea = MapArea(x: 10, y: 10, width: 100, height: 100)
        XCTAssertEqual(intersectorArea.intersection(matchingArea), matchingArea)
        
        let intersectingArea = MapArea(x: 0, y: 0, width: 100, height: 100)
        XCTAssertEqual(intersectorArea.intersection(intersectingArea), MapArea(x: 10, y: 10, width: 90, height: 90))
        
        let notIntersectingArea = MapArea(x: 0, y: 0, width: 5, height: 5)
        XCTAssertNil(intersectorArea.intersection(notIntersectingArea))
    }
    
}

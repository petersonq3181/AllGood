//
//  TextModeratorIntegrationTests.swift
//  AllGoodTests
//
//  Created by Quinn Peterson on 10/1/25.
//

import Foundation
import XCTest
@testable import AllGood

final class TextModeratorIntegrationTests: XCTestCase {
        
    override func setUp() async throws {
        try await super.setUp()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
    }
    
    // MARK: - Tests
    
    func testCheckTextAllowed0() async throws {
        let testText = "Hello, this is a safe text"
        
        do {
            let isAllowed = try await TextModerator.checkText(testText)
            XCTAssertTrue(isAllowed, "Expected text to be allowed")
        } catch {
            XCTFail("Request failed with error: \(error)")
        }
    }
    
    func testCheckTextAllowed1() async throws {
        let testText = "Volunteered for 3 hours."
        
        do {
            let isAllowed = try await TextModerator.checkText(testText)
            XCTAssertTrue(isAllowed, "Expected text to be allowed")
        } catch {
            XCTFail("Request failed with error: \(error)")
        }
    }
    
    func testCheckTextAllowed2() async throws {
        let testText = "Volunteered at habitat for humanity for 4 hours. Then, bought my Mother a donut. Then gave ten dollars to a homeless person."
        
        do {
            let isAllowed = try await TextModerator.checkText(testText)
            XCTAssertTrue(isAllowed, "Expected text to be allowed")
        } catch {
            XCTFail("Request failed with error: \(error)")
        }
    }
    
    func testCheckTextDisallowed0() async throws {
        let testText = "I ran over someone with my car today on purpose"
        
        do {
            let isAllowed = try await TextModerator.checkText(testText)
            XCTAssertFalse(isAllowed, "Expected text to be disallowed")
        } catch {
            XCTFail("Request failed with error: \(error)")
        }
    }
    
    func testCheckTextDisallowed1() async throws {
        let testText = "This morning I made love"
        
        do {
            let isAllowed = try await TextModerator.checkText(testText)
            XCTAssertFalse(isAllowed, "Expected text to be disallowed")
        } catch {
            XCTFail("Request failed with error: \(error)")
        }
    }
    
    func testCheckTextDisallowed2() async throws {
        let testText = "I committed a murder"
        
        do {
            let isAllowed = try await TextModerator.checkText(testText)
            XCTAssertFalse(isAllowed, "Expected text to be disallowed")
        } catch {
            XCTFail("Request failed with error: \(error)")
        }
    }
}

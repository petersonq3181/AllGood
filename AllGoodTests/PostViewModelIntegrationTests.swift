//
//  PostViewModelIntegrationTests.swift
//  AllGoodTests
//
//  Created by Quinn Peterson on 9/26/25.
//

import Foundation
import XCTest
@testable import AllGood
import Firebase
import FirebaseFirestore

final class PostViewModelIntegrationTests: XCTestCase {
        
    var db: Firestore!
    var collection: String!
    let testAppName: String = "allgood-test"
    
    override func setUp() {
        super.setUp()

        // configure Firebase test app only once
        if FirebaseApp.app(name: testAppName) == nil {
            if let filePath = Bundle(for: type(of: self)).path(forResource: "GoogleService-Info-Test", ofType: "plist"),
               let options = FirebaseOptions(contentsOfFile: filePath) {
                FirebaseApp.configure(name: testAppName, options: options)
            } else {
                XCTFail("Could not load GoogleService-Info-Test.plist")
            }
        }

        // point Firestore to the test app
        db = Firestore.firestore(app: FirebaseApp.app(name: testAppName)!)
        collection = "posts"
    }
    
    override func tearDown() {
        db = nil
        collection = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_GG() throws {
        // create post
        let post = Post(
            userId: "KhdhNU2o6bOuqtyj0GehbbKJUTx2",
            userName: "anon",
            type: PostType.kindness,
            location: GeoPoint(latitude: 37.74685454889474, longitude: 122.39506747538778),
            locationString: "Capitol Hill, San Francisco, CA, United States",
            description: "An act of kindness."
        )
        // store
        let docRef = try db.collection(collection).addDocument(from: post)
        
        XCTAssertNotNil(docRef)
        XCTAssertFalse(docRef.documentID.isEmpty)
    }
}

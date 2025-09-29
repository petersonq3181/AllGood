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

// assumes test DB populated with specific test data (see DB dump)

@MainActor
final class PostViewModelIntegrationTests: XCTestCase {
        
    var db: Firestore!
    var collection: String!
    let testAppName: String = "allgood-test"
    
    var postViewModel: PostViewModel!
    
    override func setUp() {
        super.setUp()

        if FirebaseApp.app(name: testAppName) == nil {
            if let filePath = Bundle(for: type(of: self)).path(forResource: "GoogleService-Info-Test", ofType: "plist"),
               let options = FirebaseOptions(contentsOfFile: filePath) {
                FirebaseApp.configure(name: testAppName, options: options)
            } else {
                XCTFail("Could not load GoogleService-Info-Test.plist")
            }
        }

        db = Firestore.firestore(app: FirebaseApp.app(name: testAppName)!)
        collection = "posts"
        FirestoreManager.setTestDB(db)

        let postManager = PostManager(db: FirestoreManager.db)
        postViewModel = PostViewModel(postManager: postManager)
    }
    
    override func tearDown() {
        db = nil
        collection = nil
        postViewModel = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testLoadUserPosts_withValidUser_returnPosts() async throws {
        await postViewModel.loadUserPosts(userId: "LPOjPKzvFNOOlGlzcqJB66VBt4v1")
        
        XCTAssertFalse(postViewModel.userPosts.isEmpty)
    }
}

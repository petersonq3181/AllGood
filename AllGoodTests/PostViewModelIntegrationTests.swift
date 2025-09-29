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
    
    func testLoadUserPosts_withInvalidUser_returnsEmptyArray() async throws {
        await postViewModel.loadUserPosts(userId: "notauserID")
        XCTAssertTrue(postViewModel.userPosts.isEmpty)
    }
    
    func testFetchAllPosts_returnPosts() async throws {
        await postViewModel.fetchAllPosts()
        XCTAssertFalse(postViewModel.allWorldPosts.isEmpty)
        XCTAssertFalse(postViewModel.worldPosts.isEmpty)
        XCTAssertEqual(
            postViewModel.allWorldPosts.count,
            postViewModel.worldPosts.count
        )
    }
    
    func testCreatePost_withValidData() async throws {
        let numAllWorldPosts = postViewModel.allWorldPosts.count
        let numWorldPosts = postViewModel.worldPosts.count
        
        let userId = "KhdhNU2o6bOuqtyj0GehbbKJUTx2"
        var document = try await db.collection("users").document(userId).getDocument()
        var user = try document.data(as: User.self)
        let streakPostBest = user.streakPostBest
        
        await postViewModel.createPost(
            userId: userId,
            userName: "mrstar",
            type: PostType.kindness,
            location: GeoPoint(latitude: 37.74685454889474, longitude: 122.39506747538778),
            locationString: "Capitol Hill, San Francisco, CA, U.S.",
            description: "Donated a penny."
        )
        
        XCTAssertEqual(numAllWorldPosts + 1, postViewModel.allWorldPosts.count)
        XCTAssertEqual(numWorldPosts + 1, postViewModel.worldPosts.count)
        
        // assuming the user's last post date wasn't within past 48 horus
        document = try await db.collection("users").document(userId).getDocument()
        user = try document.data(as: User.self)
        XCTAssertEqual(user.streakPost, 1)
        XCTAssertEqual(user.streakPostBest, streakPostBest)
        
        let userLastPost: Date = user.lastPost
        XCTAssertTrue(Calendar.current.isDateInToday(userLastPost), "Expected user.lastPost to be today, but it was \(userLastPost)")
    }
    
    func testFetchPostById_withValidId_returnPost() async throws {
        XCTAssertNil(postViewModel.selectedPostDetails)
        
        await postViewModel.fetchPostById("41azrvoBmuVQcmVamMui")
        
        XCTAssertNotNil(postViewModel.selectedPostDetails)
        XCTAssertEqual(postViewModel.selectedPostDetails?.locationString, "City Park, Denver, CO, USA")
    }
    
    func testFetchPostById_withInvalidId_returnNil() async throws {
        XCTAssertNil(postViewModel.selectedPostDetails)
        
        await postViewModel.fetchPostById("invalidpostid")
        
        XCTAssertNil(postViewModel.selectedPostDetails)
        XCTAssertNotNil(postViewModel.errorMessage)
    }
    
    func testFetchPostById_withEmptyId_returnNil() async throws {
        XCTAssertNil(postViewModel.selectedPostDetails)
        
        await postViewModel.fetchPostById("")
        
        XCTAssertNil(postViewModel.selectedPostDetails)
        XCTAssertEqual(postViewModel.errorMessage, "Post ID cannot be empty")
    }
    
    func testUserCanPost_withValidId_returnTrue() async throws {
        let canPost = await postViewModel.userCanPost(userId: "VUQYHkl8DxhhdEi2QexevB8XXSF2")
        XCTAssertTrue(canPost)
    }
    
    func testUserCanPost_withValidId_returnFalse() async throws {
        let canPost = await postViewModel.userCanPost(userId: "KhdhNU2o6bOuqtyj0GehbbKJUTx2")
        XCTAssertFalse(canPost)
    }
    
    func testUserCanPost_withInvalidId_returnNil() async throws {
        let canPost = await postViewModel.userCanPost(userId: "invaliduserid")
        XCTAssertFalse(canPost)
        XCTAssertNotNil(postViewModel.errorMessage)
    }
    
    func testUserCanPost_withEmptyId_returnNil() async throws {
        let canPost = await postViewModel.userCanPost(userId: "")
        XCTAssertFalse(canPost)
        XCTAssertNotNil(postViewModel.errorMessage)
    }
    
    func testFormattedLocation_normalCase() {
        let post = Post(
            userId: "1",
            userName: "Test",
            type: .kindness,
            location: GeoPoint(latitude: 0, longitude: 0),
            locationString: "Neighborhood, City, State, Country",
            description: "desc"
        )

        let result = postViewModel.formattedLocation(for: post)
        XCTAssertEqual(result, "City, State")
    }

    func testFormattedLocation_missingParts() {
        let post1 = Post(
            userId: "1",
            userName: "Test",
            type: .kindness,
            location: GeoPoint(latitude: 0, longitude: 0),
            locationString: "City",
            description: "desc"
        )
        XCTAssertEqual(postViewModel.formattedLocation(for: post1), "City, City")

        let post2 = Post(
            userId: "1",
            userName: "Test",
            type: .kindness,
            location: GeoPoint(latitude: 0, longitude: 0),
            locationString: "City, State",
            description: "desc"
        )
        XCTAssertEqual(postViewModel.formattedLocation(for: post2), "State, State")
    }

    func testFormattedLocation_nilOrEmpty() {
        let post1 = Post(
            userId: "1",
            userName: "Test",
            type: .kindness,
            location: GeoPoint(latitude: 0, longitude: 0),
            locationString: "",
            description: "desc"
        )
        XCTAssertNil(postViewModel.formattedLocation(for: post1))

        let post2 = Post(
            userId: "1",
            userName: "Test",
            type: .kindness,
            location: GeoPoint(latitude: 0, longitude: 0),
            locationString: "   ",
            description: "desc"
        )
        XCTAssertNil(postViewModel.formattedLocation(for: post2))
    }
}

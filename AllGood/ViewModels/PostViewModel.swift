//
//  PostViewModel.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/18/25.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class PostViewModel: ObservableObject {
    
    // posts for current user
    @Published var userPosts: [Post] = []
    
    @Published private(set) var allWorldPosts: [Post] = [] { // full dataset
        didSet {
            applyFilters()
        }
    }
    @Published var worldPosts: [Post] = []            // filtered dataset
    @Published var selectedPostDetails: Post?
    
    @Published var selectedDateFilter: PostDateFilter = .all
    @Published var selectedTypeFilter: PostTypeFilter = .all
    
    @Published var errorMessage: String?
    
    private let postManager: PostManager
    
    init(postManager: PostManager) {
        self.postManager = postManager
    }
    
    func loadUserPosts(userId: String) async {
        do {
            userPosts = try await postManager.fetchPostsByUser(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func fetchAllPosts() async {
        do {
            let posts = try await postManager.fetchAllWorldPosts()
            self.allWorldPosts = posts
            self.worldPosts = posts
        } catch {
            print("Error fetching all posts: \(error)")
            self.allWorldPosts = []
            self.worldPosts = []
        }
    }
    
    func createPost(
        userId: String,
        userName: String,
        type: PostType,
        location: GeoPoint,
        locationString: String,
        description: String
    ) async {
        do {
            let newPost = try await postManager.createPost(
                userId: userId,
                userName: userName,
                type: type,
                location: location,
                locationString: locationString,
                description: description
            )
            
            allWorldPosts.append(newPost)
            print("Post created successfully")
            
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to create post: \(error)")
        }
    }
    
    func fetchPostById(_ id: String) async {
        guard !id.isEmpty else {
            errorMessage = "Post ID cannot be empty"
            selectedPostDetails = nil
            return
        }

        errorMessage = nil
        do {
            let post = try await postManager.fetchPostById(id)
            selectedPostDetails = post
        } catch {
            errorMessage = error.localizedDescription
            selectedPostDetails = nil
        }
    }
    
    // returns true if the user is allowed to post (hasn't posted in the last 24 hours)
    func userCanPost(userId: String) async -> Bool {
        guard !userId.isEmpty else {
            errorMessage = "User ID cannot be empty"
            return false
        }
        
        do {
            return try await postManager.userCanPost(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func formattedLocation(for post: Post) -> String? {
        guard let locationString = post.locationString else { return nil }
        
        let parts = locationString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        let primary = parts.count > 1 ? parts[1] : parts.first ?? ""
        let secondary = parts.count > 2 ? parts[2] : parts.last ?? ""
        
        let result = "\(primary), \(secondary)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ","))

        return result.isEmpty ? nil : result
    }
    
    func applyFilters() {
        worldPosts = postManager.filterPosts(
            posts: allWorldPosts,
            dateFilter: selectedDateFilter,
            typeFilter: selectedTypeFilter
        )
    }
}

#if DEBUG
final class MockPostViewModel: PostViewModel {
    init(posts: [Post] = Post.mockPosts) {
        // don’t call Firestore-backed init, just inject a dummy manager
        super.init(postManager: PostManager(db: FirestoreManager.db))
        self.userPosts = userPosts
    }
    
    // disable networking in previews
    override func loadUserPosts(userId: String) async { }
    override func fetchAllPosts() async { }
}
#endif

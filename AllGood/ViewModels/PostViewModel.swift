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
    @Published var posts: [Post] = []
    
    // posts around the world
    var postLocations: [PostLocation] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let postManager: PostManager
    
    init(postManager: PostManager) {
        self.postManager = postManager
    }
    
    func loadUserPosts(userId: String) {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                posts = try await postManager.fetchPostsByUser(userId: userId)
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    func fetchAllPosts() {
        print("in postViewModel fetchAllPosts")
        postManager.fetchAllPostLocations { [weak self] posts in
            DispatchQueue.main.async {
                self?.postLocations = posts
            }
        }
    }
    
    func createPost(
        userId: String,
        userName: String,
        type: PostType,
        location: GeoPoint,
        description: String
    ) {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                let _ = try await postManager.createPost(
                    userId: userId,
                    userName: userName,
                    type: type,
                    location: location,
                    description: description
                )
                isLoading = false
                print("Post created successfully")
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                print("Failed to create post: \(error)")
            }
        }
    }
}

#if DEBUG
final class MockPostViewModel: PostViewModel {
    init(posts: [Post] = Post.mockPosts) {
        // Don’t call Firestore-backed init, just inject a dummy manager
        super.init(postManager: PostManager())
        self.posts = posts
    }
    
    // Disable networking in previews
    override func loadUserPosts(userId: String) { }
    override func fetchAllPosts() { }
}
#endif

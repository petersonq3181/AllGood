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
    
    // posts around the world
    @Published var worldPosts: [PostLocation] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedPostDetails: Post?
    
    private let postManager: PostManager
    
    init(postManager: PostManager) {
        self.postManager = postManager
    }
    
    func loadUserPosts(userId: String) {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                userPosts = try await postManager.fetchPostsByUser(userId: userId)
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    func fetchAllPosts() {
        postManager.fetchAllWorldPosts { [weak self] posts in
            DispatchQueue.main.async {
                self?.worldPosts = posts
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
                let newPostId = try await postManager.createPost(
                    userId: userId,
                    userName: userName,
                    type: type,
                    location: location,
                    description: description
                )
                
                isLoading = false
                
                let newPostLocation = PostLocation(id: newPostId, location: location)
                worldPosts.append(newPostLocation)
                
                print("Post created successfully")
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                print("Failed to create post: \(error)")
            }
        }
    }
    
    func fetchPostById(_ id: String) {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                let post = try await postManager.fetchPostById(id)
                selectedPostDetails = post
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    // returns true if the user is allowed to post (hasn't posted in the last 24 hours)
    func userCanPost(userId: String) async -> Bool {
        do {
            return try await postManager.userCanPost(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

#if DEBUG
final class MockPostViewModel: PostViewModel {
    init(posts: [Post] = Post.mockPosts) {
        // Don’t call Firestore-backed init, just inject a dummy manager
        super.init(postManager: PostManager())
        self.userPosts = userPosts
    }
    
    // Disable networking in previews
    override func loadUserPosts(userId: String) { }
    override func fetchAllPosts() { }
}
#endif

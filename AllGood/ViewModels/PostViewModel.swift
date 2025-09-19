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
    @Published var posts: [Post] = []
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
    
    func loadAllPosts() {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                posts = try await postManager.fetchAllPosts()
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
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
    override func loadAllPosts() { }
}
#endif

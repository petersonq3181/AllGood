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
final class PostViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let postManager = PostManager()
    
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
    
    func createPost(
        userId: String,
        userName: String,
        type: PostType,
        location: GeoPoint,
        description: String
    ) async {
        do {
            let postId = try await postManager.createPost(
                userId: userId,
                userName: userName,
                type: type,
                location: location,
                description: description
            )
            loadUserPosts(userId: userId) // Refresh the user's posts
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

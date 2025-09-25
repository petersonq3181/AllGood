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
    
    @Published private var allWorldPosts: [Post] = [] { // full dataset
        didSet {
            applyFilters()
        }
    }
    @Published var worldPosts: [Post] = []            // filtered dataset
    

    
    @Published var selectedDateFilter: PostDateFilter = .all
    @Published var selectedTypeFilter: PostTypeFilter = .all
    
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
                self?.allWorldPosts = posts
                self?.worldPosts = posts
            }
        }
    }
    
    func createPost(
        userId: String,
        userName: String,
        type: PostType,
        location: GeoPoint,
        locationString: String,
        description: String
    ) {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                let newPost: Post = try await postManager.createPost(
                    userId: userId,
                    userName: userName,
                    type: type,
                    location: location,
                    locationString: locationString,
                    description: description
                )
                
                isLoading = false
                
                allWorldPosts.append(newPost)
                
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
    
    func formattedLocation(for post: Post) -> String? {
        guard let locationString = post.locationString else { return nil }
        
        let parts = locationString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        let primary = parts.count > 1 ? parts[1] : parts.first ?? ""
        let secondary = parts.count > 2 ? parts[2] : parts.last ?? ""
        
        let result = "\(primary), \(secondary)".trimmingCharacters(in: .whitespacesAndNewlines)
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
        super.init(postManager: PostManager())
        self.userPosts = userPosts
    }
    
    // disable networking in previews
    override func loadUserPosts(userId: String) { }
    override func fetchAllPosts() { }
}
#endif

//
//  PostManager.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/18/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class PostManager {
    
    private let db: Firestore
    private let collection: String
    
    init(db: Firestore) {
        self.db = db
        self.collection = "posts"
    }
        
    func createPost(
        userId: String,
        userName: String,
        avatarNumber: Int,
        type: PostType,
        location: GeoPoint,
        locationString: String,
        description: String
    ) async throws -> Post {
        
        let isAllowed = try await TextModerator.checkText(description)
        
        if !isAllowed {
            throw NSError(domain: "PostManager", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Your post contains inappropriate language."])
        }
           
        // create post
        var post = Post(
            userId: userId,
            userName: userName,
            avatarNumber: avatarNumber,
            type: type,
            location: location,
            locationString: locationString,
            description: description
        )
        // store
        let docRef = try db.collection(collection).addDocument(from: post)
        print("createPost Post created successfully with ID: \(docRef.documentID)")
        post.id = docRef.documentID

        // compute and update user's post streak and best in a single read-modify-write
        let userRef = db.collection("users").document(userId)
        let now = Date()
        let snapshot = try await userRef.getDocument()
        guard let data = snapshot.data() else {
            throw NSError(domain: "CreatePost", code: 1, userInfo: [NSLocalizedDescriptionKey: "User document not found"])
        }
        let lastPostTimestamp = data["lastPost"] as? Timestamp
        let lastPostDate = lastPostTimestamp?.dateValue() ?? Date.distantPast
        let currentStreakPost = data["streakPost"] as? Int ?? 0
        let currentStreakPostBest = data["streakPostBest"] as? Int ?? 0

        let within48h = now.timeIntervalSince(lastPostDate) <= 48 * 60 * 60
        let newStreakPost = within48h ? currentStreakPost + 1 : 1
        let newStreakPostBest = max(currentStreakPostBest, newStreakPost)

        try await userRef.updateData([
            "lastPost": Timestamp(date: now),
            "streakPost": newStreakPost,
            "streakPostBest": newStreakPostBest
        ])
                
        return post
    }
        
    func fetchAllPosts() async throws -> [Post] {
        let snapshot = try await db.collection(collection)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        let posts = snapshot.documents.compactMap { document in
            try? document.data(as: Post.self)
        }
        
        print("fetchAllPosts Fetched \(posts.count) posts")
        return posts
    }
    
    func fetchPostsByUser(userId: String) async throws -> [Post] {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .getDocuments()

        let posts = snapshot.documents.compactMap { document in
            do {
                return try document.data(as: Post.self)
            } catch {
                print("fetchPostsByUser Failed to decode document \(document.documentID): \(error)")
                return nil
            }
        }
        
        print("fetchPostsByUser Fetched \(posts.count) posts for user: \(userId)")
        return posts
    }
    
    func fetchPostsByType(_ type: PostType) async throws -> [Post] {
        let snapshot = try await db.collection(collection)
            .whereField("type", isEqualTo: type.rawValue)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        let posts = snapshot.documents.compactMap { document in
            try? document.data(as: Post.self)
        }
        
        print("fetchPostsByType Fetched \(posts.count) posts of type: \(type.rawValue)")
        return posts
    }
    
    func fetchAllWorldPosts() async throws -> [Post] {
        let snapshot = try await db.collection("posts").getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Post.self)
        }
    }

    func fetchPostById(_ id: String) async throws -> Post {
        let doc = try await db.collection(collection).document(id).getDocument()
        guard doc.exists else {
            throw NSError(domain: "fetchPostById",
                          code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Post not found"])
        }
        return try doc.data(as: Post.self)
    }
    
    func userCanPost(userId: String) async throws -> Bool {
        let userRef = db.collection("users").document(userId)
        let snapshot = try await userRef.getDocument()
        
        guard let data = snapshot.data() else {
            throw NSError(domain: "userCanPost",
                          code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "User document not found"])
        }
        
        if let lastPost = data["lastPost"] as? Timestamp {
            let lastPostDate = lastPost.dateValue()
            
            // compare just the day/month/year, ignoring time
            let calendar = Calendar.current
            return !calendar.isDateInToday(lastPostDate)
        }
        
        return true
    }
    
    func filterPosts(
        posts: [Post],
        dateFilter: PostDateFilter,
        typeFilter: PostTypeFilter
    ) -> [Post] {
        let now = Date()
        let calendar = Calendar.current
        
        return posts.filter { post in
            var passesDate = false
            var passesType = false
            
            switch dateFilter {
            case .all:
                passesDate = true
            case .pastDay:
                passesDate = post.timestamp >= calendar.date(byAdding: .day, value: -1, to: now)!
            case .pastWeek:
                passesDate = post.timestamp >= calendar.date(byAdding: .day, value: -7, to: now)!
            case .pastMonth:
                passesDate = post.timestamp >= calendar.date(byAdding: .month, value: -1, to: now)!
            case .pastYear:
                passesDate = post.timestamp >= calendar.date(byAdding: .year, value: -1, to: now)!
            }
            
            switch typeFilter {
            case .all:
                passesType = true
            case .donation:
                passesType = post.type == .donation
            case .volunteering:
                passesType = post.type == .volunteering
            case .kindness:
                passesType = post.type == .kindness
            }
            
            return passesDate && passesType
        }
    }

    // MARK: HELPERS
    
    private func calculateDistance(from: GeoPoint, to: GeoPoint) -> Double {
        // simplified distance calculation (in km)
        // for production, use more accurate formulas
        let lat1 = from.latitude
        let lon1 = from.longitude
        let lat2 = to.latitude
        let lon2 = to.longitude
        
        // Earth's radius in km
        let earthRadius = 6371.0
        
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        
        let a = sin(dLat/2) * sin(dLat/2) +
                  cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                  sin(dLon/2) * sin(dLon/2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return earthRadius * c
    }
}

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
    
    private let db = Firestore.firestore()
    private let collection = "posts"
        
    func createPost(
        userId: String,
        userName: String,
        type: PostType,
        location: GeoPoint,
        description: String
    ) async throws -> String {
        let post = Post(
            userId: userId,
            userName: userName,
            type: type,
            location: location,
            description: description
        )
        
        let docRef = try db.collection(collection).addDocument(from: post)
        print("✅ Post created successfully with ID: \(docRef.documentID)")
        return docRef.documentID
    }
        
    func fetchAllPosts() async throws -> [Post] {
        let snapshot = try await db.collection(collection)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        let posts = snapshot.documents.compactMap { document in
            try? document.data(as: Post.self)
        }
        
        print("✅ Fetched \(posts.count) posts")
        return posts
    }
    
    func fetchPostsByUser(userId: String) async throws -> [Post] {
        
        print("🔍 Fetching posts for user: \(userId)")


        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        print("📄 Total docs in collection: \(snapshot.documents.count)")
        for doc in snapshot.documents {
            print("📂 Document \(doc.documentID): \(doc.data())")
        }

        for doc in snapshot.documents {
            print("📂 Document \(doc.documentID): \(doc.data())")
        }
        
        let posts = snapshot.documents.compactMap { document in
            do {
                return try document.data(as: Post.self)
            } catch {
                print("❌ Failed to decode document \(document.documentID): \(error)")
                return nil
            }
        }
        
        print("✅ Fetched \(posts.count) posts for user: \(userId)")
        return posts
    }
    
    /// Fetch posts by type
    func fetchPostsByType(_ type: PostType) async throws -> [Post] {
        let snapshot = try await db.collection(collection)
            .whereField("type", isEqualTo: type.rawValue)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        let posts = snapshot.documents.compactMap { document in
            try? document.data(as: Post.self)
        }
        
        print("✅ Fetched \(posts.count) posts of type: \(type.rawValue)")
        return posts
    }
    
    // MARK: - Helper Methods
    
    private func calculateDistance(from: GeoPoint, to: GeoPoint) -> Double {
        // Simplified distance calculation (in km)
        // For production, use more accurate formulas
        let lat1 = from.latitude
        let lon1 = from.longitude
        let lat2 = to.latitude
        let lon2 = to.longitude
        
        let earthRadius = 6371.0 // Earth's radius in km
        
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        
        let a = sin(dLat/2) * sin(dLat/2) +
                  cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                  sin(dLon/2) * sin(dLon/2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return earthRadius * c
    }
}

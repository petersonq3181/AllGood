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
        print("createPost Post created successfully with ID: \(docRef.documentID)")
        return docRef.documentID
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
    
    func fetchAllPostLocations(completion: @escaping ([PostLocation]) -> Void) {
        db.collection("posts").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching post locations: \(error)")
                completion([])
                return
            }
            
            let posts: [PostLocation] = snapshot?.documents.compactMap { doc in
                guard let geoPoint = doc.get("location") as? GeoPoint else {
                    return nil
                }
                return PostLocation(id: doc.documentID, location: geoPoint)
            } ?? []

            completion(posts)
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

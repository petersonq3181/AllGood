//
//  AuthenticationManager.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/13/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct AuthDataResultModel {
    let uid: String
    
    init(user: FirebaseAuth.User) {
        self.uid = user.uid
    }
}

final class AuthenticationManager {
    
    private let db: Firestore
    
    init(db: Firestore) {
        self.db = db
    }
    
    func getAuthenticatedUser() throws -> AuthDataResultModel {
        guard let user = Auth.auth().currentUser else {
            // lazy for now could throw diff error
            throw URLError(.badServerResponse)
        }
        
        print("getAuthenticatedUser found user with id: \(user.uid)")
        
        return AuthDataResultModel(user: user)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func setupProfile(username: String, avatarNumber: Int) async throws {
        guard let user = Auth.auth().currentUser else {
            // lazy for now could throw diff error
            throw URLError(.badServerResponse)
        }
        
        let data: [String: Any] = [
            "username": username.trimmingCharacters(in: .whitespacesAndNewlines),
            "avatarNumber": avatarNumber
        ]
        
        try await Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .setData(data, merge: true)
    }
    
    func updateAvatar(avatarNumber: Int) async throws {
        guard let user = Auth.auth().currentUser else {
            // lazy for now could throw diff error
            throw URLError(.badServerResponse)
        }
        
        let data: [String: Any] = [
            "avatarNumber": avatarNumber
        ]
        
        try await Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .setData(data, merge: true)
    }
}

// MARK: SIGN IN ANONYMOUS

extension AuthenticationManager {
    
    @discardableResult
    func signInAnonymous() async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signInAnonymously()
        
        // create user document in Firestore
        try await createUserDocument(uid: authDataResult.user.uid)
        
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    private func createUserDocument(uid: String) async throws {
        let userDocument = AllGood.User(uid: uid, isAnonymous: true)
        
        do {
            try db.collection("users").document(uid).setData(from: userDocument)
            print("createUserDocument Created user document in Firestore: \(uid)")
        } catch {
            print("createUserDocument Failed to create user document: \(error)")
            throw error
        }
    }
}

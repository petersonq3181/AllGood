import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthenticationViewModel: ObservableObject {
    @Published var user: User? = nil
    
    private let authManager = AuthenticationManager()
    
    init() {
        Task {
            await loadCurrentUser()
        }
    }
    
    func loadCurrentUser() async {
        do {
            let authDataResult = try authManager.getAuthenticatedUser()
            
            // Fetch user document from Firestore
            await fetchUserDocument(uid: authDataResult.uid)
            
            print("✅ Found existing user: \(authDataResult.uid)")
        } catch {
            // No user found → create anonymous account
            do {
                let authDataResult = try await authManager.signInAnonymous()
                await fetchUserDocument(uid: authDataResult.uid)
                print("🆕 Created anonymous user: \(authDataResult.uid)")
            } catch {
                print("❌ Failed to sign in anonymously: \(error)")
            }
        }
    }
    
    private func fetchUserDocument(uid: String) async {
        let db = Firestore.firestore()
        
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            if document.exists {
                // User document exists, decode it
                let user = try document.data(as: User.self)
                self.user = user
                print("✅ Fetched user document from Firestore: \(uid)")
            } else {
                // User document doesn't exist, create it
                let userDocument = AllGood.User(uid: uid, isAnonymous: true)
                try db.collection("users").document(uid).setData(from: userDocument)
                self.user = userDocument
                print("✅ Created missing user document in Firestore: \(uid)")
            }
        } catch {
            print("❌ Failed to fetch/create user document: \(error)")
        }
    }
    
    func signOut() {
        do {
            try authManager.signOut()
            self.user = nil
        } catch {
            print("❌ Sign-out failed: \(error)")
        }
    }
}

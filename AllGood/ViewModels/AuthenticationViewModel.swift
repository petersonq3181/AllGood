import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthenticationViewModel: ObservableObject {
    @Published var user: AuthDataResultModel? = nil
    
    private let authManager = AuthenticationManager()
    
    init() {
        Task {
            await loadCurrentUser()
        }
    }
    
    func loadCurrentUser() async {
        do {
            let currentUser = try authManager.getAuthenticatedUser()
            self.user = currentUser
            
            // Check if user document exists in Firestore, create if not
            await ensureUserDocumentExists(uid: currentUser.uid)
            
            print("✅ Found existing user: \(currentUser.uid)")
        } catch {
            // No user found → create anonymous account
            do {
                let newUser = try await authManager.signInAnonymous()
                self.user = newUser
                print("🆕 Created anonymous user: \(newUser.uid)")
            } catch {
                print("❌ Failed to sign in anonymously: \(error)")
            }
        }
    }
    
    private func ensureUserDocumentExists(uid: String) async {
        let db = Firestore.firestore()
        
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            if !document.exists {
                // User document doesn't exist, create it
                let userDocument = AllGood.User(uid: uid, isAnonymous: true)
                try await db.collection("users").document(uid).setData(from: userDocument)
                print("✅ Created missing user document in Firestore: \(uid)")
            } else {
                print("✅ User document already exists in Firestore: \(uid)")
            }
        } catch {
            print("❌ Failed to check/create user document: \(error)")
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

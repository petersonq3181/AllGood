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
            
            await fetchUserDocument(uid: authDataResult.uid)
            
            print("loadCurrentUser Found existing user: \(authDataResult.uid)")
        } catch {
            // no user found --> create anonymous account
            do {
                let authDataResult = try await authManager.signInAnonymous()
                await fetchUserDocument(uid: authDataResult.uid)
                print("loadCurrentUser Created anonymous user: \(authDataResult.uid)")
            } catch {
                print("loadCurrentUser Failed to sign in anonymously: \(error)")
            }
        }
    }
    
    private func fetchUserDocument(uid: String) async {
        let db = Firestore.firestore()
        
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            if document.exists {
                // user document exists, decode it
                let user = try document.data(as: User.self)
                self.user = user
                print("fetchUserDocument Fetched user document from Firestore: \(uid)")
            } else {
                // user document doesn't exist, create it
                let userDocument = AllGood.User(uid: uid, isAnonymous: true)
                try db.collection("users").document(uid).setData(from: userDocument)
                self.user = userDocument
                print("fetchUserDocument Created missing user document in Firestore: \(uid)")
            }
        } catch {
            print("fetchUserDocument Failed to fetch/create user document: \(error)")
        }
    }
    
    func signOut() {
        do {
            try authManager.signOut()
            self.user = nil
        } catch {
            print("signOut failed: \(error)")
        }
    }
}

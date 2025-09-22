import Foundation
import FirebaseAuth
import FirebaseFirestore

private var userListenerRegistration: ListenerRegistration?

@MainActor
class AuthenticationViewModel: ObservableObject {
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
            startUserDocumentListener(uid: authDataResult.uid)
            
            print("loadCurrentUser Found existing user: \(authDataResult.uid)")
        } catch {
            // no user found --> create anonymous account
            do {
                let authDataResult = try await authManager.signInAnonymous()
                await fetchUserDocument(uid: authDataResult.uid)
                startUserDocumentListener(uid: authDataResult.uid)
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

    private func startUserDocumentListener(uid: String) {
        // remove any existing listener before adding a new one
        userListenerRegistration?.remove()
        
        let db = Firestore.firestore()
        userListenerRegistration = db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("startUserDocumentListener error: \(error)")
                return
            }
            guard let snapshot = snapshot, snapshot.exists else { return }
            do {
                let updatedUser = try snapshot.data(as: User.self)
                DispatchQueue.main.async {
                    self.user = updatedUser
                }
            } catch {
                print("startUserDocumentListener decode error: \(error)")
            }
        }
    }
    
    // returns true if the user is allowed to post (hasn't posted in the last 24 hours)
    func userCanPost() -> Bool {
        guard let lastPost = user?.lastPost else {
            return true
        }
        return Date().timeIntervalSince(lastPost) >= 24 * 60 * 60
    }
    
    func signOut() {
        do {
            try authManager.signOut()
            userListenerRegistration?.remove()
            userListenerRegistration = nil
            self.user = nil
        } catch {
            print("signOut failed: \(error)")
        }
    }
}

#if DEBUG
@MainActor
final class MockAuthenticationViewModel: AuthenticationViewModel {
    init(mockUser: User = .mock) {
        super.init()
        self.user = mockUser
    }

    // prevent hitting Firebase in previews/tests
    override func loadCurrentUser() async { }
    override func signOut() { self.user = nil }
}
#endif

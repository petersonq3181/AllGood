import Foundation
import FirebaseAuth
import FirebaseFirestore

private var userListenerRegistration: ListenerRegistration?

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var user: User? = nil
    
    var hasValidUsername: Bool {
        guard let username = user?.username else { return false }
        return !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private let authManager = AuthenticationManager(db: FirestoreManager.db)
    
    init() {
        Task {
            await loadCurrentUser()
        }
    }
    
    func loadCurrentUser() async {
        do {
            let authDataResult = try authManager.getAuthenticatedUser()
            
            await fetchUserDocument(uid: authDataResult.uid)
            await updateStreaksOnAppOpen(uid: authDataResult.uid)
            startUserDocumentListener(uid: authDataResult.uid)
            
            print("loadCurrentUser Found existing user: \(authDataResult.uid)")
        } catch {
            // no user found --> create anonymous account
            do {
                let authDataResult = try await authManager.signInAnonymous()
                await fetchUserDocument(uid: authDataResult.uid)
                await updateStreaksOnAppOpen(uid: authDataResult.uid)
                startUserDocumentListener(uid: authDataResult.uid)
                print("loadCurrentUser Created anonymous user: \(authDataResult.uid)")
            } catch {
                print("loadCurrentUser Failed to sign in anonymously: \(error)")
            }
        }
    }
    
    private func fetchUserDocument(uid: String) async {
        let db = FirestoreManager.db
        
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
        
        let db = FirestoreManager.db
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

    private func updateStreaksOnAppOpen(uid: String) async {
        let db = FirestoreManager.db
        let userRef = db.collection("users").document(uid)
        do {
            let snapshot = try await userRef.getDocument()
            guard let data = snapshot.data() else { return }
            let now = Date()
            let lastOpenDate = (data["lastOpen"] as? Timestamp)?.dateValue()
            let lastPostDate = (data["lastPost"] as? Timestamp)?.dateValue() ?? Date.distantPast
            let currentStreakApp = data["streakApp"] as? Int ?? 0
            let currentStreakAppBest = data["streakAppBest"] as? Int ?? 0
            let currentStreakPost = data["streakPost"] as? Int ?? 0

            var updates: [String: Any] = [:]

            // reset post streak if last post was more than 48h ago
            if now.timeIntervalSince(lastPostDate) > 48 * 60 * 60 {
                if currentStreakPost != 0 { updates["streakPost"] = 0 }
            }

            // app streak: increment at most once per calendar day
            let calendar = Calendar.current
            let newStreakApp: Int
            if let lastOpenDate = lastOpenDate {
                if calendar.isDate(now, inSameDayAs: lastOpenDate) {
                    // same day: do not increment
                    newStreakApp = max(1, currentStreakApp)
                } else if now.timeIntervalSince(lastOpenDate) <= 48 * 60 * 60 {
                    // different day, within 48h window: increment by 1
                    newStreakApp = max(1, currentStreakApp + 1)
                } else {
                    // gap too long: reset to 1
                    newStreakApp = 1
                }
            } else {
                // first open we track
                newStreakApp = 1
            }
            if newStreakApp != currentStreakApp { updates["streakApp"] = newStreakApp }
            let newStreakAppBest = max(currentStreakAppBest, newStreakApp)
            if newStreakAppBest != currentStreakAppBest { updates["streakAppBest"] = newStreakAppBest }

            // always update lastOpen
            updates["lastOpen"] = Timestamp(date: now)

            if !updates.isEmpty {
                try await userRef.updateData(updates)
            }
        } catch {
            print("updateStreaksOnAppOpen error: \(error)")
        }
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
    
    func setupProfile(username: String, avatarNumber: Int) async {
        do {
            try await authManager.setupProfile(username: username, avatarNumber: avatarNumber)
        } catch {
            print("Failed to setup profile: \(error.localizedDescription)")
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

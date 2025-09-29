//
//  FirestoreManager.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/26/25.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

final class FirestoreManager {
    static var sharedDB: Firestore = Firestore.firestore() // production default

    static func setTestDB(_ db: Firestore) {
        sharedDB = db
    }

    static var db: Firestore { sharedDB }
}

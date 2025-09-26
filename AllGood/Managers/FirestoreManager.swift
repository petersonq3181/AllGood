//
//  FirestoreManager.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/26/25.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

class FirestoreManager {
    static var db: Firestore {
        if let testApp = FirebaseApp.app(name: "test") {
            return Firestore.firestore(app: testApp)
        } else {
            return Firestore.firestore()
        }
    }
}

//
//  User.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/13/25.
//

import Foundation
import FirebaseFirestore

struct User: Codable {
    let uid: String
    let createdAt: Date
    let isAnonymous: Bool
    
    init(uid: String, isAnonymous: Bool = true) {
        self.uid = uid
        self.createdAt = Date()
        self.isAnonymous = isAnonymous
    }
}

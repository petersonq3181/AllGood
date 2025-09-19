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
    var username: String?
    var streakApp: Int
    var streakAppBest: Int
    var streakPost: Int
    var streakPostBest: Int
    
    init(uid: String, isAnonymous: Bool = true, username: String? = nil, 
         streakApp: Int = 0, streakAppBest: Int = 0, streakPost: Int = 0, streakPostBest: Int = 0) {
        self.uid = uid
        self.createdAt = Date()
        self.isAnonymous = isAnonymous
        self.username = username
        self.streakApp = streakApp
        self.streakAppBest = streakAppBest
        self.streakPost = streakPost
        self.streakPostBest = streakPostBest
    }
}

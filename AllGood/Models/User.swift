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
    var lastPost: Date
    let isAnonymous: Bool
    var username: String?
    var streakApp: Int
    var streakAppBest: Int
    var streakPost: Int
    var streakPostBest: Int
    
    init(uid: String, isAnonymous: Bool = true, username: String? = nil,
         streakApp: Int = 0, streakAppBest: Int = 0, streakPost: Int = 0, streakPostBest: Int = 0) {
        
        let calendar = Calendar.current
        let components = DateComponents(year: 2000, month: 1, day: 1)
        let oldDate = calendar.date(from: components) ?? Date()
        
        self.uid = uid
        self.createdAt = Date()
        self.lastPost = oldDate
        self.isAnonymous = isAnonymous
        self.username = username
        self.streakApp = streakApp
        self.streakAppBest = streakAppBest
        self.streakPost = streakPost
        self.streakPostBest = streakPostBest
    }
}

// makes sure mock code is only included in debug builds (not production)
#if DEBUG
extension User {
    static var mock: User {
        User(uid: "123", isAnonymous: false, username: "anon",
             streakApp: 9, streakAppBest: 9, streakPost: 3, streakPostBest: 5)
    }
}
#endif

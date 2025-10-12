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
    var lastOpen: Date
    let isAnonymous: Bool
    var username: String?
    var streakApp: Int
    var streakAppBest: Int
    var streakPost: Int
    var streakPostBest: Int
    var avatarNumber: Int
    
    init(uid: String, isAnonymous: Bool = true, username: String? = nil,
         streakApp: Int = 0, streakAppBest: Int = 0, streakPost: Int = 0, streakPostBest: Int = 0, avatarNumber: Int = 1) {
        
        let calendar = Calendar.current
        let components = DateComponents(year: 2000, month: 1, day: 1)
        let oldDate = calendar.date(from: components) ?? Date()
        
        self.uid = uid
        self.createdAt = Date()
        self.lastPost = oldDate
        self.lastOpen = oldDate
        self.isAnonymous = isAnonymous
        self.username = username
        self.streakApp = streakApp
        self.streakAppBest = streakAppBest
        self.streakPost = streakPost
        self.streakPostBest = streakPostBest
        self.avatarNumber = avatarNumber
    }

    enum CodingKeys: String, CodingKey {
        case uid
        case createdAt
        case lastPost
        case lastOpen
        case isAnonymous
        case username
        case streakApp
        case streakAppBest
        case streakPost
        case streakPostBest
        case avatarNumber
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let calendar = Calendar.current
        let components = DateComponents(year: 2000, month: 1, day: 1)
        let oldDate = calendar.date(from: components) ?? Date()
        
        uid = try container.decode(String.self, forKey: .uid)
        createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        lastPost = (try? container.decode(Date.self, forKey: .lastPost)) ?? oldDate
        lastOpen = (try? container.decode(Date.self, forKey: .lastOpen)) ?? oldDate
        isAnonymous = (try? container.decode(Bool.self, forKey: .isAnonymous)) ?? true
        username = try? container.decode(String.self, forKey: .username)
        streakApp = (try? container.decode(Int.self, forKey: .streakApp)) ?? 0
        streakAppBest = (try? container.decode(Int.self, forKey: .streakAppBest)) ?? 0
        streakPost = (try? container.decode(Int.self, forKey: .streakPost)) ?? 0
        streakPostBest = (try? container.decode(Int.self, forKey: .streakPostBest)) ?? 0
        avatarNumber = (try? container.decode(Int.self, forKey: .avatarNumber)) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uid, forKey: .uid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastPost, forKey: .lastPost)
        try container.encode(lastOpen, forKey: .lastOpen)
        try container.encode(isAnonymous, forKey: .isAnonymous)
        try container.encodeIfPresent(username, forKey: .username)
        try container.encode(streakApp, forKey: .streakApp)
        try container.encode(streakAppBest, forKey: .streakAppBest)
        try container.encode(streakPost, forKey: .streakPost)
        try container.encode(streakPostBest, forKey: .streakPostBest)
        try container.encode(avatarNumber, forKey: .avatarNumber)
    }
}

//// makes sure mock code is only included in debug builds (not production)
//#if DEBUG
//extension User {
//    static var mock: User {
//        User(uid: "123", isAnonymous: false, username: "",
//             streakApp: 1, streakAppBest: 1, streakPost: 0, streakPostBest: 0, avatarNumber: 0)
//    }
//}
//#endif

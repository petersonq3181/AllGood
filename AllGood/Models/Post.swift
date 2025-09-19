//
//  Post.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/18/25.
//

import Foundation
import FirebaseFirestore

enum PostType: String, CaseIterable, Codable {
    case donation
    case volunteering
    case personalKindness = "personalKindness"
    
    var displayName: String {
        return self.rawValue.capitalized
    }
}

struct Post: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let userName: String
    let type: PostType
    let timestamp: Date
    let location: GeoPoint
    let description: String
    
    init(
        userId: String,
        userName: String,
        type: PostType,
        location: GeoPoint,
        description: String
    ) {
        self.userId = userId
        self.userName = userName
        self.type = type
        self.timestamp = Date()
        self.location = location
        self.description = description
    }
}

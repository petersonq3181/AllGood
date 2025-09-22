//
//  Post.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/18/25.
//

import Foundation
import FirebaseFirestore
import CoreLocation

enum PostType: String, CaseIterable, Codable {
    case donation
    case volunteering
    case kindness
    
    var displayName: String {
        return self.rawValue.capitalized
    }
}

struct PostLocation: Identifiable {
    let id: String
    let location: GeoPoint
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
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
        id: String? = nil,
        userId: String,
        userName: String,
        type: PostType,
        location: GeoPoint,
        description: String
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.type = type
        self.timestamp = Date()
        self.location = location
        self.description = description
    }
}

// makes sure mock code is only included in debug builds (not production)
#if DEBUG
extension Post {
    static var mockPosts: [Post] {
        [
            Post(id: "mock1",
                 userId: "123",
                 userName: "anon",
                 type: .donation,
                 location: GeoPoint(latitude: 33.2, longitude: -117.25),
                 description: "A batch of chicken pot pie delivered across the county ..."),
            Post(id: "mock2",
                 userId: "123",
                 userName: "anon",
                 type: .donation,
                 location: GeoPoint(latitude: 33.2, longitude: -117.25),
                 description: "A dollar donated at the grocery checkout at 3 PM on the day, despite the increased price in groceries, and even with the projection for higher inflation.")
        ]
    }
}
#endif

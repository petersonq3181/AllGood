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

enum PostDateFilter: CaseIterable, Identifiable {
    case all
    case pastDay
    case pastWeek
    case pastMonth
    case pastYear
    
    var id: Self { self }
    
    var displayName: String {
        switch self {
        case .all: return "All Dates"
        case .pastDay: return "Past Day"
        case .pastWeek: return "Past Week"
        case .pastMonth: return "Past Month"
        case .pastYear: return "Past Year"
        }
    }
}

enum PostTypeFilter: CaseIterable, Identifiable {
    case all
    case donation
    case volunteering
    case kindness
    
    var id: Self { self }
    
    var displayName: String {
        switch self {
        case .all: return "All Types"
        case .donation: return "Donation"
        case .volunteering: return "Volunteering"
        case .kindness: return "Kindness"
        }
    }
}

struct Post: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let userName: String
    let avatarNumber: Int?
    let type: PostType
    let timestamp: Date
    let location: GeoPoint
    let locationString: String?
    let description: String
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
    }
    
    init(
        id: String? = nil,
        userId: String,
        userName: String,
        avatarNumber: Int,
        type: PostType,
        location: GeoPoint,
        locationString: String,
        description: String
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.avatarNumber = avatarNumber
        self.type = type
        self.timestamp = Date()
        self.location = location
        self.locationString = locationString
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
                 userName: "SuperLongUsernameLol",
                 avatarNumber: 1,
                 type: .donation,
                 location: GeoPoint(latitude: 33.2, longitude: -117.25),
                 locationString: "Capitol Hill, San Francisco, CA, United States",
                 description: "A batch of chicken pot pie delivered across the county ..."),
            Post(id: "mock2",
                 userId: "123",
                 userName: "anon",
                 avatarNumber: 5,
                 type: .donation,
                 location: GeoPoint(latitude: 33.2, longitude: -117.25),
                 locationString: "Capitol Hill, San Francisco, CA, United States",
                 description: "A dollar donated at the grocery checkout at 3 PM on the day, despite the increased price in groceries, and even with the projection for higher inflation.")
        ]
    }
}
#endif

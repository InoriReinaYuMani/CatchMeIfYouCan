import Foundation

struct GeoPoint: Codable, Equatable {
    let latitude: Double
    let longitude: Double
}

struct NearbyCandidate: Equatable {
    let profile: UserProfile
    let location: GeoPoint
    let distanceMeters: Double
}

struct DailyTopMatch: Equatable {
    let profile: UserProfile
    let finalScore: Double
    let wordScore: Double
    let distanceScore: Double
    let distanceMeters: Double
}

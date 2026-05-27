import Foundation

enum SeedData {
    static let currentUser = UserProfile(
        id: "me",
        displayName: "You",
        selfWords: ["coffee", "travel", "movie", "dog", "coding"],
        targetWords: ["travel", "music", "cat", "book", "startup"],
        isDiscoverable: true,
        locationSharingEnabled: true,
        searchRadiusMeters: 800
        isDiscoverable: false // デフォルトは非公開。アプリ内ONで公開。
    )

    static let candidates: [UserProfile] = [
        UserProfile(
            id: "u1",
            displayName: "Alex",
            selfWords: ["music", "travel", "cat", "gym", "book"],
            targetWords: ["coding", "movie", "coffee", "design", "dog"],
            isDiscoverable: true,
            locationSharingEnabled: true,
            searchRadiusMeters: 1_000
        ),
        UserProfile(
            id: "u2",
            displayName: "Taylor",
            selfWords: ["hiking", "tea", "startup", "book", "movie"],
            targetWords: ["travel", "dog", "coffee", "music", "sports"],
            isDiscoverable: false,
            locationSharingEnabled: true,
            searchRadiusMeters: 600
        )
    ]
}

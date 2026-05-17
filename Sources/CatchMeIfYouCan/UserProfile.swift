import Foundation

struct UserProfile: Identifiable, Codable, Equatable {
    let id: String
    var displayName: String
    var selfWords: [String]      // 5件固定
    var targetWords: [String]    // 5件固定

    var isValid: Bool {
        selfWords.count == 5 && targetWords.count == 5
    }
}

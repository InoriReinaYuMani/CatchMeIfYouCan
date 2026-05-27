import Foundation

struct UserProfile: Identifiable, Codable, Equatable {
    let id: String
    var displayName: String
    var selfWords: [String]      // 5件固定
    var targetWords: [String]    // 5件固定
    var isDiscoverable: Bool     // 相手の検索結果に載るかどうか（アプリ内ON/OFF）

    /// 位置情報マッチングを許可するか（OS の許可 + アプリ内設定）
    var locationSharingEnabled: Bool

    /// ユーザーが指定する探索半径（メートル）
    var searchRadiusMeters: Double

    var isValid: Bool {
        selfWords.count == 5 &&
        targetWords.count == 5 &&
        searchRadiusMeters > 0
    }
}

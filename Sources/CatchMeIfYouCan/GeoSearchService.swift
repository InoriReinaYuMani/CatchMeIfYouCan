import Foundation

protocol GeoSearchService {
    /// 現在位置と最大半径から候補ユーザーを取得。
    /// 実装では Geohash / H3 / S2 など空間インデックスを使って絞り込む想定。
    func findNearbyCandidates(
        center: GeoPoint,
        maxRadiusMeters: Double,
        limit: Int
    ) async -> [NearbyCandidate]
}

protocol DistanceCalculator {
    func distanceMeters(from: GeoPoint, to: GeoPoint) -> Double
}

enum HaversineDistanceCalculator: DistanceCalculator {
    case shared

    func distanceMeters(from: GeoPoint, to: GeoPoint) -> Double {
        let earthRadius = 6_371_000.0
        let dLat = (to.latitude - from.latitude) * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(from.latitude * .pi / 180) * cos(to.latitude * .pi / 180)
            * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }
}

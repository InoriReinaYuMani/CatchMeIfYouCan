import Foundation

actor DailyTopMatchService {
    private let geoSearchService: GeoSearchService

    init(geoSearchService: GeoSearchService) {
        self.geoSearchService = geoSearchService
    }

    /// その日の上位マッチ5人を返す。
    /// - Note: 先に位置で絞り込むことで、重いAI関連度計算の対象数を減らす。
    func findDailyTopMatches(
        for currentUser: UserProfile,
        currentLocation: GeoPoint,
        relationScorer: WordRelationScoring? = nil,
        relatednessThreshold: Double = 0.75,
        topK: Int = 5,
        prefilterLimit: Int = 300
    ) async -> [DailyTopMatch] {
        guard currentUser.isDiscoverable,
              currentUser.locationSharingEnabled,
              currentUser.searchRadiusMeters > 0 else {
            return []
        }

        let near = await geoSearchService.findNearbyCandidates(
            center: currentLocation,
            maxRadiusMeters: currentUser.searchRadiusMeters,
            limit: max(prefilterLimit, topK)
        )

        var matches: [DailyTopMatch] = []
        matches.reserveCapacity(near.count)

        for candidate in near {
            guard candidate.profile.id != currentUser.id,
                  candidate.profile.isDiscoverable,
                  candidate.profile.locationSharingEnabled else {
                continue
            }

            let wordScore: Double
            if let relationScorer {
                wordScore = await MatchingEngine.calculateScore(
                    targetWords: currentUser.targetWords,
                    selfWords: candidate.profile.selfWords,
                    relationScorer: relationScorer,
                    relatednessThreshold: relatednessThreshold
                )
            } else {
                wordScore = MatchingEngine.calculateScore(
                    targetWords: currentUser.targetWords,
                    selfWords: candidate.profile.selfWords
                )
            }

            let distanceScore = distanceScore(
                distanceMeters: candidate.distanceMeters,
                userRadiusMeters: currentUser.searchRadiusMeters
            )

            // 将来的な大規模運用を想定して、最終スコアを線形合成。
            // 単語相性 80% + 距離 20%
            let finalScore = wordScore * 0.8 + distanceScore * 0.2

            matches.append(
                DailyTopMatch(
                    profile: candidate.profile,
                    finalScore: finalScore,
                    wordScore: wordScore,
                    distanceScore: distanceScore,
                    distanceMeters: candidate.distanceMeters
                )
            )
        }

        return matches
            .sorted {
                if $0.finalScore == $1.finalScore {
                    if $0.wordScore == $1.wordScore {
                        return $0.profile.displayName < $1.profile.displayName
                    }
                    return $0.wordScore > $1.wordScore
                }
                return $0.finalScore > $1.finalScore
            }
            .prefix(max(1, topK))
            .map { $0 }
    }

    /// 半径内で近いほど高得点（0〜100）
    private func distanceScore(distanceMeters: Double, userRadiusMeters: Double) -> Double {
        guard userRadiusMeters > 0 else { return 0 }
        let clamped = min(max(distanceMeters, 0), userRadiusMeters)
        let normalized = 1.0 - (clamped / userRadiusMeters)
        return normalized * 100.0
    }
}

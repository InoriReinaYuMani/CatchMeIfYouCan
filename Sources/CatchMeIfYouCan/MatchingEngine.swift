import Foundation

/// AI や埋め込みAPIなどで「関連ワードかどうか」を判定するための抽象。
/// - Returns: 0.0...1.0（1.0 に近いほど関連度が高い）
protocol WordRelationScoring {
    func relatedness(between lhs: String, and rhs: String) async -> Double
}

enum MatchingEngine {
    /// 同義・関連語判定を有効にしたランキング（AI連携向け）
    static func rankCandidates(
        for currentUser: UserProfile,
        candidates: [UserProfile],
        relationScorer: WordRelationScoring,
        relatednessThreshold: Double = 0.75
    ) async -> [(profile: UserProfile, score: Double)] {
        var results: [(profile: UserProfile, score: Double)] = []

        for profile in candidates where profile.id != currentUser.id && profile.isDiscoverable {
            let score = await calculateScore(
                targetWords: currentUser.targetWords,
                selfWords: profile.selfWords,
                relationScorer: relationScorer,
                relatednessThreshold: relatednessThreshold
            )
            results.append((profile, score))
        }

        return results.sorted { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.profile.displayName < rhs.profile.displayName
            }
            return lhs.score > rhs.score
        }
    }

    /// 既存ロジック（同期）
    static func rankCandidates(for currentUser: UserProfile, candidates: [UserProfile]) -> [(profile: UserProfile, score: Double)] {
        candidates
            .filter { $0.id != currentUser.id }
            .filter(\.isDiscoverable)
            .map { profile in
                (profile, calculateScore(targetWords: currentUser.targetWords, selfWords: profile.selfWords))
            }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.profile.displayName < rhs.profile.displayName
                }
                return lhs.score > rhs.score
            }
    }

    /// 既存ロジック（完全一致/部分一致）
    static func calculateScore(targetWords: [String], selfWords: [String]) -> Double {
        guard targetWords.count == 5, selfWords.count == 5 else {
            return 0
        }

        var score = 0.0

        for target in targetWords {
            let normalizedTarget = normalize(target)

            for selfWord in selfWords {
                let normalizedSelf = normalize(selfWord)

                if normalizedTarget == normalizedSelf {
                    score += 1.0
                    break
                }

                if normalizedTarget.contains(normalizedSelf) || normalizedSelf.contains(normalizedTarget) {
                    score += 0.6
                    break
                }
            }
        }

        return min((score / 5.0) * 100.0, 100.0)
    }

    /// AI 連携ロジック（関連語判定込み）
    static func calculateScore(
        targetWords: [String],
        selfWords: [String],
        relationScorer: WordRelationScoring,
        relatednessThreshold: Double = 0.75
    ) async -> Double {
        guard targetWords.count == 5, selfWords.count == 5 else {
            return 0
        }

        let threshold = min(max(relatednessThreshold, 0), 1)
        var score = 0.0

        for target in targetWords {
            let normalizedTarget = normalize(target)

            var matched = false
            for selfWord in selfWords {
                let normalizedSelf = normalize(selfWord)

                if normalizedTarget == normalizedSelf {
                    score += 1.0
                    matched = true
                    break
                }

                if normalizedTarget.contains(normalizedSelf) || normalizedSelf.contains(normalizedTarget) {
                    score += 0.6
                    matched = true
                    break
                }

                let relation = await relationScorer.relatedness(between: normalizedTarget, and: normalizedSelf)
                if relation >= threshold {
                    score += 0.7
                    matched = true
                    break
                }
            }

            if matched == false {
                continue
            }
        }

        return min((score / 5.0) * 100.0, 100.0)
    }

    private static func normalize(_ word: String) -> String {
        word
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

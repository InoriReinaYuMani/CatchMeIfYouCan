import Foundation

enum MatchingEngine {
    static func rankCandidates(for currentUser: UserProfile, candidates: [UserProfile]) -> [(profile: UserProfile, score: Double)] {
        candidates
            .filter { $0.id != currentUser.id }
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

    private static func normalize(_ word: String) -> String {
        word
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

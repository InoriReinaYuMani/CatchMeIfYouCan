import Foundation

/// バックグラウンドで定期的に候補検索を行うシンプルなサービス。
/// 実アプリでは BGTaskScheduler / Push / Firestore listener 等で置き換える。
actor BackgroundMatchService {
    private var searchTask: Task<Void, Never>?

    /// 直近の検索結果（スコア順）
    private(set) var latestMatches: [(profile: UserProfile, score: Double)] = []

    func startBackgroundSearch(
        currentUserProvider: @escaping @Sendable () async -> UserProfile,
        candidatesProvider: @escaping @Sendable () async -> [UserProfile],
        relationScorer: WordRelationScoring? = nil,
        relatednessThreshold: Double = 0.75,
        intervalSeconds: UInt64 = 30
    ) {
        stopBackgroundSearch()

        searchTask = Task {
            while !Task.isCancelled {
                let currentUser = await currentUserProvider()
                let candidates = await candidatesProvider()

                if let relationScorer {
                    latestMatches = await MatchingEngine.rankCandidates(
                        for: currentUser,
                        candidates: candidates,
                        relationScorer: relationScorer,
                        relatednessThreshold: relatednessThreshold
                    )
                } else {
                    latestMatches = MatchingEngine.rankCandidates(for: currentUser, candidates: candidates)
                }

                try? await Task.sleep(nanoseconds: intervalSeconds * 1_000_000_000)
            }
        }
    }

    func stopBackgroundSearch() {
        searchTask?.cancel()
        searchTask = nil
    }

    /// 自分を相手検索に載せる ON/OFF を更新。
    func setDiscoverable(_ isOn: Bool, for profile: inout UserProfile) {
        profile.isDiscoverable = isOn
    }
}

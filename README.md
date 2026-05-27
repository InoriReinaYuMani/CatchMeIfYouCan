# CatchMeIfYouCan (iOS Matching App)

このリポジトリは、以下の要件を満たす iOS アプリの設計・実装のたたき台です。

- ユーザー自身を表すワードを **5つ** 設定
- 探したい相手の特徴ワードを **5つ** 設定
- 最終的に「その日、最も相性の高い相手」上位5人を表示

## 1. 追加された重要要件（今回）

- 候補者は、ユーザーが **位置情報ON** にした後のみ探索対象
- 候補者は、ユーザー指定の半径 `X` メートル以内の人に限定
- 将来的な高負荷を考慮し、**先に位置で絞り込み**してから相性計算する

## 2. ユーザー探索（スケール前提）

### 2.1 2段階探索
1. **粗い探索（空間インデックス）**  
   Geohash / H3 / S2 などで「半径X近傍セル」を引く。
2. **厳密探索（距離計算）**  
   Haversine で実距離(m)を計算して半径内のみ残す。

この2段階により、全ユーザー総当たりを避け、AI関連度計算の対象数を大幅削減できます。

### 2.2 実装インターフェース
- `GeoSearchService.findNearbyCandidates(center:maxRadiusMeters:limit:)`
- `NearbyCandidate` に `distanceMeters` を持たせて後段のランキングに利用

## 3. ランク付け（Top 5）

`DailyTopMatchService.findDailyTopMatches` で、以下を行います。

1. 位置情報/公開設定を満たすかチェック
2. 位置で候補を事前絞り込み（`prefilterLimit`）
3. 単語スコア計算
   - 完全一致 +1.0
   - 部分一致 +0.6
   - AI関連語一致 +0.7（任意）
4. 距離スコア計算（近いほど高得点, 0〜100）
5. 最終スコア計算  
   `finalScore = wordScore * 0.8 + distanceScore * 0.2`
6. 上位 `topK`（デフォルト5人）を返却

## 4. スケーラブル設計ポイント

- **最初に位置で絞る**: 重い関連語判定の前に候補数を削減
- **抽象化**: `WordRelationScoring` / `GeoSearchService` を分離し、実装差し替え容易
- **定期計算**: `BackgroundMatchService` でバックグラウンド更新
- **将来拡張**:
  - Redis などにセル単位キャッシュ
  - 前日夜の事前バッチ（候補プール更新）
  - オンラインでは再ランクのみ

## 5. データモデル

- `UserProfile`
  - `selfWords` (5)
  - `targetWords` (5)
  - `isDiscoverable`
  - `locationSharingEnabled`
  - `searchRadiusMeters`

- `DailyTopMatch`
  - `finalScore`
  - `wordScore`
  - `distanceScore`
  - `distanceMeters`

## 6. 補足

現状コードは「アーキテクチャとコアロジック」の雛形です。  
iOS本番では以下を接続します。

- CoreLocation（位置許可）
- BGTaskScheduler（定期更新）
- Firestore + 空間インデックス（Geo query）

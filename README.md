# CatchMeIfYouCan (iOS Matching App)

このリポジトリは、以下の要件を満たす iOS アプリの設計・実装のたたき台です。

- ユーザー自身を表すワードを **5つ** 設定
- 探したい相手の特徴ワードを **5つ** 設定
- マッチ度の高い順で候補ユーザーを表示

## 1. 機能要件

### ユーザー設定
- 自分ワード (`selfWords`): 5件固定
- 希望ワード (`targetWords`): 5件固定
- 各ワードは 1〜20 文字程度を想定

### マッチング
- 自分の `targetWords` と相手の `selfWords` の一致度を算出
- スコア順でソートして一覧表示

## 2. マッチ度ロジック

基本スコア:

- 完全一致: +1.0
- 部分一致（含む）: +0.6
- 類義語一致（任意拡張）: +0.7

最終スコア:

- `score / 5.0 * 100` (% 表示)

## 3. 推奨技術スタック

- UI: SwiftUI
- データ保存: Firebase Firestore
- 認証: Sign in with Apple / Firebase Auth
- 類義語辞書: ローカル JSON（初期）

## 4. 画面構成

1. Onboarding / Login
2. ワード設定画面（自分5つ・希望5つ）
3. 候補一覧（スコア順）
4. 候補詳細

## 5. 次の実装ステップ

1. Xcode で `App` プロジェクト作成
2. `UserProfile` モデル実装
3. `MatchingEngine` 実装
4. `ProfileEditView` と `MatchesView` 作成
5. Firestore 連携
6. スコアチューニング

---

## サンプルコード

`Sources/` 配下に、コアロジックのサンプルを追加しています。


## 6. 公開設定とバックグラウンド検索

- 候補検索はバックグラウンドで定期実行（`BackgroundMatchService`）
- 自分を相手の検索結果へ表示するには、アプリ内の公開スイッチを **ON** にする
- 公開OFFのユーザーは `isDiscoverable = false` となり、相手の候補一覧に出ない


## 7. 部分一致をAIで判定する拡張

`MatchingEngine` には `WordRelationScoring` プロトコルを追加しており、
OpenAI embeddings 等を使って「travel」と「trip」のような関連語を判定できます。

- 関連度スコア: `0.0 ... 1.0`
- しきい値: `relatednessThreshold`（デフォルト `0.75`）
- しきい値以上なら関連語一致として `+0.7`

この構成により、将来的に API 実装だけ差し替えて精度改善が可能です。

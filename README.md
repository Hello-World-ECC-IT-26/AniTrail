# AniTrail（アニトレイル）

AniTrail のクライアントアプリ（Flutter）。

![AniTrail メインビジュアル](image/main.png)

## 概要

AniTrail は、アニメの舞台となった場所を巡りながらスタンプを集める、聖地巡礼支援アプリです。スポットの検索や地図表示、しおりによる巡礼ルートの管理、現在地からのナビゲーション、スタンプ・クーポンの獲得などを一つのアプリで楽しめます。

本リポジトリは Flutter 製のフロントエンドです。

![AniTrail サブビジュアル](image/sub.png)

## 主要技術

- Flutter 3.38.5 / Dart 3.10.4
- Provider
- Supabase（Authentication / Database）
- Google Maps for Flutter
- Geolocator
- HTTP API
- SharedPreferences
- CachedNetworkImage

## 必要環境

- Flutter SDK 3.38.5 以上
- Dart SDK 3.10.4 以上
- Android Studio または Xcode
- Supabase プロジェクト
- AniTrail バックエンド API
- Google Maps Platform API キー

## セットアップ（開発）

1. 依存関係をインストールします。

   ```bash
   flutter pub get
   ```

2. プロジェクトルートに `.env` を作成し、接続先を設定します。

   ```dotenv
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   API_BASE_URL=your_backend_api_url
   ```

3. Google Maps API キーを設定します。

   Android は `android/local.properties` に追記します。

   ```properties
   MAPS_API_KEY=your_google_maps_api_key
   ```

   iOS は `ios/Flutter/Local.xcconfig` を作成します。

   ```xcconfig
   MAPS_API_KEY=your_google_maps_api_key
   ```

   `.env`、`android/local.properties`、`ios/Flutter/Local.xcconfig` は Git の管理対象外です。API キーには利用するアプリと API の制限を設定してください。

4. エミュレータまたは実機でアプリを起動します。

   ```bash
   flutter run
   ```

位置情報、カメラ、写真ライブラリを利用する機能では、端末上で権限の許可が必要です。

## 主要コマンド

- `flutter run` — 接続中の実機またはエミュレータで起動
- `flutter run -d <device-id>` — 指定したデバイスで起動
- `flutter devices` — 利用可能なデバイスを確認
- `flutter analyze` — 静的解析を実行
- `flutter test` — テストを実行
- `flutter build apk` — Android APK をビルド
- `flutter build ios` — iOS アプリをビルド

## 主要な画面と機能

- 認証 — ログイン、新規登録、メール認証、パスワード再設定
- ホーム — ユーザー情報、イベント、スタンプカードを表示
- スポット検索 — アニメの聖地を検索し、詳細・写真・コメントを確認
- マップ — 現在地や周辺スポット、しおりに登録したスポットを地図上に表示
- しおり — 巡りたいスポットをまとめ、順番を編集して巡礼プランを作成
- ナビゲーション — 現在地から目的地までの徒歩ルートと進行方向を案内
- スタンプ — スポット到着時にスタンプを獲得し、コレクションを確認
- クーポン — 獲得したクーポンの一覧、詳細、利用条件を確認
- マイページ — プロフィールの確認・編集、アカウント設定

## ディレクトリ構成

```text
lib/
├── core/       # 共通定数、スタイル、通信、共通ウィジェット
├── features/   # 機能単位の画面、モデル、サービス、ウィジェット
└── main.dart   # アプリのエントリーポイント

assets/images/  # アプリ内で使用する画像
image/          # README 用画像
test/           # ウィジェットテスト、ロジックテスト
```

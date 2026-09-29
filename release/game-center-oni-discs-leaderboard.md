# おに CPU 勝利時の黒石枚数ランキング

App Store Connect の `animis.co.jp.OthelloApp` に、アプリのコードと同じ ID で Game Center ランキングを登録済み。

2026-09-30 に下記の設定と 7 言語のローカリゼーションを保存し、詳細画面で再表示して確認した。現在の状態は「提出準備中」。審査用への追加・提出、実機での Game Center 送信とランキング表示は未実施。

| 項目 | 設定値 |
| --- | --- |
| Reference Name | Oni CPU Victory Black Discs |
| Leaderboard ID | `othello.cpu.oni.discs` |
| Type | Classic |
| Score Format | Integer |
| Score Range | 1 から 64 |
| Score Submission Type | Best Score |
| Sort Order | High to Low |
| Default | このランキングを既定で表示したい場合に設定 |

Leaderboard ID は作成後に変更できない。既存の ID と重複しないことを登録前に確認する。

## 表示文言

| 言語 | Display Name | Leaderboard Description | 単位 |
| --- | --- | --- | --- |
| 日本語 | おに勝利・黒石枚数 | おに CPU に勝利した対局で、最後に残った黒石の最多枚数 | 枚 |
| English | Black Discs vs Oni CPU | Most black discs at the end of a win against the Oni CPU | discs |
| Español | Fichas negras contra CPU Oni | Máximo de fichas negras al ganar contra la CPU Oni | fichas |
| Français | Pions noirs contre CPU Oni | Nombre maximal de pions noirs lors d'une victoire contre CPU Oni | pions |
| Português (Brasil) | Peças pretas contra CPU Oni | Maior número de peças pretas ao vencer a CPU Oni | peças |
| 简体中文 | 鬼级电脑对战黑棋数 | 战胜鬼级电脑时，终局黑棋的最多枚数 | 枚 |
| 한국어 | 오니 CPU전 흑돌 수 | 오니 CPU에게 승리했을 때 최종 흑돌의 최고 개수 | 개 |

Leaderboard Localization で上記の言語を追加し、保存後に再度開いて文言と設定値を確認する。画像は任意。

## アプリ側の集計

- 人間（黒）が「おに」CPU（白）に勝った対局の終了時だけ、最終盤面の黒石を数える。引き分け、敗北、他の難易度、同じ端末での 2 人対戦、途中終了は対象外。
- Game Center の認証済みプレイヤーごとに端末内で自己ベストを保存し、GameKit には最高値だけを送る。失敗時は値を残し、次の認証成功、アプリ復帰、または対局終了時に再送する。
- 未認証中の結果はゲスト用の記録に保存し、後から認証したアカウントへ自動移行しない。機能追加前の対局結果は復元できない。
- ランキングを見るには Game Center へのサインインが必要。アプリ内では標準の Game Center 画面を開く。

ランキングを保存しただけでは公開されない。新しい Game Center コンポーネントは App Review に提出する。初めて Game Center コンポーネントを追加する場合は、アプリのバージョンと同じ提出に含める。

参考: [Apple のランキング設定手順](https://developer.apple.com/help/app-store-connect/configure-game-center/manage-leaderboards/)、[ランキング項目の定義](https://developer.apple.com/help/app-store-connect/reference/game-center/leaderboards)、[Game Center コンポーネントの審査提出](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-game-center-components)

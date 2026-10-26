# App Store 提出文言 — 3.2.0 (14)

- アプリ: 広告なし！簡単オセロ！
- Bundle ID: `animis.co.jp.OthelloApp`
- App Store ID: `6670340876`
- 対象: iOS / iPadOS
- リリース方法: 審査承認後に自動リリース
- この資料は提出用の文言原稿です。提出状態や公開状態の証明ではありません。

## このバージョンの最新情報

### ja

CPU対戦で、先攻の黒と後攻の白を選べるようになったにゃ！
難易度を選んでから、好きな色で対局を始めてほしいにゃ。

iPhone Duoでも遊びやすいように、開いたとき・閉じたときの画面を調整したにゃ。盤面や石の数、ボタンを見やすくして、2人対戦では向かい合って石の数を確認できるようにしたにゃ。

難易度のマークも星1〜3個と警告マークに変更したにゃ。「鬼」の解放条件もわかりやすくなったにゃん。
これからも、ひとりでもふたりでもオセロを楽しんでほしいにゃ！

### en-US

You can now choose Black to go first or White to go second against the CPU, meow! Pick a difficulty, then choose your color to start a match.

We adjusted the layouts for iPhone Duo, both open and folded. The board, disc counts, and buttons are easier to see, and players sitting opposite each other can read their own disc counts in local two-player matches.

Difficulty icons now use one to three stars and a warning symbol. The requirement to unlock Oni is clearer, too. Keep enjoying Reversi, solo or with a friend, meow!

### es-ES

¡Ahora puedes elegir negras para jugar primero o blancas para jugar después contra la CPU, miau! Elige la dificultad y luego tu color para empezar la partida.

Hemos ajustado las pantallas del iPhone Duo, tanto abierto como plegado. El tablero, el recuento de fichas y los botones se ven mejor, y cada jugador puede leer su recuento al sentarse frente al otro en las partidas locales de dos jugadores.

Los iconos de dificultad ahora usan de una a tres estrellas y un símbolo de advertencia. También se explica mejor cómo desbloquear Oni. ¡Sigue disfrutando del Reversi, a solas o en compañía, miau!

### es-MX

¡Ya puedes elegir negras para jugar primero o blancas para jugar después contra la CPU, miau! Selecciona la dificultad y luego tu color para comenzar la partida.

Ajustamos las pantallas del iPhone Duo, tanto abierto como plegado. El tablero, el conteo de fichas y los botones se ven mejor, y cada jugador puede leer su conteo al sentarse frente al otro en las partidas locales de dos jugadores.

Los íconos de dificultad ahora usan de una a tres estrellas y un símbolo de advertencia. También explicamos mejor cómo desbloquear Oni. ¡Sigue disfrutando del Reversi, por tu cuenta o con alguien más, miau!

### fr-FR

Vous pouvez maintenant choisir les noirs pour commencer ou les blancs pour jouer en second contre l’ordinateur, miaou ! Choisissez la difficulté, puis votre couleur pour lancer la partie.

Nous avons adapté l’affichage de l’iPhone Duo, ouvert comme plié. Le plateau, le nombre de pions et les boutons sont plus lisibles. En partie locale à deux, chaque joueur peut lire son nombre de pions en étant assis face à son adversaire.

Les niveaux de difficulté utilisent désormais une à trois étoiles et un symbole d’avertissement. La condition pour débloquer Oni est aussi plus claire. Amusez-vous au Reversi, seul ou à deux, miaou !

### pt-BR

Agora você pode escolher as pretas para jogar primeiro ou as brancas para jogar depois contra a CPU, miau! Escolha a dificuldade e depois sua cor para começar a partida.

Ajustamos as telas do iPhone Duo, aberto ou dobrado. O tabuleiro, a contagem de peças e os botões ficaram mais fáceis de ver. Nas partidas locais em dupla, cada pessoa pode ler sua contagem de peças sentada de frente para a outra.

Os ícones de dificuldade agora usam de uma a três estrelas e um símbolo de alerta. A condição para desbloquear Oni também ficou mais clara. Continue curtindo Reversi, a sós ou em dupla, miau!

### ko

이제 CPU 대전에서 먼저 두는 흑돌과 나중에 두는 백돌을 고를 수 있다냥! 난이도를 고른 뒤 원하는 색으로 대국을 시작해 보라냥.

iPhone Duo를 펼쳤을 때와 접었을 때 모두 편하게 즐길 수 있도록 화면을 조정했다냥. 보드와 돌 개수, 버튼을 보기 쉽게 다듬었고, 로컬 2인 대전에서는 서로 마주 앉아 각자의 돌 개수를 읽을 수 있다냥.

난이도 아이콘은 별 1~3개와 경고 표시로 바꿨다냥. 오니의 해제 조건도 더 알기 쉬워졌다냥. 앞으로도 혼자 또는 둘이 리버시를 즐겨 달라냥!

### zh-Hans

现在与电脑对战时，可以选择执黑先手或执白后手了喵！选好难度，再选喜欢的颜色开始对局吧。

我们调整了 iPhone Duo 展开和折叠时的界面，让棋盘、棋子数量和按钮更清晰。本地双人对战时，面对面坐着的两位玩家也能分别看清自己的棋子数量喵。

难度图标改成了1～3颗星和警告标志，鬼级的解锁条件也说明得更清楚了。继续享受一个人或两个人的黑白棋时光吧，喵！

## App Review Notes (English)

Version 3.2.0 adds player color selection for CPU matches. Select a CPU difficulty, then choose Black (first) or White (second) in the dialog. When White is selected, the CPU makes the opening move.

This update improves layouts on iPhone Duo in open and closed configurations, hides the status bar throughout the app, and keeps controls clear of the camera area. In local two-player landscape matches, the white player panel is rotated for the opponent. Difficulty icons and the locked Oni explanation have also been improved. Oni unlocks after defeating the Strong CPU.

The game works offline and has no ads or in-app purchases. No app account or review credentials are required. The trophy button opens Game Center rankings and achievements; these require Game Center sign-in and internet access.

## 文言と実装の対応

- CPU難易度を選ぶと、先攻の黒・後攻の白を選択するダイアログが開きます。白を選ぶとCPUが初手を打ちます。
- iPhone Duoの開閉時の配置、カメラ側の安全領域、アプリ内のステータスバー非表示を調整しています。
- ローカル2人対戦の横画面では白側のパネルを180度回転し、向かい合うプレイヤーに向けて表示します。
- やさしい・ふつう・つよいのアイコンは同じ大きさの星1・2・3個、鬼は警告マークです。未解放の鬼を選ぶと解放条件を表示します。
- 新しい更新文は各言語で猫語の雰囲気を付けています。審査メモは英語の通常体です。
- 既存のアプリ名、概要、キーワード、価格、プライバシー回答を変更するための資料ではありません。

## 文字数確認

Unicodeコードポイント数で計算し、改行も1文字として数えています。各更新文と審査メモの上限は4,000文字です。

| 言語 | 更新文文字数 | 上限 |
| --- | ---: | ---: |
| ja | 231 | 4,000 |
| en-US | 525 | 4,000 |
| es-ES | 599 | 4,000 |
| es-MX | 603 | 4,000 |
| fr-FR | 628 | 4,000 |
| pt-BR | 594 | 4,000 |
| ko | 274 | 4,000 |
| zh-Hans | 177 | 4,000 |

審査メモ: 800 / 4,000文字

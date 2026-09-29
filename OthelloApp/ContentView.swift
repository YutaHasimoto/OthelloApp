//
//  ContentView.swift
//  OthelloApp
//
//  Created by 橋本雄太 on 2024/08/31.
//

import AVFoundation
import GameKit
import StoreKit
import SwiftUI

#if canImport(AudioToolbox)
import AudioToolbox
#endif

#if canImport(UIKit)
import UIKit
#endif

enum Disc: Int, CaseIterable {
    case empty
    case black
    case white

    var opponent: Disc {
        switch self {
        case .black:
            return .white
        case .white:
            return .black
        case .empty:
            return .empty
        }
    }

    var name: String {
        switch self {
        case .black:
            return L10n.string("disc.black")
        case .white:
            return L10n.string("disc.white")
        case .empty:
            return L10n.string("disc.empty")
        }
    }
}

struct BoardPosition: Hashable, Identifiable {
    let row: Int
    let column: Int

    var id: Int {
        row * OthelloGame.boardSize + column
    }

    var displayName: String {
        L10n.format("board.position", Int64(row + 1), Int64(column + 1))
    }
}

struct OthelloGame {
    static let boardSize = 8
    static let cellCount = boardSize * boardSize

    private(set) var board: [Disc]
    private(set) var currentPlayer: Disc
    private(set) var lastMove: BoardPosition?
    private(set) var lastMessage: String
    private(set) var moveCount: Int
    private(set) var isFinished: Bool
    private(set) var winner: Disc?
    private var consecutivePasses: Int

    init() {
        var initialBoard = Array(repeating: Disc.empty, count: Self.cellCount)
        initialBoard[Self.index(row: 3, column: 3)] = .white
        initialBoard[Self.index(row: 3, column: 4)] = .black
        initialBoard[Self.index(row: 4, column: 3)] = .black
        initialBoard[Self.index(row: 4, column: 4)] = .white

        board = initialBoard
        currentPlayer = .black
        lastMove = nil
        lastMessage = L10n.string("game.start_black")
        moveCount = 0
        isFinished = false
        winner = nil
        consecutivePasses = 0
    }

    init(board: [Disc], currentPlayer: Disc, consecutivePasses: Int = 0) {
        precondition(board.count == Self.cellCount)
        self.board = board
        self.currentPlayer = currentPlayer
        self.lastMove = nil
        self.lastMessage = L10n.format("game.turn", currentPlayer.name)
        self.moveCount = board.filter { $0 != .empty }.count - 4
        self.isFinished = false
        self.winner = nil
        self.consecutivePasses = consecutivePasses
    }

    static func index(row: Int, column: Int) -> Int {
        row * boardSize + column
    }

    func disc(at position: BoardPosition) -> Disc {
        board[Self.index(row: position.row, column: position.column)]
    }

    func count(for disc: Disc) -> Int {
        board.filter { $0 == disc }.count
    }

    func legalMoves() -> [BoardPosition] {
        legalMoves(for: currentPlayer)
    }

    func legalMoves(for player: Disc) -> [BoardPosition] {
        guard player != .empty else {
            return []
        }

        var moves: [BoardPosition] = []
        for row in 0..<Self.boardSize {
            for column in 0..<Self.boardSize {
                let position = BoardPosition(row: row, column: column)
                if !flippedPositions(for: player, at: position).isEmpty {
                    moves.append(position)
                }
            }
        }
        return moves
    }

    func flippedPositions(for player: Disc, at position: BoardPosition) -> [BoardPosition] {
        guard player != .empty, isInside(row: position.row, column: position.column), disc(at: position) == .empty else {
            return []
        }

        let directions = [-1, 0, 1]
        var result: [BoardPosition] = []

        for rowDirection in directions {
            for columnDirection in directions where !(rowDirection == 0 && columnDirection == 0) {
                let line = capturedLine(
                    for: player,
                    from: position,
                    rowDirection: rowDirection,
                    columnDirection: columnDirection
                )
                result.append(contentsOf: line)
            }
        }

        return result
    }

    mutating func applyMove(at position: BoardPosition) -> Bool {
        guard !isFinished else {
            return false
        }

        let flips = flippedPositions(for: currentPlayer, at: position)
        guard !flips.isEmpty else {
            lastMessage = L10n.string("game.invalid_move")
            return false
        }

        let player = currentPlayer
        board[Self.index(row: position.row, column: position.column)] = player
        for flip in flips {
            board[Self.index(row: flip.row, column: flip.column)] = player
        }

        currentPlayer = player.opponent
        lastMove = position
        lastMessage = L10n.format("game.move", player.name, position.displayName)
        moveCount += 1
        consecutivePasses = 0

        finishIfNeeded()
        return true
    }

    mutating func passTurnIfNeeded() -> Bool {
        guard !isFinished, legalMoves(for: currentPlayer).isEmpty else {
            return false
        }

        let skippedPlayer = currentPlayer
        currentPlayer = skippedPlayer.opponent
        consecutivePasses += 1
        lastMessage = L10n.format("game.pass", skippedPlayer.name)

        finishIfNeeded()
        return true
    }

    mutating func note(_ message: String) {
        lastMessage = message
    }

    private func capturedLine(
        for player: Disc,
        from position: BoardPosition,
        rowDirection: Int,
        columnDirection: Int
    ) -> [BoardPosition] {
        var row = position.row + rowDirection
        var column = position.column + columnDirection
        var captured: [BoardPosition] = []

        while isInside(row: row, column: column) {
            let nextPosition = BoardPosition(row: row, column: column)
            let nextDisc = disc(at: nextPosition)

            if nextDisc == player.opponent {
                captured.append(nextPosition)
            } else if nextDisc == player {
                return captured.isEmpty ? [] : captured
            } else {
                return []
            }

            row += rowDirection
            column += columnDirection
        }

        return []
    }

    private func isInside(row: Int, column: Int) -> Bool {
        (0..<Self.boardSize).contains(row) && (0..<Self.boardSize).contains(column)
    }

    private mutating func finishIfNeeded() {
        if board.allSatisfy({ $0 != .empty }) ||
            consecutivePasses >= 2 ||
            (legalMoves(for: .black).isEmpty && legalMoves(for: .white).isEmpty) {
            finishGame()
        }
    }

    private mutating func finishGame() {
        isFinished = true
        let blackCount = count(for: .black)
        let whiteCount = count(for: .white)

        if blackCount == whiteCount {
            winner = nil
            lastMessage = L10n.string("game.draw")
        } else {
            winner = blackCount > whiteCount ? .black : .white
            lastMessage = L10n.format("game.winner", winner?.name ?? "")
        }
    }
}

enum PlayMode: String, CaseIterable, Identifiable {
    case twoPlayers
    case humanVsCPU

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .twoPlayers:
            return L10n.string("mode.two_players")
        case .humanVsCPU:
            return L10n.string("mode.cpu")
        }
    }
}

enum CPUDifficulty: String, CaseIterable, Identifiable {
    case easy
    case normal
    case strong
    case oni

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .easy:
            return L10n.string("difficulty.easy")
        case .normal:
            return L10n.string("difficulty.normal")
        case .strong:
            return L10n.string("difficulty.strong")
        case .oni:
            return L10n.string("difficulty.oni")
        }
    }

    var requiresUnlock: Bool {
        self == .oni
    }
}

/// Local progress is kept per Game Center player so one person's achievements
/// are never reported to another signed-in account.
struct AchievementProgress: Codable, Equatable {
    var totalCPUWins = 0
    var currentCPUWinStreak = 0
    var bestCPUWinStreak = 0
    var completedTwoPlayerGames = 0
    var clearedDifficulties: Set<String> = []
    // Optional so progress saved before this leaderboard existed still decodes.
    var bestOniVictoryBlackDiscs: Int? = nil

    mutating func record(mode: PlayMode, difficulty: CPUDifficulty, winner: Disc?, finalBlackDiscs: Int? = nil) {
        switch mode {
        case .humanVsCPU:
            if winner == .black {
                if totalCPUWins < Int.max { totalCPUWins += 1 }
                if currentCPUWinStreak < Int.max { currentCPUWinStreak += 1 }
                bestCPUWinStreak = max(bestCPUWinStreak, currentCPUWinStreak)
                clearedDifficulties.insert(difficulty.rawValue)
                if difficulty == .oni, let finalBlackDiscs, (1...64).contains(finalBlackDiscs) {
                    bestOniVictoryBlackDiscs = max(bestOniVictoryBlackDiscs ?? 0, finalBlackDiscs)
                }
            } else {
                currentCPUWinStreak = 0
            }
        case .twoPlayers:
            if completedTwoPlayerGames < Int.max { completedTwoPlayerGames += 1 }
        }
    }

    var achievedIdentifiers: Set<String> {
        var identifiers = Set(clearedDifficulties.map { "othello.cpu.\($0)" })
        for threshold in [3, 5, 10, 15, 20, 25, 30] where bestCPUWinStreak >= threshold {
            identifiers.insert("othello.streak.\(threshold)")
        }
        for threshold in [1, 3, 5, 10, 30, 100, 1000, 10000] where totalCPUWins >= threshold {
            identifiers.insert("othello.wins.\(threshold)")
        }
        if completedTwoPlayerGames >= 101 {
            identifiers.insert("othello.two_player.101")
        }
        return identifiers
    }
}

@MainActor
final class AchievementTracker: ObservableObject {
    static let shared = AchievementTracker()

    private static let progressKey = "achievementProgressByPlayer.v1"
    private static let reportedKey = "achievementReportedByPlayer.v1"
    private static let reportedOniDiscsKey = "leaderboardReportedOniDiscsByPlayer.v1"
    private static let guestPlayerID = "guest"
    static let oniDiscsLeaderboardID = "othello.cpu.oni.discs"

    private let defaults: UserDefaults
    private var progressByPlayer: [String: AchievementProgress]
    private var reportedByPlayer: [String: Set<String>]
    private var reportedOniDiscsByPlayer: [String: Int]
    private var hasStartedAuthentication = false
    private var isReporting = false
    private var shouldReportAgain = false
    private var isReportingOniDiscs = false
    private var shouldReportOniDiscsAgain = false
    @Published private(set) var isGameCenterAuthenticated = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.progressKey),
           let decoded = try? JSONDecoder().decode([String: AchievementProgress].self, from: data) {
            progressByPlayer = decoded
        } else {
            progressByPlayer = [:]
        }
        if let data = defaults.data(forKey: Self.reportedKey),
           let decoded = try? JSONDecoder().decode([String: Set<String>].self, from: data) {
            reportedByPlayer = decoded
        } else {
            reportedByPlayer = [:]
        }
        if let data = defaults.data(forKey: Self.reportedOniDiscsKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            reportedOniDiscsByPlayer = decoded
        } else {
            reportedOniDiscsByPlayer = [:]
        }
        isGameCenterAuthenticated = authenticatedPlayerID != nil
    }

    func startAuthentication() {
        guard !hasStartedAuthentication else { return }
        hasStartedAuthentication = true

        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, _ in
            Task { @MainActor in
                guard let self else { return }
                self.isGameCenterAuthenticated = self.authenticatedPlayerID != nil
                if let viewController {
                    let root = UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }
                        .first(where: { $0.activationState == .foregroundActive })?
                        .windows.first(where: \.isKeyWindow)?.rootViewController
                    root?.present(viewController, animated: true)
                } else if GKLocalPlayer.local.isAuthenticated {
                    self.reportAchievementsIfPossible()
                    self.reportOniDiscsIfPossible()
                }
            }
        }
    }

    func retryPendingReports() {
        isGameCenterAuthenticated = authenticatedPlayerID != nil
        reportAchievementsIfPossible()
        reportOniDiscsIfPossible()
    }

    func recordFinishedGame(mode: PlayMode, difficulty: CPUDifficulty, winner: Disc?, finalBlackDiscs: Int) {
        let playerID = authenticatedPlayerID ?? Self.guestPlayerID
        var progress = progressByPlayer[playerID] ?? AchievementProgress()
        progress.record(mode: mode, difficulty: difficulty, winner: winner, finalBlackDiscs: finalBlackDiscs)
        progressByPlayer[playerID] = progress
        persist()
        reportAchievementsIfPossible()
        reportOniDiscsIfPossible()
    }

    private var authenticatedPlayerID: String? {
        guard GKLocalPlayer.local.isAuthenticated else { return nil }
        let playerID = GKLocalPlayer.local.gamePlayerID
        return playerID.isEmpty ? nil : playerID
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(progressByPlayer) else { return }
        defaults.set(data, forKey: Self.progressKey)
        if let reportedData = try? JSONEncoder().encode(reportedByPlayer) {
            defaults.set(reportedData, forKey: Self.reportedKey)
        }
        if let reportedData = try? JSONEncoder().encode(reportedOniDiscsByPlayer) {
            defaults.set(reportedData, forKey: Self.reportedOniDiscsKey)
        }
    }

    private func reportAchievementsIfPossible() {
        guard let playerID = authenticatedPlayerID else { return }
        if isReporting {
            shouldReportAgain = true
            return
        }
        let identifiers = (progressByPlayer[playerID]?.achievedIdentifiers ?? [])
            .subtracting(reportedByPlayer[playerID] ?? [])
        guard !identifiers.isEmpty else { return }

        isReporting = true
        let achievements = identifiers.sorted().map { identifier -> GKAchievement in
            let achievement = GKAchievement(identifier: identifier)
            achievement.percentComplete = 100
            achievement.showsCompletionBanner = true
            return achievement
        }
        GKAchievement.report(achievements) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if error == nil {
                    self.reportedByPlayer[playerID, default: []].formUnion(identifiers)
                    self.persist()
                }
                self.isReporting = false
                if self.shouldReportAgain {
                    self.shouldReportAgain = false
                    self.reportAchievementsIfPossible()
                }
            }
        }
    }

    private func reportOniDiscsIfPossible() {
        guard let playerID = authenticatedPlayerID,
              let best = progressByPlayer[playerID]?.bestOniVictoryBlackDiscs,
              (1...64).contains(best),
              best > (reportedOniDiscsByPlayer[playerID] ?? 0) else { return }
        if isReportingOniDiscs {
            shouldReportOniDiscsAgain = true
            return
        }

        isReportingOniDiscs = true
        GKLeaderboard.submitScore(
            best,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [Self.oniDiscsLeaderboardID]
        ) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if error == nil {
                    self.reportedOniDiscsByPlayer[playerID] = max(self.reportedOniDiscsByPlayer[playerID] ?? 0, best)
                    self.persist()
                }
                self.isReportingOniDiscs = false
                if self.shouldReportOniDiscsAgain {
                    self.shouldReportOniDiscsAgain = false
                    self.reportOniDiscsIfPossible()
                }
            }
        }
    }
}

enum GameFeedbackEvent {
    case menuSelect
    case validMove(flippedCount: Int)
    case invalidMove
    case pass
    case undo
    case reset
    case gameFinished(winner: Disc?)
    case humanVictory
}

struct GameFeedbackSignal: Identifiable {
    let id = UUID()
    let event: GameFeedbackEvent
}

@MainActor
final class GameFeedbackController: ObservableObject {
    private var backgroundPlayer: AVAudioPlayer?
    private var isAudioSessionConfigured = false

    func startBackgroundMusic() {
        configureAudioSessionIfNeeded()

        if backgroundPlayer == nil {
            backgroundPlayer = makeBackgroundPlayer()
        }

        guard let backgroundPlayer, !backgroundPlayer.isPlaying else {
            return
        }

        backgroundPlayer.currentTime = 0
        backgroundPlayer.numberOfLoops = -1
        backgroundPlayer.volume = 0.16
        backgroundPlayer.play()
    }

    func stopBackgroundMusic() {
        backgroundPlayer?.stop()
        backgroundPlayer?.currentTime = 0
    }

    func play(_ event: GameFeedbackEvent) {
        configureAudioSessionIfNeeded()
        playSound(for: event)
        playHaptic(for: event)
    }

    private func makeBackgroundPlayer() -> AVAudioPlayer? {
        #if canImport(UIKit)
        guard let dataAsset = NSDataAsset(name: "OthelloBGM"),
              let player = try? AVAudioPlayer(data: dataAsset.data) else {
            return nil
        }

        player.prepareToPlay()
        return player
        #else
        return nil
        #endif
    }

    private func configureAudioSessionIfNeeded() {
        guard !isAudioSessionConfigured else {
            return
        }

        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)
        #endif

        isAudioSessionConfigured = true
    }

    private func playSound(for event: GameFeedbackEvent) {
        #if canImport(AudioToolbox)
        let soundID: SystemSoundID

        switch event {
        case .menuSelect:
            soundID = 1104
        case .validMove(let flippedCount):
            soundID = flippedCount >= 4 ? 1105 : 1104
        case .invalidMove:
            soundID = 1053
        case .pass:
            soundID = 1057
        case .undo:
            soundID = 1156
        case .reset:
            soundID = 1006
        case .gameFinished:
            soundID = 1025
        case .humanVictory:
            soundID = 1025
        }

        AudioServicesPlaySystemSound(soundID)
        #endif
    }

    private func playHaptic(for event: GameFeedbackEvent) {
        #if canImport(UIKit)
        switch event {
        case .menuSelect:
            UISelectionFeedbackGenerator().selectionChanged()
        case .validMove(let flippedCount):
            let style: UIImpactFeedbackGenerator.FeedbackStyle = flippedCount >= 4 ? .medium : .light
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        case .invalidMove:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .pass:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .undo:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .reset:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .gameFinished(let winner):
            UINotificationFeedbackGenerator().notificationOccurred(winner == nil ? .warning : .success)
        case .humanVictory:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        }
        #endif
    }
}

struct OthelloAI {
    private static let winningScore = 1_000_000

    private static let positionWeights = [
        120, -20, 20, 5, 5, 20, -20, 120,
        -20, -40, -5, -5, -5, -5, -40, -20,
        20, -5, 15, 3, 3, 15, -5, 20,
        5, -5, 3, 3, 3, 3, -5, 5,
        5, -5, 3, 3, 3, 3, -5, 5,
        20, -5, 15, 3, 3, 15, -5, 20,
        -20, -40, -5, -5, -5, -5, -40, -20,
        120, -20, 20, 5, 5, 20, -20, 120
    ]

    private static let cornerPositions: Set<BoardPosition> = [
        BoardPosition(row: 0, column: 0),
        BoardPosition(row: 0, column: 7),
        BoardPosition(row: 7, column: 0),
        BoardPosition(row: 7, column: 7)
    ]

    private static let cornerAdjacentPositions: [BoardPosition: [BoardPosition]] = [
        BoardPosition(row: 0, column: 0): [
            BoardPosition(row: 0, column: 1),
            BoardPosition(row: 1, column: 0),
            BoardPosition(row: 1, column: 1)
        ],
        BoardPosition(row: 0, column: 7): [
            BoardPosition(row: 0, column: 6),
            BoardPosition(row: 1, column: 6),
            BoardPosition(row: 1, column: 7)
        ],
        BoardPosition(row: 7, column: 0): [
            BoardPosition(row: 6, column: 0),
            BoardPosition(row: 6, column: 1),
            BoardPosition(row: 7, column: 1)
        ],
        BoardPosition(row: 7, column: 7): [
            BoardPosition(row: 6, column: 6),
            BoardPosition(row: 6, column: 7),
            BoardPosition(row: 7, column: 6)
        ]
    ]

    static func chooseMove(in game: OthelloGame, difficulty: CPUDifficulty) -> BoardPosition? {
        let moves = game.legalMoves()
        guard !moves.isEmpty else {
            return nil
        }

        switch difficulty {
        case .easy:
            return moves.randomElement()
        case .oni:
            return chooseOniMove(in: game, from: moves)
        case .normal, .strong:
            return moves.max { first, second in
                score(move: first, in: game, difficulty: difficulty) < score(move: second, in: game, difficulty: difficulty)
            }
        }
    }

    private static func chooseOniMove(in game: OthelloGame, from moves: [BoardPosition]) -> BoardPosition? {
        let player = game.currentPlayer
        let depth = oniSearchDepth(for: game)
        let orderedMoves = orderedMoves(moves, in: game, for: player)
        var bestMove = orderedMoves[0]
        var bestScore = -winningScore * 10
        var alpha = -winningScore * 10
        let beta = winningScore * 10

        for move in orderedMoves {
            var forecast = game
            _ = forecast.applyMove(at: move)

            let score = minimax(
                game: forecast,
                depth: depth - 1,
                maximizingPlayer: player,
                alpha: alpha,
                beta: beta
            )

            if score > bestScore {
                bestScore = score
                bestMove = move
            }

            alpha = max(alpha, bestScore)
        }

        return bestMove
    }

    private static func score(move: BoardPosition, in game: OthelloGame, difficulty: CPUDifficulty) -> Int {
        let player = game.currentPlayer
        let flippedCount = game.flippedPositions(for: player, at: move).count
        let positionScore = positionWeights[OthelloGame.index(row: move.row, column: move.column)]
        var score = flippedCount * 10 + positionScore

        if difficulty == .strong {
            var forecast = game
            _ = forecast.applyMove(at: move)
            let opponentMobility = forecast.legalMoves(for: player.opponent).count
            let discLead = forecast.count(for: player) - forecast.count(for: player.opponent)
            score += discLead * 2
            score -= opponentMobility * 5
        }

        return score
    }

    private static func minimax(
        game originalGame: OthelloGame,
        depth: Int,
        maximizingPlayer: Disc,
        alpha: Int,
        beta: Int
    ) -> Int {
        var game = originalGame
        normalizePasses(in: &game)

        guard depth > 0, !game.isFinished else {
            return evaluate(game: game, for: maximizingPlayer)
        }

        let moves = orderedMoves(game.legalMoves(), in: game, for: game.currentPlayer)
        guard !moves.isEmpty else {
            return evaluate(game: game, for: maximizingPlayer)
        }

        if game.currentPlayer == maximizingPlayer {
            var bestScore = -winningScore * 10
            var alpha = alpha

            for move in moves {
                var forecast = game
                _ = forecast.applyMove(at: move)
                let score = minimax(
                    game: forecast,
                    depth: depth - 1,
                    maximizingPlayer: maximizingPlayer,
                    alpha: alpha,
                    beta: beta
                )
                bestScore = max(bestScore, score)
                alpha = max(alpha, bestScore)

                if alpha >= beta {
                    break
                }
            }

            return bestScore
        } else {
            var bestScore = winningScore * 10
            var beta = beta

            for move in moves {
                var forecast = game
                _ = forecast.applyMove(at: move)
                let score = minimax(
                    game: forecast,
                    depth: depth - 1,
                    maximizingPlayer: maximizingPlayer,
                    alpha: alpha,
                    beta: beta
                )
                bestScore = min(bestScore, score)
                beta = min(beta, bestScore)

                if alpha >= beta {
                    break
                }
            }

            return bestScore
        }
    }

    private static func oniSearchDepth(for game: OthelloGame) -> Int {
        let emptyCount = game.count(for: .empty)

        if emptyCount <= 10 {
            return max(1, emptyCount)
        } else if emptyCount <= 16 {
            return 8
        } else if emptyCount <= 28 {
            return 6
        } else {
            return 5
        }
    }

    private static func orderedMoves(_ moves: [BoardPosition], in game: OthelloGame, for player: Disc) -> [BoardPosition] {
        moves.sorted { first, second in
            let firstScore = quickMoveScore(move: first, in: game, for: player)
            let secondScore = quickMoveScore(move: second, in: game, for: player)

            if firstScore == secondScore {
                return first.id < second.id
            }

            return firstScore > secondScore
        }
    }

    private static func quickMoveScore(move: BoardPosition, in game: OthelloGame, for player: Disc) -> Int {
        let flippedCount = game.flippedPositions(for: player, at: move).count
        let positionScore = positionWeights[OthelloGame.index(row: move.row, column: move.column)]
        var forecast = game
        _ = forecast.applyMove(at: move)

        let playerMobility = forecast.legalMoves(for: player).count
        let opponentMobility = forecast.legalMoves(for: player.opponent).count
        let opponentCornerAccess = availableCornerCount(in: forecast, for: player.opponent)

        return positionScore * 8
            + flippedCount * 24
            + (playerMobility - opponentMobility) * 36
            + (cornerPositions.contains(move) ? 24_000 : 0)
            - opponentCornerAccess * 9_000
    }

    private static func evaluate(game: OthelloGame, for player: Disc) -> Int {
        let opponent = player.opponent
        let discDifference = game.count(for: player) - game.count(for: opponent)

        if game.isFinished {
            if discDifference > 0 {
                return winningScore + discDifference * 1_000
            } else if discDifference < 0 {
                return -winningScore + discDifference * 1_000
            } else {
                return 0
            }
        }

        let emptyCount = game.count(for: .empty)
        let discWeight = emptyCount <= 16 ? 120 : 8
        let positionalScore = weightedDiscScore(in: game, for: player)
        let mobility = game.legalMoves(for: player).count - game.legalMoves(for: opponent).count
        let cornerOwnership = occupiedCornerCount(in: game, for: player) - occupiedCornerCount(in: game, for: opponent)
        let cornerAccess = availableCornerCount(in: game, for: player) - availableCornerCount(in: game, for: opponent)
        let edgeOwnership = edgeDiscCount(in: game, for: player) - edgeDiscCount(in: game, for: opponent)
        let frontierDifference = frontierDiscCount(in: game, for: player) - frontierDiscCount(in: game, for: opponent)
        let cornerDanger = cornerAdjacentDanger(in: game, for: player) - cornerAdjacentDanger(in: game, for: opponent)

        return positionalScore * 4
            + mobility * 120
            + cornerOwnership * 16_000
            + cornerAccess * 2_400
            + edgeOwnership * 180
            - frontierDifference * 75
            - cornerDanger * 700
            + discDifference * discWeight
    }

    private static func normalizePasses(in game: inout OthelloGame) {
        for _ in 0..<2 where !game.isFinished && game.legalMoves(for: game.currentPlayer).isEmpty {
            _ = game.passTurnIfNeeded()
        }
    }

    private static func weightedDiscScore(in game: OthelloGame, for player: Disc) -> Int {
        var score = 0

        for index in 0..<OthelloGame.cellCount {
            let disc = game.board[index]
            if disc == player {
                score += positionWeights[index]
            } else if disc == player.opponent {
                score -= positionWeights[index]
            }
        }

        return score
    }

    private static func occupiedCornerCount(in game: OthelloGame, for player: Disc) -> Int {
        cornerPositions.filter { game.disc(at: $0) == player }.count
    }

    private static func availableCornerCount(in game: OthelloGame, for player: Disc) -> Int {
        cornerPositions.filter { game.disc(at: $0) == .empty && !game.flippedPositions(for: player, at: $0).isEmpty }.count
    }

    private static func edgeDiscCount(in game: OthelloGame, for player: Disc) -> Int {
        var count = 0

        for row in 0..<OthelloGame.boardSize {
            for column in 0..<OthelloGame.boardSize where isEdge(row: row, column: column) {
                if game.disc(at: BoardPosition(row: row, column: column)) == player {
                    count += 1
                }
            }
        }

        return count
    }

    private static func frontierDiscCount(in game: OthelloGame, for player: Disc) -> Int {
        var count = 0

        for row in 0..<OthelloGame.boardSize {
            for column in 0..<OthelloGame.boardSize {
                let position = BoardPosition(row: row, column: column)
                guard game.disc(at: position) == player else {
                    continue
                }

                if hasAdjacentEmptyCell(from: position, in: game) {
                    count += 1
                }
            }
        }

        return count
    }

    private static func cornerAdjacentDanger(in game: OthelloGame, for player: Disc) -> Int {
        var danger = 0

        for (corner, adjacentPositions) in cornerAdjacentPositions where game.disc(at: corner) == .empty {
            danger += adjacentPositions.filter { game.disc(at: $0) == player }.count
        }

        return danger
    }

    private static func hasAdjacentEmptyCell(from position: BoardPosition, in game: OthelloGame) -> Bool {
        for rowOffset in -1...1 {
            for columnOffset in -1...1 where !(rowOffset == 0 && columnOffset == 0) {
                let row = position.row + rowOffset
                let column = position.column + columnOffset
                guard isInside(row: row, column: column) else {
                    continue
                }

                if game.disc(at: BoardPosition(row: row, column: column)) == .empty {
                    return true
                }
            }
        }

        return false
    }

    private static func isEdge(row: Int, column: Int) -> Bool {
        row == 0 || row == OthelloGame.boardSize - 1 || column == 0 || column == OthelloGame.boardSize - 1
    }

    private static func isInside(row: Int, column: Int) -> Bool {
        (0..<OthelloGame.boardSize).contains(row) && (0..<OthelloGame.boardSize).contains(column)
    }
}

@MainActor
final class OthelloGameViewModel: ObservableObject {
    @Published private(set) var game = OthelloGame()
    @Published var playMode: PlayMode = .twoPlayers {
        didSet {
            resetGame()
        }
    }
    @Published var difficulty: CPUDifficulty = .normal {
        didSet {
            continueTurnFlow()
        }
    }
    @Published private(set) var isThinking = false
    @Published private(set) var feedbackSignal: GameFeedbackSignal?

    private let humanDisc = Disc.black
    private let cpuDisc = Disc.white
    private var history: [OthelloGame] = []
    private var cpuTask: Task<Void, Never>?
    private var cpuWatchdogTask: Task<Void, Never>?
    private var thinkingStartedAt: Date?
    private let cpuThinkDelayNanoseconds: UInt64 = 360_000_000
    private let cpuRecoveryDelayNanoseconds: UInt64 = 2_500_000_000

    init(
        game: OthelloGame = OthelloGame(),
        playMode: PlayMode = .twoPlayers,
        difficulty: CPUDifficulty = .normal
    ) {
        _game = Published(initialValue: game)
        _playMode = Published(initialValue: playMode)
        _difficulty = Published(initialValue: difficulty)
        continueTurnFlow()
    }

    var legalMoveSet: Set<BoardPosition> {
        Set(game.legalMoves())
    }

    var canUndo: Bool {
        !history.isEmpty && !isThinking && !game.isFinished
    }

    var didHumanWinAgainstCPU: Bool {
        playMode == .humanVsCPU && game.isFinished && game.winner == humanDisc
    }

    var didHumanWinAgainstStrongCPU: Bool {
        didHumanWinAgainstCPU && difficulty == .strong
    }

    var statusText: String {
        if game.isFinished {
            return game.lastMessage
        }

        if isThinking {
            return L10n.string("game.cpu_thinking")
        }

        return L10n.format("game.turn", game.currentPlayer.name)
    }

    var isPendingCPUTurn: Bool {
        playMode == .humanVsCPU && !game.isFinished && game.currentPlayer == cpuDisc
    }

    func resumeTurnFlow() {
        if isThinking, !isPendingCPUTurn {
            clearPendingCPUWork()
        } else if isThinking, isThinkingStale {
            clearPendingCPUWork()
        }

        continueTurnFlow()
    }

    func tap(position: BoardPosition) {
        guard !isThinking else {
            return
        }

        guard playMode == .twoPlayers || game.currentPlayer == humanDisc else {
            return
        }

        guard legalMoveSet.contains(position) else {
            game.note(L10n.string("game.invalid_move"))
            emitFeedback(.invalidMove)
            return
        }

        let flippedCount = game.flippedPositions(for: game.currentPlayer, at: position).count
        history.append(game)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            _ = game.applyMove(at: position)
        }
        emitMoveFeedback(flippedCount: flippedCount)
        continueTurnFlow()
    }

    func undo() {
        guard !game.isFinished, !isThinking, let previous = history.popLast() else {
            return
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            game = previous
            game.note(L10n.string("game.undo"))
        }
        emitFeedback(.undo)
        continueTurnFlow()
    }

    func resetGame(playFeedback: Bool = false) {
        clearPendingCPUWork()
        history.removeAll()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            game = OthelloGame()
        }
        if playFeedback {
            emitFeedback(.reset)
        }
        continueTurnFlow()
    }

    private func continueTurnFlow() {
        guard !isThinking else {
            return
        }

        resolvePasses()

        guard isPendingCPUTurn else {
            return
        }

        scheduleCPUTurn()
    }

    private func scheduleCPUTurn() {
        guard cpuTask == nil else {
            return
        }

        isThinking = true
        thinkingStartedAt = Date()

        cpuTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: self.cpuThinkDelayNanoseconds)
            guard !Task.isCancelled else {
                return
            }

            self.cpuTask = nil
            self.performCPUTurnIfNeeded()
        }

        cpuWatchdogTask?.cancel()
        cpuWatchdogTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: self.cpuRecoveryDelayNanoseconds)
            guard !Task.isCancelled, self.isThinking, self.isPendingCPUTurn else {
                return
            }

            self.cpuTask?.cancel()
            self.cpuTask = nil
            self.cpuWatchdogTask = nil
            self.performCPUTurnIfNeeded()
        }
    }

    private func performCPUTurnIfNeeded() {
        guard isPendingCPUTurn else {
            clearPendingCPUWork()
            continueTurnFlow()
            return
        }

        if let move = OthelloAI.chooseMove(in: game, difficulty: difficulty) {
            let flippedCount = game.flippedPositions(for: game.currentPlayer, at: move).count
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                _ = game.applyMove(at: move)
            }
            emitMoveFeedback(flippedCount: flippedCount)
        } else {
            withAnimation(.easeInOut(duration: 0.18)) {
                if game.passTurnIfNeeded() {
                    emitPassFeedback()
                }
            }
        }

        clearPendingCPUWork()
        continueTurnFlow()
    }

    private func resolvePasses() {
        var guardCount = 0
        while !game.isFinished && game.legalMoves(for: game.currentPlayer).isEmpty && guardCount < 2 {
            withAnimation(.easeInOut(duration: 0.18)) {
                if game.passTurnIfNeeded() {
                    emitPassFeedback()
                }
            }
            guardCount += 1
        }
    }

    private func emitMoveFeedback(flippedCount: Int) {
        if game.isFinished {
            emitFinishedFeedback()
        } else {
            emitFeedback(.validMove(flippedCount: flippedCount))
        }
    }

    private func emitPassFeedback() {
        if game.isFinished {
            emitFinishedFeedback()
        } else {
            emitFeedback(.pass)
        }
    }

    private func emitFinishedFeedback() {
        if didHumanWinAgainstCPU {
            emitFeedback(.humanVictory)
        } else {
            emitFeedback(.gameFinished(winner: game.winner))
        }
    }

    private func emitFeedback(_ event: GameFeedbackEvent) {
        feedbackSignal = GameFeedbackSignal(event: event)
    }

    private var isThinkingStale: Bool {
        guard let thinkingStartedAt else {
            return false
        }

        return Date().timeIntervalSince(thinkingStartedAt) > 3
    }

    private func clearPendingCPUWork() {
        cpuTask?.cancel()
        cpuWatchdogTask?.cancel()
        cpuTask = nil
        cpuWatchdogTask = nil
        thinkingStartedAt = nil
        isThinking = false
    }
}

struct ContentView: View {
    private enum Screen {
        case menu
        case game
    }

    @AppStorage("isOniDifficultyUnlocked") private var isOniDifficultyUnlocked = false
    @StateObject private var achievementTracker = AchievementTracker.shared
    @StateObject private var viewModel = OthelloGameViewModel()
    @StateObject private var feedbackController = GameFeedbackController()
    @State private var screen: Screen = .menu
    @State private var isShowingInitialSplash = true
    @State private var showsResetAlert = false
    @State private var reviewRequestedMoveCount: Int?
    @State private var isShowingVictoryCelebration = false
    @State private var victoryCelebrationID = 0
    @State private var celebratedVictoryMoveCount: Int?
    @State private var isResultScreenDismissed = false
    @State private var hasRecordedCurrentGame = false
    @State private var showsOniLeaderboard = false
    @State private var victoryCelebrationTitle = L10n.string("celebration.victory_title")
    @State private var victoryCelebrationMessage = L10n.string("celebration.victory_message")

    var body: some View {
        ZStack {
            ZStack {
                switch screen {
                case .menu:
                    menuScreen
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                case .game:
                    gameScreen
                        .transition(.opacity)
                }
            }
            .disabled(isShowingInitialSplash)

            if isShowingInitialSplash {
                SplashLogoView()
                    .transition(.opacity)
                    .zIndex(2)
            }

            if isShowingVictoryCelebration {
                VictoryCelebrationView(
                    title: victoryCelebrationTitle,
                    message: victoryCelebrationMessage
                )
                .id(victoryCelebrationID)
                .transition(.opacity.combined(with: .scale(scale: 1.02)))
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: screen)
        .animation(.easeOut(duration: 0.35), value: isShowingInitialSplash)
        .animation(.easeOut(duration: 0.22), value: isShowingVictoryCelebration)
        .alert(L10n.string("alert.reset.title"), isPresented: $showsResetAlert) {
            Button(L10n.string("alert.reset.cancel"), role: .cancel) {}
            Button(L10n.string("alert.reset.confirm"), role: .destructive) {
                resetVictoryCelebrationState()
                hasRecordedCurrentGame = false
                viewModel.resetGame(playFeedback: true)
            }
        } message: {
            Text(L10n.string("alert.reset.message"))
        }
        .fullScreenCover(isPresented: $showsOniLeaderboard) {
            OniLeaderboardView(isPresented: $showsOniLeaderboard)
        }
        .onChange(of: viewModel.game.isFinished) { isFinished in
            if isFinished {
                handleGameFinished()
                return
            }

            isResultScreenDismissed = false
            resetVictoryCelebrationState()
        }
        .onChange(of: screen) { newScreen in
            guard newScreen == .game else {
                feedbackController.stopBackgroundMusic()
                return
            }
            feedbackController.startBackgroundMusic()
            viewModel.resumeTurnFlow()
        }
        .onChange(of: viewModel.feedbackSignal?.id) { _ in
            guard let event = viewModel.feedbackSignal?.event else {
                return
            }
            feedbackController.play(event)
        }
        .onAppear {
            achievementTracker.startAuthentication()
            if screen == .game {
                feedbackController.startBackgroundMusic()
            }
            viewModel.resumeTurnFlow()
        }
        .task {
            await hideInitialSplashAfterDelay()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            achievementTracker.retryPendingReports()
            viewModel.resumeTurnFlow()
        }
    }

    private var menuScreen: some View {
        GeometryReader { geometry in
            ZStack {
                OthelloBoardBackdrop()

                ScrollView {
                    VStack(spacing: 26) {
                        Spacer(minLength: 0)

                        VStack(spacing: 12) {
                            MenuChoiceButton(
                                title: L10n.string("menu.two_player_battle"),
                                systemImage: "person.2.fill",
                                action: startTwoPlayerGame
                            )
                            .accessibilityIdentifier("startTwoPlayerButton")

                            VStack(spacing: 8) {
                                Text(L10n.string("menu.cpu_battle"))
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(.white.opacity(0.94))
                                    .shadow(color: .black.opacity(0.28), radius: 2, x: 0, y: 1)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ForEach(CPUDifficulty.allCases) { difficulty in
                                    let isLocked = isDifficultyLocked(difficulty)
                                    MenuChoiceButton(
                                        title: difficulty.title,
                                        systemImage: cpuIcon(for: difficulty),
                                        trailingSystemImage: isLocked ? "lock.fill" : "chevron.right",
                                        isDisabled: isLocked,
                                        action: {
                                            startCPUGame(difficulty: difficulty)
                                        }
                                    )
                                    .accessibilityIdentifier("startCPUButton-\(difficulty.rawValue)")
                                }
                            }
                            .padding(.top, 8)

                            MenuChoiceButton(
                                title: L10n.string("menu.oni_leaderboard"),
                                systemImage: "list.number",
                                isDisabled: !achievementTracker.isGameCenterAuthenticated,
                                action: { showsOniLeaderboard = true }
                            )
                            .accessibilityIdentifier("showOniLeaderboardButton")

                            if !achievementTracker.isGameCenterAuthenticated {
                                Text(L10n.string("menu.leaderboard_requires_game_center"))
                                    .font(.footnote.weight(.semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(maxWidth: 420)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 28)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
    }

    private var gameScreen: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollView {
                    VStack(spacing: viewModel.playMode == .twoPlayers ? 12 : 14) {
                        if viewModel.playMode == .twoPlayers {
                            twoPlayerTopControls

                            board(in: geometry)

                            twoPlayerBottomControls
                        } else {
                            cpuTopControls

                            board(in: geometry)

                            cpuBottomControls
                        }
                    }
                    .padding(.horizontal, gameHorizontalPadding(for: geometry))
                    .padding(.vertical, gameVerticalPadding(for: geometry))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height)
                }

                if viewModel.game.isFinished && !isResultScreenDismissed {
                    GameResultScreen(
                        game: viewModel.game,
                        playMode: viewModel.playMode,
                        difficulty: viewModel.difficulty,
                        playAgainAction: {
                            isResultScreenDismissed = false
                            hasRecordedCurrentGame = false
                            viewModel.resetGame(playFeedback: true)
                        },
                        menuAction: showMenu,
                        dismissAction: dismissResultScreen
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(1)
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: viewModel.game.isFinished)
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: isResultScreenDismissed)
            .background(OthelloTheme.appBackground.ignoresSafeArea())
        }
    }

    private var twoPlayerTopControls: some View {
        PlayerControlStrip(
            title: Disc.white.name,
            disc: .white,
            count: viewModel.game.count(for: .white),
            isActive: viewModel.game.currentPlayer == .white && !viewModel.game.isFinished,
            isThinking: false,
            canUndo: viewModel.canUndo,
            canReset: !viewModel.isThinking,
            menuAction: showMenu,
            undoAction: viewModel.undo,
            resetAction: {
                feedbackController.play(.menuSelect)
                showsResetAlert = true
            }
        )
        .rotationEffect(.degrees(180))
    }

    private var twoPlayerBottomControls: some View {
        PlayerControlStrip(
            title: Disc.black.name,
            disc: .black,
            count: viewModel.game.count(for: .black),
            isActive: viewModel.game.currentPlayer == .black && !viewModel.game.isFinished,
            isThinking: false,
            canUndo: viewModel.canUndo,
            canReset: !viewModel.isThinking,
            menuAction: showMenu,
            undoAction: viewModel.undo,
            resetAction: {
                feedbackController.play(.menuSelect)
                showsResetAlert = true
            }
        )
    }

    private var cpuTopControls: some View {
        PlayerControlStrip(
            title: L10n.format("player.cpu", viewModel.difficulty.title),
            disc: .white,
            count: viewModel.game.count(for: .white),
            isActive: viewModel.game.currentPlayer == .white && !viewModel.game.isFinished,
            isThinking: viewModel.isThinking,
            canUndo: viewModel.canUndo,
            canReset: !viewModel.isThinking,
            menuAction: showMenu,
            undoAction: viewModel.undo,
            resetAction: {
                feedbackController.play(.menuSelect)
                showsResetAlert = true
            }
        )
    }

    private var cpuBottomControls: some View {
        PlayerControlStrip(
            title: Disc.black.name,
            disc: .black,
            count: viewModel.game.count(for: .black),
            isActive: viewModel.game.currentPlayer == .black && !viewModel.game.isFinished,
            isThinking: false,
            canUndo: viewModel.canUndo,
            canReset: !viewModel.isThinking,
            menuAction: showMenu,
            undoAction: viewModel.undo,
            resetAction: {
                feedbackController.play(.menuSelect)
                showsResetAlert = true
            }
        )
    }

    private func board(in geometry: GeometryProxy) -> some View {
        OthelloBoardView(
            game: viewModel.game,
            legalMoves: viewModel.legalMoveSet,
            tapAction: viewModel.tap(position:)
        )
        .frame(width: boardSide(for: geometry), height: boardSide(for: geometry))
    }

    private func hideInitialSplashAfterDelay() async {
        guard isShowingInitialSplash else {
            return
        }

        try? await Task.sleep(nanoseconds: 2_000_000_000)

        guard !Task.isCancelled else {
            return
        }

        withAnimation(.easeOut(duration: 0.35)) {
            isShowingInitialSplash = false
        }
    }

    private func startTwoPlayerGame() {
        feedbackController.play(.menuSelect)
        resetVictoryCelebrationState()
        isResultScreenDismissed = false
        hasRecordedCurrentGame = false
        viewModel.playMode = .twoPlayers
        viewModel.resetGame()
        screen = .game
    }

    private func startCPUGame(difficulty: CPUDifficulty) {
        guard !isDifficultyLocked(difficulty) else {
            feedbackController.play(.invalidMove)
            return
        }

        feedbackController.play(.menuSelect)
        resetVictoryCelebrationState()
        isResultScreenDismissed = false
        hasRecordedCurrentGame = false
        viewModel.difficulty = difficulty
        viewModel.playMode = .humanVsCPU
        viewModel.resetGame()
        screen = .game
    }

    private func showMenu() {
        feedbackController.play(.menuSelect)
        resetVictoryCelebrationState()
        isResultScreenDismissed = false
        screen = .menu
    }

    private func dismissResultScreen() {
        feedbackController.play(.menuSelect)

        withAnimation(.easeOut(duration: 0.2)) {
            isResultScreenDismissed = true
        }
    }

    private func cpuIcon(for difficulty: CPUDifficulty) -> String {
        switch difficulty {
        case .easy:
            return "1.circle.fill"
        case .normal:
            return "circle.grid.3x3.fill"
        case .strong:
            return "bolt.fill"
        case .oni:
            return "flame.fill"
        }
    }

    private func isDifficultyLocked(_ difficulty: CPUDifficulty) -> Bool {
        difficulty.requiresUnlock && !isOniDifficultyUnlocked
    }

    private func boardSide(for geometry: GeometryProxy) -> CGFloat {
        let controlsHeight: CGFloat = 64 * 2
        let verticalSpacing: CGFloat = (viewModel.playMode == .twoPlayers ? 12 : 14) * 2
        let availableWidth = geometry.size.width - gameHorizontalPadding(for: geometry) * 2
        let availableHeight = geometry.size.height - gameVerticalPadding(for: geometry) * 2 - controlsHeight - verticalSpacing

        return max(280, min(availableWidth, availableHeight))
    }

    private func gameHorizontalPadding(for geometry: GeometryProxy) -> CGFloat {
        geometry.size.width < 430 ? 8 : 12
    }

    private func gameVerticalPadding(for geometry: GeometryProxy) -> CGFloat {
        geometry.size.height < 700 ? 8 : 12
    }

    private func handleGameFinished() {
        if !hasRecordedCurrentGame {
            hasRecordedCurrentGame = true
            achievementTracker.recordFinishedGame(
                mode: viewModel.playMode,
                difficulty: viewModel.difficulty,
                winner: viewModel.game.winner,
                finalBlackDiscs: viewModel.game.count(for: .black)
            )
        }
        isResultScreenDismissed = false
        let didUnlockOni = unlockOniIfNeeded()
        requestReviewAfterAIVictoryIfNeeded()
        showVictoryCelebrationIfNeeded(didUnlockOni: didUnlockOni)
    }

    private func unlockOniIfNeeded() -> Bool {
        guard !isOniDifficultyUnlocked,
              viewModel.didHumanWinAgainstStrongCPU else {
            return false
        }

        isOniDifficultyUnlocked = true
        return true
    }

    private func requestReviewAfterAIVictoryIfNeeded() {
        guard viewModel.didHumanWinAgainstCPU,
              reviewRequestedMoveCount != viewModel.game.moveCount else {
            return
        }

        reviewRequestedMoveCount = viewModel.game.moveCount

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            requestStoreReview()
        }
    }

    private func requestStoreReview() {
        #if canImport(UIKit)
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }

        SKStoreReviewController.requestReview(in: scene)
        #endif
    }

    private func showVictoryCelebrationIfNeeded(didUnlockOni: Bool) {
        guard viewModel.didHumanWinAgainstCPU,
              celebratedVictoryMoveCount != viewModel.game.moveCount else {
            return
        }

        if didUnlockOni {
            victoryCelebrationTitle = L10n.string("celebration.unlock_title")
            victoryCelebrationMessage = L10n.string("celebration.unlock_message")
        } else {
            victoryCelebrationTitle = L10n.string("celebration.victory_title")
            victoryCelebrationMessage = L10n.string("celebration.victory_message")
        }

        celebratedVictoryMoveCount = viewModel.game.moveCount
        victoryCelebrationID += 1
        let activeCelebrationID = victoryCelebrationID

        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            isShowingVictoryCelebration = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
            guard victoryCelebrationID == activeCelebrationID else {
                return
            }

            withAnimation(.easeOut(duration: 0.3)) {
                isShowingVictoryCelebration = false
            }
        }
    }

    private func resetVictoryCelebrationState() {
        celebratedVictoryMoveCount = nil
        victoryCelebrationID += 1
        victoryCelebrationTitle = L10n.string("celebration.victory_title")
        victoryCelebrationMessage = L10n.string("celebration.victory_message")

        withAnimation(.easeOut(duration: 0.18)) {
            isShowingVictoryCelebration = false
        }
    }
}

struct SplashLogoView: View {
    var body: some View {
        ZStack {
            OthelloBoardBackdrop()

            GeometryReader { geometry in
                Image("AnimsLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Animis GAME STUDIO")
        .accessibilityIdentifier("studioLogo")
    }
}

struct OthelloBoardBackdrop: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.36, blue: 0.14),
                        Color(red: 0.13, green: 0.52, blue: 0.18),
                        Color(red: 0.04, green: 0.17, blue: 0.09)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                gridPath(in: geometry.size)
                    .stroke(Color.black.opacity(0.28), lineWidth: 1)

                gridPath(in: geometry.size)
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    .offset(x: 1, y: 1)

                DiscView(disc: .white)
                    .frame(width: discSize(for: geometry.size, scale: 0.32), height: discSize(for: geometry.size, scale: 0.32))
                    .opacity(0.16)
                    .blur(radius: 0.3)
                    .position(x: geometry.size.width * 0.82, y: geometry.size.height * 0.22)

                DiscView(disc: .black)
                    .frame(width: discSize(for: geometry.size, scale: 0.38), height: discSize(for: geometry.size, scale: 0.38))
                    .opacity(0.18)
                    .position(x: geometry.size.width * 0.16, y: geometry.size.height * 0.76)

                DiscView(disc: .white)
                    .frame(width: discSize(for: geometry.size, scale: 0.20), height: discSize(for: geometry.size, scale: 0.20))
                    .opacity(0.14)
                    .position(x: geometry.size.width * 0.28, y: geometry.size.height * 0.18)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.08),
                        Color.clear,
                        Color.black.opacity(0.24)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }

    private func gridPath(in size: CGSize) -> Path {
        var path = Path()
        let cellSide = max(46, min(size.width, size.height) / 8)

        var x = -cellSide
        while x <= size.width + cellSide {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            x += cellSide
        }

        var y = -cellSide
        while y <= size.height + cellSide {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            y += cellSide
        }

        return path
    }

    private func discSize(for size: CGSize, scale: CGFloat) -> CGFloat {
        max(92, min(size.width, size.height) * scale)
    }
}

struct VictoryCelebrationView: View {
    let title: String
    let message: String

    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .opacity(isAnimating ? 0.10 : 0)
                    .ignoresSafeArea()

                ForEach(0..<16, id: \.self) { index in
                    confettiPiece(for: index)
                        .frame(width: pieceSize(for: index).width, height: pieceSize(for: index).height)
                        .position(
                            x: geometry.size.width * xPosition(for: index),
                            y: geometry.size.height * (isAnimating ? endYPosition(for: index) : startYPosition(for: index))
                        )
                        .rotationEffect(.degrees(isAnimating ? Double(index * 42 + 180) : Double(index * 10)))
                        .opacity(isAnimating ? 0.95 : 0)
                        .animation(.easeOut(duration: 1.65).delay(Double(index) * 0.035), value: isAnimating)
                }

                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundColor(OthelloTheme.lastMove)

                    Text(title)
                        .font(.largeTitle.weight(.heavy))
                        .foregroundColor(OthelloTheme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)

                    Text(message)
                        .font(.headline.weight(.bold))
                        .foregroundColor(OthelloTheme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .frame(maxWidth: min(max(geometry.size.width - 48, 240), 360))
                .background(Color.white.opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(OthelloTheme.lastMove.opacity(0.84), lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
                .scaleEffect(isAnimating ? 1 : 0.86)
                .offset(y: isAnimating ? 0 : 18)
                .opacity(isAnimating ? 1 : 0)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.32)
                .animation(.spring(response: 0.36, dampingFraction: 0.68).delay(0.1), value: isAnimating)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            isAnimating = false
            DispatchQueue.main.async {
                isAnimating = true
            }
        }
    }

    @ViewBuilder
    private func confettiPiece(for index: Int) -> some View {
        if index.isMultiple(of: 3) {
            Circle()
                .fill(confettiColor(for: index))
        } else if index.isMultiple(of: 2) {
            Capsule()
                .fill(confettiColor(for: index))
        } else {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(confettiColor(for: index))
        }
    }

    private func confettiColor(for index: Int) -> Color {
        [Color.yellow, Color.cyan, Color.pink, Color.orange, Color.mint, Color.purple][index % 6]
    }

    private func pieceSize(for index: Int) -> CGSize {
        let wide = CGSize(width: 8, height: 20)
        let square = CGSize(width: 10, height: 10)
        let flat = CGSize(width: 14, height: 8)
        return [wide, square, flat][index % 3]
    }

    private func xPosition(for index: Int) -> CGFloat {
        let positions: [CGFloat] = [0.08, 0.16, 0.24, 0.33, 0.42, 0.50, 0.58, 0.67, 0.76, 0.84, 0.92, 0.12, 0.28, 0.47, 0.70, 0.88]
        return positions[index % positions.count]
    }

    private func startYPosition(for index: Int) -> CGFloat {
        index.isMultiple(of: 2) ? -0.12 : -0.04
    }

    private func endYPosition(for index: Int) -> CGFloat {
        let positions: [CGFloat] = [0.72, 0.86, 0.78, 0.92, 0.70, 0.84, 0.76, 0.90]
        return positions[index % positions.count]
    }
}

struct MenuChoiceButton: View {
    let title: String
    let systemImage: String
    var trailingSystemImage = "chevron.right"
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.bold))
                    .frame(width: 30)

                Text(title)
                    .font(.headline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 0)

                Image(systemName: trailingSystemImage)
                    .font(.subheadline.weight(.bold))
            }
            .foregroundColor(isDisabled ? .black.opacity(0.42) : .black)
            .padding(.horizontal, 18)
            .frame(height: 58)
            .background(Color.white.opacity(isDisabled ? 0.72 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(isDisabled ? L10n.format("accessibility.locked", title) : title)
    }
}

struct OniLeaderboardView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }

    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let controller = GKGameCenterViewController(
            leaderboardID: AchievementTracker.oniDiscsLeaderboardID,
            playerScope: .global,
            timeScope: .allTime
        )
        controller.gameCenterDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: GKGameCenterViewController, context: Context) {}

    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        @Binding var isPresented: Bool

        init(isPresented: Binding<Bool>) {
            _isPresented = isPresented
        }

        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            isPresented = false
        }
    }
}

struct PlayerControlStrip: View {
    let title: String
    let disc: Disc
    let count: Int
    let isActive: Bool
    let isThinking: Bool
    let canUndo: Bool
    let canReset: Bool
    let menuAction: () -> Void
    let undoAction: () -> Void
    let resetAction: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 12) {
                DiscView(disc: disc)
                    .frame(width: 38, height: 38)
                    .opacity(isActive ? 1 : 0.82)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(isActive ? OthelloTheme.primaryText : OthelloTheme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(count)")
                            .font(.title.monospacedDigit().weight(.heavy))
                            .foregroundColor(OthelloTheme.primaryText)

                        Text(L10n.string("disc.unit"))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(OthelloTheme.secondaryText)
                    }
                }
            }

            if isThinking {
                ProgressView()
                    .scaleEffect(0.78)
                    .frame(width: 28, height: 28)
            } else {
                Capsule()
                    .fill(isActive ? OthelloTheme.accent : Color.clear)
                    .frame(width: 5, height: 36)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                IconControlButton(title: L10n.string("control.menu"), systemImage: "house.fill", action: menuAction)
                IconControlButton(
                    title: L10n.string("control.undo"),
                    systemImage: "arrow.uturn.backward",
                    isDisabled: !canUndo,
                    action: undoAction
                )
                IconControlButton(
                    title: L10n.string("control.reset"),
                    systemImage: "arrow.counterclockwise",
                    tint: OthelloTheme.warning,
                    isDisabled: !canReset,
                    action: resetAction
                )
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .frame(minHeight: 64)
    }
}

struct IconControlButton: View {
    let title: String
    let systemImage: String
    var tint: Color = OthelloTheme.accent
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .foregroundColor(isDisabled ? OthelloTheme.secondaryText.opacity(0.36) : tint)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.46 : 1)
        .accessibilityLabel(title)
    }
}

struct GameResultScreen: View {
    let game: OthelloGame
    let playMode: PlayMode
    let difficulty: CPUDifficulty
    let playAgainAction: () -> Void
    let menuAction: () -> Void
    let dismissAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.34)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                HStack(alignment: .center, spacing: 12) {
                    Text(L10n.string("result.label"))
                        .font(.caption.weight(.heavy))
                        .foregroundColor(OthelloTheme.accent)

                    Spacer(minLength: 0)

                    Button(action: dismissAction) {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.black))
                            .foregroundColor(.white)
                            .frame(width: 46, height: 46)
                            .background(OthelloTheme.warning)
                            .clipShape(Circle())
                            .shadow(color: OthelloTheme.warning.opacity(0.28), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.string("accessibility.dismiss_result"))
                    .accessibilityHint(L10n.string("accessibility.show_board"))
                    .accessibilityIdentifier("dismissResultButton")
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 8) {
                    Text(resultTitle)
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(OthelloTheme.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)

                    Text(resultMessage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(OthelloTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 14) {
                    ScorePill(
                        disc: .black,
                        count: game.count(for: .black),
                        isActive: game.winner == .black
                    )

                    Text("-")
                        .font(.title2.weight(.heavy))
                        .foregroundColor(OthelloTheme.secondaryText)

                    ScorePill(
                        disc: .white,
                        count: game.count(for: .white),
                        isActive: game.winner == .white
                    )
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    L10n.format(
                        "result.score",
                        Int64(game.count(for: .black)),
                        Int64(game.count(for: .white))
                    )
                )

                VStack(spacing: 10) {
                    Button(action: playAgainAction) {
                        Label(L10n.string("result.play_again"), systemImage: "arrow.clockwise.circle.fill")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(OthelloTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("playAgainButton")

                    Button(action: menuAction) {
                        Label(L10n.string("result.menu"), systemImage: "house.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(OthelloTheme.accent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .frame(maxWidth: 420)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: .black.opacity(0.22), radius: 20, x: 0, y: 12)
            .padding(.horizontal, 24)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("resultScreen")
        }
    }

    private var resultTitle: String {
        guard game.isFinished else {
            return L10n.string("result.in_progress")
        }

        if let winner = game.winner {
            return L10n.format("game.winner", winner.name)
        }

        return L10n.string("game.draw")
    }

    private var resultMessage: String {
        guard game.isFinished else {
            return L10n.string("result.play_to_finish")
        }

        if playMode == .humanVsCPU {
            if game.winner == .black {
                return L10n.format("result.human_victory", difficulty.title)
            } else if game.winner == .white {
                return L10n.format("result.cpu_victory", difficulty.title)
            }
            return L10n.format("result.cpu_draw", difficulty.title)
        }

        return L10n.string("result.two_player_message")
    }
}

struct OthelloBoardView: View {
    let game: OthelloGame
    let legalMoves: Set<BoardPosition>
    let tapAction: (BoardPosition) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(minimum: 28), spacing: 0),
        count: OthelloGame.boardSize
    )

    var body: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(0..<OthelloGame.cellCount, id: \.self) { index in
                let position = BoardPosition(row: index / OthelloGame.boardSize, column: index % OthelloGame.boardSize)
                Button {
                    tapAction(position)
                } label: {
                    OthelloCellView(
                        disc: game.disc(at: position),
                        isLegalMove: legalMoves.contains(position),
                        isLastMove: game.lastMove == position
                    )
                    .aspectRatio(1, contentMode: .fit)
                }
                .buttonStyle(.plain)
                .disabled(game.isFinished)
                .accessibilityLabel(accessibilityLabel(for: position))
                .accessibilityIdentifier("boardCell-\(position.row)-\(position.column)")
            }
        }
        .padding(8)
        .background(OthelloTheme.boardFrame)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 10)
    }

    private func accessibilityLabel(for position: BoardPosition) -> String {
        let disc = game.disc(at: position)
        if legalMoves.contains(position) {
            return L10n.format("accessibility.board_cell_legal", position.displayName, disc.name)
        }
        return L10n.format("accessibility.board_cell", position.displayName, disc.name)
    }
}

struct OthelloCellView: View {
    let disc: Disc
    let isLegalMove: Bool
    let isLastMove: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(OthelloTheme.boardCell)
                    .overlay(
                        Rectangle()
                            .stroke(OthelloTheme.gridLine, lineWidth: 1)
                    )

                if isLegalMove {
                    Circle()
                        .strokeBorder(OthelloTheme.legalMove, lineWidth: max(2, geometry.size.width * 0.06))
                        .frame(width: geometry.size.width * 0.34, height: geometry.size.width * 0.34)
                }

                if disc != .empty {
                    DiscView(disc: disc)
                        .frame(width: geometry.size.width * 0.72, height: geometry.size.width * 0.72)
                        .transition(.scale.combined(with: .opacity))
                }

                if isLastMove {
                    Circle()
                        .fill(OthelloTheme.lastMove)
                        .frame(width: geometry.size.width * 0.16, height: geometry.size.width * 0.16)
                        .offset(x: geometry.size.width * 0.26, y: -geometry.size.width * 0.26)
                }
            }
        }
    }
}

struct DiscView: View {
    let disc: Disc

    var body: some View {
        Circle()
            .fill(fill)
            .overlay(
                Circle()
                    .stroke(disc == .white ? Color.black.opacity(0.14) : Color.white.opacity(0.08), lineWidth: 2)
            )
            .shadow(color: .black.opacity(disc == .white ? 0.18 : 0.32), radius: 4, x: 0, y: 3)
    }

    private var fill: LinearGradient {
        switch disc {
        case .black:
            return LinearGradient(
                colors: [Color(red: 0.03, green: 0.04, blue: 0.04), Color(red: 0.16, green: 0.17, blue: 0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .white:
            return LinearGradient(
                colors: [Color.white, Color(red: 0.86, green: 0.87, blue: 0.83)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .empty:
            return LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom)
        }
    }
}

struct ScorePill: View {
    let disc: Disc
    let count: Int
    let isActive: Bool

    var body: some View {
        VStack(spacing: 6) {
            DiscView(disc: disc)
                .frame(width: 34, height: 34)

            Text(disc.name)
                .font(.caption.weight(.bold))
                .foregroundColor(OthelloTheme.secondaryText)

            Text("\(count)")
                .font(.title2.monospacedDigit().weight(.heavy))
                .foregroundColor(OthelloTheme.primaryText)
        }
        .frame(width: 76)
        .padding(.vertical, 10)
        .background(isActive ? OthelloTheme.activePanel : OthelloTheme.panelBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isActive ? OthelloTheme.accent : Color.clear, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct AppMarkView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(OthelloTheme.boardFrame)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 2), spacing: 2) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(OthelloTheme.boardCell)
                        .overlay(
                            DiscView(disc: index == 0 || index == 3 ? .white : .black)
                                .padding(5)
                        )
                }
            }
            .padding(6)
        }
    }
}

enum OthelloTheme {
    static let appBackground = Color(red: 0.93, green: 0.95, blue: 0.91)
    static let panelBackground = Color.white.opacity(0.86)
    static let activePanel = Color(red: 1.0, green: 0.93, blue: 0.72)
    static let primaryText = Color(red: 0.08, green: 0.11, blue: 0.10)
    static let secondaryText = Color(red: 0.31, green: 0.37, blue: 0.34)
    static let boardFrame = Color(red: 0.05, green: 0.18, blue: 0.10)
    static let boardCell = Color(red: 0.14, green: 0.55, blue: 0.17)
    static let gridLine = Color.black.opacity(0.5)
    static let legalMove = Color(red: 1.0, green: 0.87, blue: 0.34).opacity(0.9)
    static let lastMove = Color(red: 0.98, green: 0.64, blue: 0.18)
    static let accent = Color(red: 0.11, green: 0.38, blue: 0.76)
    static let warning = Color(red: 0.82, green: 0.34, blue: 0.14)
}

#Preview {
    ContentView()
}

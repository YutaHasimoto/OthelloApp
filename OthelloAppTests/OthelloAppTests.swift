//
//  OthelloAppTests.swift
//  OthelloAppTests
//
//  Created by 橋本雄太 on 2024/08/31.
//

import XCTest
@testable import OthelloApp

final class OthelloAppTests: XCTestCase {
    func testAllLocalizationsAreBundledAndFormatted() throws {
        struct Expectation {
            let locale: String
            let black: String
            let twoPlayers: String
            let position: String
            let move: String
        }

        let expectations = [
            Expectation(
                locale: "ja", black: "黒", twoPlayers: "2人対戦",
                position: "3行4列", move: "黒が3行4列に置いたにゃ"
            ),
            Expectation(
                locale: "en", black: "Black", twoPlayers: "Two Players",
                position: "row 3, column 4", move: "Black placed a disc at row 3, column 4, meow"
            ),
            Expectation(
                locale: "zh-Hans", black: "黑棋", twoPlayers: "双人对战",
                position: "第3行，第4列", move: "黑棋在第3行，第4列落子，喵"
            ),
            Expectation(
                locale: "pt-BR", black: "Pretas", twoPlayers: "Dois jogadores",
                position: "linha 3, coluna 4", move: "Pretas colocou uma peça em linha 3, coluna 4, miau"
            ),
            Expectation(
                locale: "fr", black: "Noir", twoPlayers: "Deux joueurs",
                position: "ligne 3, colonne 4", move: "Noir a posé un pion en ligne 3, colonne 4, miaou"
            ),
            Expectation(
                locale: "es", black: "Negras", twoPlayers: "Dos jugadores",
                position: "fila 3, columna 4", move: "Negras ha puesto una ficha en fila 3, columna 4, miau"
            ),
            Expectation(
                locale: "ko", black: "흑돌", twoPlayers: "2인 대전",
                position: "3행 4열", move: "흑돌이 3행 4열에 돌을 놓았다냥"
            )
        ]

        for expectation in expectations {
            let bundle = try XCTUnwrap(
                L10n.bundle(for: expectation.locale),
                "Missing bundled localization: \(expectation.locale)"
            )
            XCTAssertEqual(L10n.string("disc.black", bundle: bundle), expectation.black)
            XCTAssertEqual(L10n.string("menu.two_player_battle", bundle: bundle), expectation.twoPlayers)

            let position = L10n.format(
                "board.position",
                arguments: [Int64(3), Int64(4)],
                bundle: bundle
            )
            XCTAssertEqual(position, expectation.position)
            XCTAssertEqual(
                L10n.format("game.move", arguments: [expectation.black, position], bundle: bundle),
                expectation.move
            )
        }
    }

    func testInitialBoardHasStandardFourDiscs() {
        let game = OthelloGame()

        XCTAssertEqual(game.count(for: .black), 2)
        XCTAssertEqual(game.count(for: .white), 2)
        XCTAssertEqual(game.count(for: .empty), 60)
        XCTAssertEqual(game.currentPlayer, .black)
    }

    func testInitialLegalMovesAreAvailableForBlack() {
        let game = OthelloGame()
        let moves = Set(game.legalMoves())

        XCTAssertEqual(moves.count, 4)
        XCTAssertTrue(moves.contains(BoardPosition(row: 2, column: 3)))
        XCTAssertTrue(moves.contains(BoardPosition(row: 3, column: 2)))
        XCTAssertTrue(moves.contains(BoardPosition(row: 4, column: 5)))
        XCTAssertTrue(moves.contains(BoardPosition(row: 5, column: 4)))
    }

    func testApplyingOpeningMoveFlipsCapturedDisc() {
        var game = OthelloGame()

        let didMove = game.applyMove(at: BoardPosition(row: 2, column: 3))

        XCTAssertTrue(didMove)
        XCTAssertEqual(game.count(for: .black), 4)
        XCTAssertEqual(game.count(for: .white), 1)
        XCTAssertEqual(game.currentPlayer, .white)
        XCTAssertEqual(game.disc(at: BoardPosition(row: 3, column: 3)), .black)
    }

    func testIllegalMoveDoesNotChangeBoard() {
        var game = OthelloGame()
        let originalBoard = game.board

        let didMove = game.applyMove(at: BoardPosition(row: 0, column: 0))

        XCTAssertFalse(didMove)
        XCTAssertEqual(game.board, originalBoard)
        XCTAssertEqual(game.currentPlayer, .black)
    }

    func testPassTurnFinishesWhenNeitherPlayerCanMove() {
        var board = Array(repeating: Disc.black, count: OthelloGame.cellCount)
        board[OthelloGame.index(row: 7, column: 7)] = .empty
        var game = OthelloGame(board: board, currentPlayer: .white)

        XCTAssertTrue(game.passTurnIfNeeded())

        XCTAssertTrue(game.isFinished)
        XCTAssertEqual(game.winner, .black)
    }

    func testCPUChoosesALegalMove() {
        let game = OthelloGame()
        let move = OthelloAI.chooseMove(in: game, difficulty: .normal)

        XCTAssertNotNil(move)
        XCTAssertTrue(Set(game.legalMoves()).contains(move!))
    }

    func testOniDifficultyRequiresUnlock() {
        XCTAssertTrue(CPUDifficulty.oni.requiresUnlock)
        XCTAssertFalse(CPUDifficulty.strong.requiresUnlock)
    }

    func testOniDifficultyChoosesAvailableCorner() {
        var board = Array(repeating: Disc.empty, count: OthelloGame.cellCount)
        board[OthelloGame.index(row: 0, column: 1)] = .black
        board[OthelloGame.index(row: 0, column: 2)] = .white
        board[OthelloGame.index(row: 3, column: 3)] = .black
        board[OthelloGame.index(row: 4, column: 3)] = .white
        let game = OthelloGame(board: board, currentPlayer: .white)
        let corner = BoardPosition(row: 0, column: 0)
        let otherMove = BoardPosition(row: 2, column: 3)

        XCTAssertTrue(Set(game.legalMoves()).contains(corner))
        XCTAssertTrue(Set(game.legalMoves()).contains(otherMove))
        XCTAssertEqual(OthelloAI.chooseMove(in: game, difficulty: .oni), corner)
    }

    @MainActor
    func testHumanWinAgainstStrongCPUUnlockPredicate() {
        var board = Array(repeating: Disc.black, count: OthelloGame.cellCount)
        board[OthelloGame.index(row: 0, column: 0)] = .empty
        board[OthelloGame.index(row: 0, column: 1)] = .white
        var game = OthelloGame(board: board, currentPlayer: .black)

        XCTAssertTrue(game.applyMove(at: BoardPosition(row: 0, column: 0)))
        XCTAssertTrue(game.isFinished)
        XCTAssertEqual(game.winner, .black)

        let strongViewModel = OthelloGameViewModel(game: game, playMode: .humanVsCPU, difficulty: .strong)
        let normalViewModel = OthelloGameViewModel(game: game, playMode: .humanVsCPU, difficulty: .normal)

        XCTAssertTrue(strongViewModel.didHumanWinAgainstStrongCPU)
        XCTAssertFalse(normalViewModel.didHumanWinAgainstStrongCPU)
    }

    @MainActor
    func testValidMoveEmitsMoveFeedback() {
        let viewModel = OthelloGameViewModel()

        viewModel.tap(position: BoardPosition(row: 2, column: 3))

        guard case .validMove(let flippedCount) = viewModel.feedbackSignal?.event else {
            XCTFail("Expected a valid move feedback event")
            return
        }

        XCTAssertEqual(flippedCount, 1)
    }

    @MainActor
    func testInvalidMoveEmitsWarningFeedback() {
        let viewModel = OthelloGameViewModel()

        viewModel.tap(position: BoardPosition(row: 0, column: 0))

        guard case .invalidMove = viewModel.feedbackSignal?.event else {
            XCTFail("Expected an invalid move feedback event")
            return
        }
    }

    @MainActor
    func testCPUWithoutLegalMovePassesBackToHuman() {
        var board = Array(repeating: Disc.black, count: OthelloGame.cellCount)
        board[OthelloGame.index(row: 0, column: 0)] = .empty
        board[OthelloGame.index(row: 0, column: 1)] = .white
        let game = OthelloGame(board: board, currentPlayer: .white)

        XCTAssertTrue(game.legalMoves(for: .white).isEmpty)
        XCTAssertTrue(Set(game.legalMoves(for: .black)).contains(BoardPosition(row: 0, column: 0)))

        let viewModel = OthelloGameViewModel(game: game, playMode: .humanVsCPU)

        XCTAssertEqual(viewModel.game.currentPlayer, .black)
        XCTAssertFalse(viewModel.game.isFinished)
        XCTAssertFalse(viewModel.isThinking)
    }

    @MainActor
    func testCPUTurnAutomaticallyMovesAndReturnsToHuman() async throws {
        var game = OthelloGame()
        XCTAssertTrue(game.applyMove(at: BoardPosition(row: 2, column: 3)))

        let viewModel = OthelloGameViewModel(game: game, playMode: .humanVsCPU, difficulty: .normal)

        XCTAssertTrue(viewModel.isThinking)

        try await Task.sleep(nanoseconds: 700_000_000)

        XCTAssertEqual(viewModel.game.currentPlayer, .black)
        XCTAssertFalse(viewModel.isThinking)
        XCTAssertEqual(viewModel.game.count(for: .black) + viewModel.game.count(for: .white), 6)
    }
}

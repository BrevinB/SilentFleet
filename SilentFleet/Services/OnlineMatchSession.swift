import Foundation
import GameKit
import GameEngine

/// Wraps a single `GKTurnBasedMatch` and drives the private-board match
/// protocol: the shared match data (`OnlineMatchState`) carries only public
/// moves and their results, while each device keeps its own fleet private in
/// `OnlineFleetStore`. Incoming moves are adjudicated locally by the defender.
///
/// Slot mapping: the local player owns the slot matching their index in
/// `match.participants`. `participants[0]` controls slot 0, `participants[1]`
/// controls slot 1. This ordering is identical on both clients.
@MainActor
final class OnlineMatchSession {
    let match: GKTurnBasedMatch
    private(set) var state: OnlineMatchState
    let localSlot: Int
    /// The local player's private ships. Empty until they commit placement.
    private(set) var myFleet: [Ship]

    private var localID: String { GKLocalPlayer.local.gamePlayerID }
    private var opponentSlot: Int { 1 - localSlot }

    var isLocalTurn: Bool {
        guard let current = match.currentParticipant else { return false }
        return current.player?.gamePlayerID == localID
    }

    private var opponentParticipant: GKTurnBasedParticipant? {
        match.participants.first { $0.player?.gamePlayerID != localID }
    }

    var opponentDisplayName: String {
        opponentParticipant?.player?.displayName ?? "Opponent"
    }

    /// True if the opponent forfeited out of turn (their GC outcome is `.quit`)
    /// but the match data hasn't been finalized yet.
    var opponentQuit: Bool {
        opponentParticipant?.matchOutcome == .quit
    }

    private init(match: GKTurnBasedMatch, state: OnlineMatchState, localSlot: Int, myFleet: [Ship]) {
        self.match = match
        self.state = state
        self.localSlot = localSlot
        self.myFleet = myFleet
    }

    // MARK: - Loading / bootstrapping

    static func load(
        match: GKTurnBasedMatch,
        creationDefaults: OnlineMatchPreferences? = nil
    ) async throws -> OnlineMatchSession {
        let localID = GKLocalPlayer.local.gamePlayerID
        let localSlot = match.participants.firstIndex { $0.player?.gamePlayerID == localID } ?? 0

        let data = try await match.loadMatchData()
        let state: OnlineMatchState
        if let data, !data.isEmpty {
            do {
                state = try OnlineMatchState.decoded(from: data)
            } catch {
                throw OnlineMatchError.payloadDecodeFailed
            }
        } else {
            let prefs = creationDefaults ?? OnlineMatchPreferences()
            state = OnlineMatchState(mode: prefs.mode, gridSize: prefs.gridSize, split: prefs.split)
        }

        let fleet = OnlineFleetStore.load(matchID: match.matchID) ?? []
        return OnlineMatchSession(match: match, state: state, localSlot: localSlot, myFleet: fleet)
    }

    // MARK: - Derived views into state

    /// The local player's own board, reflecting damage taken from the
    /// opponent's resolved shots.
    var localBoard: Board {
        state.reconstructBoard(forSlot: localSlot, fleet: myFleet)
    }

    var availablePowerUps: [PowerUpType] {
        state.remainingKit(for: localSlot).availableTypes
    }

    // MARK: - Adjudication

    /// Resolve the opponent's pending moves against the local fleet. Returns
    /// whether the local player has just lost. Safe to call repeatedly.
    @discardableResult
    func adjudicateIncoming() -> Bool {
        guard state.phase == .inProgress, !myFleet.isEmpty else { return false }
        let (_, iLost) = state.resolvePendingMoves(attacker: opponentSlot, defenderFleet: myFleet)
        return iLost
    }

    // MARK: - Placement

    func commitPlacement(fleet: [Ship]) async throws {
        myFleet = fleet
        OnlineFleetStore.save(fleet, matchID: match.matchID)
        state.placementDone[localSlot] = true

        if state.placementDone[opponentSlot] {
            // Second placer: start the match and decide who fires first.
            state.phase = .inProgress
            let first: Int
            if state.mode == .ranked {
                first = Int.random(in: 0...1)
            } else {
                // Casual: the first placer (the opponent) fires first.
                first = opponentSlot
            }
            state.firstPlayerIndex = first
            state.currentSlot = first
            if first == localSlot {
                // We go first — keep the turn rather than passing it.
                try await pushSavingTurn()
            } else {
                try await pushEndingTurn(to: first)
            }
        } else {
            // First placer: hand off so the opponent can place.
            state.currentSlot = opponentSlot
            try await pushEndingTurn(to: opponentSlot)
        }
    }

    // MARK: - In-progress actions (each is a full turn)

    func makeShot(at coordinate: Coordinate) async throws {
        state.moves.append(OnlineMove(attackerSlot: localSlot, kind: .shot(coordinate)))
        state.currentSlot = opponentSlot
        try await pushEndingTurn(to: opponentSlot)
    }

    func makeSonar(center: Coordinate) async throws {
        state.moves.append(OnlineMove(attackerSlot: localSlot, kind: .sonar(center: center)))
        state.currentSlot = opponentSlot
        try await pushEndingTurn(to: opponentSlot)
    }

    func makeRowScan(row: Int) async throws {
        state.moves.append(OnlineMove(attackerSlot: localSlot, kind: .rowScan(row: row)))
        state.currentSlot = opponentSlot
        try await pushEndingTurn(to: opponentSlot)
    }

    // MARK: - Endgame

    /// Finalize the match because the local player's fleet was just sunk.
    func finalizeAsLoss() async throws {
        state.winnerSlot = opponentSlot
        state.phase = .finished
        setOutcomes(localWon: false)
        try await pushEndingMatch()
    }

    /// Finalize the match because the opponent forfeited out of turn (so the
    /// turn is now ours and we can write the result).
    func finalizeOpponentQuit() async throws {
        state.winnerSlot = localSlot
        state.phase = .finished
        setOutcomes(localWon: true)
        try await pushEndingMatch()
    }

    /// Forfeit from the local side. In turn we can record the result; out of
    /// turn GameKit only lets us quit and the opponent finalizes later.
    func forfeit() async throws {
        if isLocalTurn {
            state.winnerSlot = opponentSlot
            state.phase = .finished
            setOutcomes(localWon: false)
            try await pushEndingMatch()
        } else {
            try await match.participantQuitOutOfTurn(with: .quit)
        }
    }

    // MARK: - Helpers

    private func setOutcomes(localWon: Bool) {
        for participant in match.participants {
            let isLocal = participant.player?.gamePlayerID == localID
            if isLocal {
                participant.matchOutcome = localWon ? .won : .lost
            } else {
                participant.matchOutcome = localWon ? .lost : .won
            }
        }
    }

    private func pushEndingTurn(to slot: Int) async throws {
        let data = try state.encoded()
        let next = [match.participants[slot]]
        try await match.endTurn(
            withNextParticipants: next,
            turnTimeout: GKTurnTimeoutDefault,
            match: data
        )
    }

    private func pushSavingTurn() async throws {
        let data = try state.encoded()
        try await match.saveCurrentTurn(withMatch: data)
    }

    private func pushEndingMatch() async throws {
        let data = try state.encoded()
        try await match.endMatchInTurn(withMatch: data)
    }
}

enum OnlineMatchError: LocalizedError {
    case notAuthenticated
    case payloadDecodeFailed
    case invalidMatch

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to Game Center to play online."
        case .payloadDecodeFailed:
            return "This match's data could not be read. It may be from a different game version."
        case .invalidMatch:
            return "The match could not be loaded."
        }
    }
}

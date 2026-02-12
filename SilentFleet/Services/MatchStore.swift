import Foundation
import GameEngine

/// Protocol for storing and retrieving game states
/// Designed for future extension to support Game Center and network play
public protocol MatchStore: Sendable {
    func save(_ state: GameState) async throws
    func load(id: UUID) async throws -> GameState?
    func loadAll() async throws -> [GameState]
    func delete(id: UUID) async throws
    func deleteAll() async throws
}

/// Errors that can occur during match storage operations
public enum MatchStoreError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case fileOperationFailed(Error)
    case matchNotFound(UUID)

    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode game state"
        case .decodingFailed:
            return "Failed to decode game state"
        case .fileOperationFailed(let error):
            return "File operation failed: \(error.localizedDescription)"
        case .matchNotFound(let id):
            return "Match not found: \(id)"
        }
    }
}

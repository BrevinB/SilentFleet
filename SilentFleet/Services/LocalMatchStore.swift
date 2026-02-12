import Foundation
import GameEngine

/// Local file-based implementation of MatchStore
/// Stores game states as JSON files in the app's documents directory
public actor LocalMatchStore: MatchStore {

    private let fileManager = FileManager.default

    private var matchesDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("matches", isDirectory: true)
    }

    public init() {
        // Ensure matches directory exists
        try? fileManager.createDirectory(at: matchesDirectory, withIntermediateDirectories: true)
    }

    private func fileURL(for id: UUID) -> URL {
        matchesDirectory.appendingPathComponent("\(id.uuidString).json")
    }

    public func save(_ state: GameState) async throws {
        do {
            let data = try state.encode()
            let url = fileURL(for: state.id)
            try data.write(to: url)
        } catch let error as EncodingError {
            throw MatchStoreError.encodingFailed
        } catch {
            throw MatchStoreError.fileOperationFailed(error)
        }
    }

    public func load(id: UUID) async throws -> GameState? {
        let url = fileURL(for: id)

        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try GameState.decode(from: data)
        } catch is DecodingError {
            throw MatchStoreError.decodingFailed
        } catch {
            throw MatchStoreError.fileOperationFailed(error)
        }
    }

    public func loadAll() async throws -> [GameState] {
        guard fileManager.fileExists(atPath: matchesDirectory.path) else {
            return []
        }

        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: matchesDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            ).filter { $0.pathExtension == "json" }

            var states: [GameState] = []

            for url in fileURLs {
                do {
                    let data = try Data(contentsOf: url)
                    let state = try GameState.decode(from: data)
                    states.append(state)
                } catch {
                    // Skip invalid files
                    continue
                }
            }

            // Sort by creation date (newest first)
            return states.sorted { $0.createdAt > $1.createdAt }

        } catch {
            throw MatchStoreError.fileOperationFailed(error)
        }
    }

    public func delete(id: UUID) async throws {
        let url = fileURL(for: id)

        guard fileManager.fileExists(atPath: url.path) else {
            throw MatchStoreError.matchNotFound(id)
        }

        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw MatchStoreError.fileOperationFailed(error)
        }
    }

    public func deleteAll() async throws {
        guard fileManager.fileExists(atPath: matchesDirectory.path) else {
            return
        }

        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: matchesDirectory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )

            for url in fileURLs {
                try fileManager.removeItem(at: url)
            }
        } catch {
            throw MatchStoreError.fileOperationFailed(error)
        }
    }

    /// Get count of saved matches
    public func matchCount() async -> Int {
        guard fileManager.fileExists(atPath: matchesDirectory.path) else {
            return 0
        }

        do {
            let files = try fileManager.contentsOfDirectory(
                at: matchesDirectory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            ).filter { $0.pathExtension == "json" }
            return files.count
        } catch {
            return 0
        }
    }
}

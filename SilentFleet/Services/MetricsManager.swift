import Foundation
import MetricKit

/// Subscribes to MetricKit to capture crash diagnostics, hang reports, and
/// performance metrics. Each payload is appended to a JSON-lines log in the
/// app's Application Support directory so it can be inspected via the Files
/// app (Documents directory share) or exported by support tools.
///
/// MetricKit delivers payloads ~once per day (or shortly after a crash on
/// next launch), so this is a passive background service — no UI required.
final class MetricsManager: NSObject, MXMetricManagerSubscriber {
    static let shared = MetricsManager()

    private let queue = DispatchQueue(label: "co.brevinb.silentfleet.metrics", qos: .utility)
    private let fileManager = FileManager.default

    private override init() { super.init() }

    /// Call once at app launch.
    func start() {
        MXMetricManager.shared.add(self)
    }

    // MARK: - MXMetricManagerSubscriber

    func didReceive(_ payloads: [MXMetricPayload]) {
        queue.async { [weak self] in
            self?.append(payloads.map { $0.jsonRepresentation() }, suffix: "metrics")
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        queue.async { [weak self] in
            self?.append(payloads.map { $0.jsonRepresentation() }, suffix: "diagnostics")
        }
    }

    // MARK: - File sink

    private func append(_ jsonChunks: [Data], suffix: String) {
        guard let dir = supportDirectory() else { return }
        let logURL = dir.appendingPathComponent("metrickit-\(suffix).log")
        do {
            if !fileManager.fileExists(atPath: logURL.path) {
                fileManager.createFile(atPath: logURL.path, contents: nil)
            }
            let handle = try FileHandle(forWritingTo: logURL)
            defer { try? handle.close() }
            try handle.seekToEnd()
            for chunk in jsonChunks {
                try handle.write(contentsOf: chunk)
                try handle.write(contentsOf: Data("\n".utf8))
            }
        } catch {
            // Diagnostics best-effort; never break the app over a write failure.
        }
    }

    private func supportDirectory() -> URL? {
        guard let url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
}

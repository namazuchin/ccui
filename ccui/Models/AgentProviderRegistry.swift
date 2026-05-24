import Foundation

@MainActor
final class AgentProviderRegistry {
    static let shared = AgentProviderRegistry()

    let allProviders: [any AgentProvider] = [
        ClaudeCodeProvider(),
        OpenCodeProvider(),
        CodexProvider(),
    ]

    /// Detect which agent CLIs are available on the system PATH
    func detectAvailableProviders() async -> [any AgentProvider] {
        var available: [any AgentProvider] = []
        for provider in allProviders {
            if await isCLIAvailable(provider.cliName) {
                available.append(provider)
            }
        }
        return available
    }

    func provider(for id: String) -> (any AgentProvider)? {
        allProviders.first { $0.id == id }
    }

    private func isCLIAvailable(_ name: String) async -> Bool {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-l", "-c", "which \(name)"]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            do {
                try process.run()
                process.waitUntilExit()
                continuation.resume(returning: process.terminationStatus == 0)
            } catch {
                continuation.resume(returning: false)
            }
        }
    }
}

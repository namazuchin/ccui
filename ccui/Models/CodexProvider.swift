import Foundation

/// Codex agent provider — placeholder for future hook support.
struct CodexProvider: AgentProvider, Sendable {
    let id = "codex"
    let displayName = "Codex"
    let cliName = "codex"
    let configDirectoryName = ".codex"
    let settingsFileName = "config.json"
    let instructionFileName = "AGENTS.md"
    let titlePattern: String? = "codex"
    let hookEventNames: [String] = []

    func launchArgs(cliPath: String, sessionId: String, isResume: Bool) -> String {
        if isResume {
            return "\(cliPath) --resume \(sessionId)"
        } else {
            return "\(cliPath) --session-id \(sessionId)"
        }
    }

    func parseHookPayload(data: Data) -> AgentHookPayload? {
        // Codex does not support hooks yet
        return nil
    }

    func installHooks(worktreePath: String, socketPath: String) throws {
        // No-op: Codex does not support hooks yet
    }

    func uninstallHooks(worktreePath: String) throws {
        // No-op: Codex does not support hooks yet
    }

    func notificationMessage(toolName: String?) -> String {
        if let tool = toolName, !tool.isEmpty {
            return "Codex wants to use \(tool)"
        }
        return "Codex needs permission"
    }

    func notificationTitle() -> String {
        return "Codex needs your attention"
    }
}

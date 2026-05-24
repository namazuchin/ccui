import Foundation

/// OpenCode agent provider — placeholder for future hook support.
struct OpenCodeProvider: AgentProvider, Sendable {
    let id = "opencode"
    let displayName = "OpenCode"
    let cliName = "opencode"
    let configDirectoryName = ".opencode"
    let settingsFileName = "config.json"
    let instructionFileName = "OPENCODE.md"
    let titlePattern: String? = "opencode"
    let hookEventNames: [String] = []

    func launchArgs(cliPath: String, sessionId: String, isResume: Bool) -> String {
        if isResume {
            return "\(cliPath) --resume \(sessionId)"
        } else {
            return "\(cliPath) --session \(sessionId)"
        }
    }

    func parseHookPayload(data: Data) -> AgentHookPayload? {
        // OpenCode does not support hooks yet
        return nil
    }

    func installHooks(worktreePath: String, socketPath: String) throws {
        // No-op: OpenCode does not support hooks yet
    }

    func uninstallHooks(worktreePath: String) throws {
        // No-op: OpenCode does not support hooks yet
    }

    func notificationMessage(toolName: String?) -> String {
        if let tool = toolName, !tool.isEmpty {
            return "OpenCode wants to use \(tool)"
        }
        return "OpenCode needs permission"
    }

    func notificationTitle() -> String {
        return "OpenCode needs your attention"
    }
}

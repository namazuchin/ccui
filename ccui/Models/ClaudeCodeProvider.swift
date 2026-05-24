import Foundation
import OSLog

/// Claude Code agent provider — the original ccui target.
struct ClaudeCodeProvider: AgentProvider, Sendable {
    let id = "claude"
    let displayName = "Claude Code"
    let cliName = "claude"
    let configDirectoryName = ".claude"
    let settingsFileName = "settings.local.json"
    let instructionFileName = "CLAUDE.md"
    let titlePattern: String? = "Claude Code"
    let hookEventNames = [
        "Stop", "Notification", "PreToolUse", "PostToolUse",
        "SubagentStop", "PermissionRequest", "UserPromptSubmit",
    ]

    func launchArgs(cliPath: String, sessionId: String, isResume: Bool) -> String {
        if isResume {
            return "\(cliPath) --resume \(sessionId)"
        } else {
            return "\(cliPath) --session-id \(sessionId)"
        }
    }

    func parseHookPayload(data: Data) -> AgentHookPayload? {
        let decoder = JSONDecoder()
        guard let raw = try? decoder.decode(ClaudeRawHookPayload.self, from: data) else {
            return nil
        }
        guard let eventName = AgentHookEventName(rawValue: raw.hookEventName.rawValue) else {
            return nil
        }
        return AgentHookPayload(
            providerId: id,
            hookEventName: eventName,
            cwd: raw.cwd,
            notificationType: raw.notificationType,
            message: raw.message,
            isMuted: raw.isMuted,
            toolName: raw.toolName,
            sessionId: raw.sessionId,
            prompt: raw.prompt,
            toolInput: raw.toolInput
        )
    }

    func installHooks(worktreePath: String, socketPath: String) throws {
        ClaudeHooksInstaller.install(worktreePath: worktreePath, socketPath: socketPath)
    }

    func uninstallHooks(worktreePath: String) throws {
        ClaudeHooksInstaller.uninstall(worktreePath: worktreePath)
    }

    func notificationMessage(toolName: String?) -> String {
        if let tool = toolName, !tool.isEmpty {
            return "Claude wants to use \(tool)"
        }
        return "Claude needs permission"
    }

    func notificationTitle() -> String {
        return "Claude needs your attention"
    }
}

// MARK: - Claude-specific wire format

/// Wire-format decoder matching Claude Code's hook JSON schema.
/// Kept as a private Decodable type so the public API uses the generic AgentHookPayload.
private struct ClaudeRawHookPayload: Decodable, Sendable {
    enum HookEventName: String, Codable, Sendable {
        case stop = "Stop"
        case notification = "Notification"
        case preToolUse = "PreToolUse"
        case postToolUse = "PostToolUse"
        case subagentStop = "SubagentStop"
        case permissionRequest = "PermissionRequest"
        case userPromptSubmit = "UserPromptSubmit"
    }

    let hookEventName: HookEventName
    let cwd: String
    let notificationType: String?
    let message: String?
    let isMuted: Bool?
    let toolName: String?
    let sessionId: String?
    let prompt: String?
    let toolInput: String?

    private enum CodingKeys: String, CodingKey {
        case hookEventName = "hook_event_name"
        case cwd
        case notificationType = "notification_type"
        case message
        case isMuted = "is_muted"
        case toolName = "tool_name"
        case sessionId = "session_id"
        case prompt
        case toolInput = "tool_input"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hookEventName = try container.decode(HookEventName.self, forKey: .hookEventName)
        cwd = try container.decode(String.self, forKey: .cwd)
        notificationType = try container.decodeIfPresent(String.self, forKey: .notificationType)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        isMuted = try container.decodeIfPresent(Bool.self, forKey: .isMuted)
        toolName = try container.decodeIfPresent(String.self, forKey: .toolName)
        sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
        prompt = try container.decodeIfPresent(String.self, forKey: .prompt)
        if container.contains(.toolInput) {
            let raw = try container.decode(AnyCodableValue.self, forKey: .toolInput)
            let data = try JSONSerialization.data(withJSONObject: raw.value, options: [.sortedKeys])
            toolInput = String(data: data, encoding: .utf8)
        } else {
            toolInput = nil
        }
    }
}

/// Wrapper for decoding arbitrary JSON values from hook payloads.
private struct AnyCodableValue: Decodable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let dict = try? container.decode([String: AnyCodableValue].self) {
            value = dict.mapValues(\.value)
        } else if let array = try? container.decode([AnyCodableValue].self) {
            value = array.map(\.value)
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }
}

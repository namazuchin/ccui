import Foundation

// MARK: - Hook Level

enum HookLevel: String, CaseIterable, Identifiable, Sendable {
    case worktree = "Worktree"
    case user = "User"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .worktree: "{worktree}/<agent-config>/settings.local.json"
        case .user: "~/<agent-config>/settings.local.json"
        }
    }

    func settingsPath(worktreePath: String, provider: any AgentProvider = ClaudeCodeProvider()) -> String {
        switch self {
        case .worktree:
            return (worktreePath as NSString)
                .appendingPathComponent(provider.configDirectoryName)
                .appendingPathComponent(provider.settingsFileName)
        case .user:
            return (NSHomeDirectory() as NSString)
                .appendingPathComponent(provider.configDirectoryName)
                .appendingPathComponent(provider.settingsFileName)
        }
    }
}

// MARK: - Hook Command

struct HookCommand: Identifiable, Hashable, Sendable {
    var id: UUID
    var type: String
    var command: String

    init(id: UUID = UUID(), type: String = "command", command: String = "") {
        self.id = id
        self.type = type
        self.command = command
    }
}

// MARK: - Hook Entry

struct HookEntry: Identifiable, Hashable, Sendable {
    var id: UUID
    var matcher: String
    var hooks: [HookCommand]
    let isManagedByCCUI: Bool

    init(id: UUID = UUID(), matcher: String = "", hooks: [HookCommand] = [], isManagedByCCUI: Bool = false) {
        self.id = id
        self.matcher = matcher
        self.hooks = hooks
        self.isManagedByCCUI = isManagedByCCUI
    }
}

// MARK: - Hook Fire Log

struct HookFireLog: Identifiable, Hashable, Sendable {
    let id: UUID
    let eventName: AgentHookPayload.HookEventName
    let toolName: String?
    let sessionId: String
    let receivedAt: Date

    init(event: AgentEvent) {
        self.id = event.id
        self.eventName = event.hookEventName
        self.toolName = event.toolName
        self.sessionId = event.sessionId
        self.receivedAt = event.receivedAt
    }
}

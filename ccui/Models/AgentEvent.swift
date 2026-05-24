import Foundation

/// Generic hook event names across all agents
enum AgentHookEventName: String, Codable, Sendable, CaseIterable {
    case stop = "Stop"
    case notification = "Notification"
    case preToolUse = "PreToolUse"
    case postToolUse = "PostToolUse"
    case subagentStop = "SubagentStop"
    case permissionRequest = "PermissionRequest"
    case userPromptSubmit = "UserPromptSubmit"
}

/// Generic hook payload decoded from agent-specific JSON
struct AgentHookPayload: Sendable {
    let providerId: String
    let hookEventName: AgentHookEventName
    let cwd: String
    let notificationType: String?
    let message: String?
    let isMuted: Bool?
    let toolName: String?
    let sessionId: String?
    let prompt: String?
    let toolInput: String?
}

/// Generic agent event stored and displayed by ccui
struct AgentEvent: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let worktreePath: String
    let sessionId: String
    let providerId: String
    let hookEventName: AgentHookEventName
    let notificationType: String?
    let message: String?
    let toolName: String?
    let prompt: String?
    let toolInput: String?
    let receivedAt: Date

    nonisolated static func == (lhs: AgentEvent, rhs: AgentEvent) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    init(worktreePath: String, providerId: String, payload: AgentHookPayload) {
        self.id = UUID()
        self.worktreePath = worktreePath
        self.providerId = providerId
        self.sessionId = payload.sessionId ?? "__anonymous__"
        self.hookEventName = payload.hookEventName
        self.notificationType = payload.notificationType
        self.message = payload.message
        self.toolName = payload.toolName
        self.prompt = payload.prompt
        self.toolInput = payload.toolInput
        self.receivedAt = Date()
    }

    init(id: UUID, worktreePath: String, sessionId: String, providerId: String, hookEventName: AgentHookEventName, notificationType: String?, message: String?, toolName: String?, prompt: String? = nil, toolInput: String? = nil, receivedAt: Date) {
        self.id = id
        self.worktreePath = worktreePath
        self.sessionId = sessionId
        self.providerId = providerId
        self.hookEventName = hookEventName
        self.notificationType = notificationType
        self.message = message
        self.toolName = toolName
        self.prompt = prompt
        self.toolInput = toolInput
        self.receivedAt = receivedAt
    }
}

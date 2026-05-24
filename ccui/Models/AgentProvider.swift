import Foundation

// MARK: - AgentProvider Protocol

/// AI コーディングエージェントの抽象化プロトコル。
/// 各エージェント (Claude Code, OpenCode, Codex 等) はこのプロトコルを実装する。
protocol AgentProvider: Sendable {
    /// 一意識別子 (e.g. "claude", "opencode", "codex")
    var id: String { get }
    /// ユーザー表示名 (e.g. "Claude Code")
    var displayName: String { get }
    /// CLI 実行ファイル名 (e.g. "claude")
    var cliName: String { get }
    /// 設定ディレクトリ名 (e.g. ".claude")
    var configDirectoryName: String { get }
    /// 設定ファイル名 (e.g. "settings.local.json")
    var settingsFileName: String { get }
    /// ユーザー設定ファイル名 (e.g. "settings.json") — nil の場合はユーザー設定ファイルなし
    var userSettingsFileName: String? { get }
    /// 指示ファイル名 (e.g. "CLAUDE.md")
    var instructionFileName: String { get }
    /// プロジェクトローカル指示ファイルの相対パス (e.g. ".claude/CLAUDE.md")
    var projectLocalInstructionPath: String { get }
    /// ターミナルタイトルからセッション名を抽出するためのパターン
    var titleIgnorePattern: String { get }
    /// hooks をサポートするかどうか
    var supportsHooks: Bool { get }
    /// サポートする hook イベント名
    var hookEventNames: [String] { get }
    /// 通知メッセージ生成
    func notificationTitle(for event: AgentEvent) -> String
    /// 権限要求通知の本文
    func notificationBody(for event: AgentEvent) -> String
}

// MARK: - Default Implementations

extension AgentProvider {
    var userSettingsFileName: String? { nil }
    var supportsHooks: Bool { true }

    func notificationBody(for event: AgentEvent) -> String {
        let worktreeName = (event.worktreePath as NSString).lastPathComponent
        if let message = event.message, !message.isEmpty {
            return "\(worktreeName): \(message)"
        }
        return worktreeName
    }
}

// MARK: - ClaudeCodeProvider

struct ClaudeCodeProvider: AgentProvider {
    let id = "claude"
    let displayName = "Claude Code"
    let cliName = "claude"
    let configDirectoryName = ".claude"
    let settingsFileName = "settings.local.json"
    let userSettingsFileName = "settings.json"
    let instructionFileName = "CLAUDE.md"
    let projectLocalInstructionPath = ".claude/CLAUDE.md"
    let titleIgnorePattern = "Claude Code"
    let hookEventNames = [
        "Stop", "Notification", "PreToolUse", "PostToolUse",
        "SubagentStop", "PermissionRequest", "UserPromptSubmit"
    ]

    func notificationTitle(for event: AgentEvent) -> String {
        switch event.hookEventName {
        case .permissionRequest:
            if let tool = event.toolName, !tool.isEmpty {
                return "Claude wants to use \(tool)"
            }
            return "Claude needs permission"
        default:
            return "Claude needs your attention"
        }
    }
}

// MARK: - OpenCodeProvider

struct OpenCodeProvider: AgentProvider {
    let id = "opencode"
    let displayName = "OpenCode"
    let cliName = "opencode"
    let configDirectoryName = ".opencode"
    let settingsFileName = "settings.local.json"
    let instructionFileName = "OPENCODE.md"
    let projectLocalInstructionPath = ".opencode/OPENCODE.md"
    let titleIgnorePattern = "OpenCode"
    let hookEventNames = [
        "Stop", "Notification", "PreToolUse", "PostToolUse",
        "SubagentStop", "PermissionRequest"
    ]

    func notificationTitle(for event: AgentEvent) -> String {
        switch event.hookEventName {
        case .permissionRequest:
            if let tool = event.toolName, !tool.isEmpty {
                return "OpenCode wants to use \(tool)"
            }
            return "OpenCode needs permission"
        default:
            return "OpenCode needs your attention"
        }
    }
}

// MARK: - CodexProvider

struct CodexProvider: AgentProvider {
    let id = "codex"
    let displayName = "Codex"
    let cliName = "codex"
    let configDirectoryName = ".codex"
    let settingsFileName = "config.json"
    let instructionFileName = "AGENTS.md"
    let projectLocalInstructionPath = ".codex/AGENTS.md"
    let titleIgnorePattern = "Codex"
    let hookEventNames = [
        "Stop", "Notification", "PreToolUse", "PostToolUse",
        "PermissionRequest"
    ]

    func notificationTitle(for event: AgentEvent) -> String {
        switch event.hookEventName {
        case .permissionRequest:
            if let tool = event.toolName, !tool.isEmpty {
                return "Codex wants to use \(tool)"
            }
            return "Codex needs permission"
        default:
            return "Codex needs your attention"
        }
    }
}

// MARK: - AgentProviderRegistry

@MainActor
final class AgentProviderRegistry {
    static let shared = AgentProviderRegistry()

    /// 登録済みプロバイダー
    let allProviders: [any AgentProvider] = [
        ClaudeCodeProvider(),
        OpenCodeProvider(),
        CodexProvider()
    ]

    /// デフォルトプロバイダー
    var defaultProvider: any AgentProvider {
        // 最初は Claude Code をデフォルトとする
        // TODO: ユーザー設定から取得する
        allProviders.first { $0.id == "claude" }!
    }

    /// 指定 ID のプロバイダーを取得
    func provider(for id: String) -> (any AgentProvider)? {
        allProviders.first { $0.id == id }
    }

    /// PATH 上で利用可能な CLI を検出
    func detectAvailableProviders() async -> [any AgentProvider] {
        await Task.detached(priority: .userInitiated) {
            var available: [any AgentProvider] = []
            for provider in self.allProviders {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/sh")
                process.arguments = ["-l", "-c", "which \(provider.cliName)"]
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice
                do {
                    try process.run()
                    process.waitUntilExit()
                    if process.terminationStatus == 0 {
                        available.append(provider)
                    }
                } catch {
                    // CLI not found, skip
                }
            }
            return available
        }.value
    }

    private init() {}
}

import Foundation

final class AgentHooksInstaller {
    /// settings.local.json は read-modify-write なので、`WorktreeStore.load` の
    /// `withTaskGroup` で並行実行されるとユーザー定義 hooks を取り違えて上書きする。
    /// install 全体を直列化する。
    private static let installLock = NSLock()

    nonisolated static func install(
        worktreePath: String,
        socketPath: String = UDSListenerService.socketPath,
        provider: any AgentProvider = ClaudeCodeProvider()
    ) throws {
        installLock.lock()
        defer { installLock.unlock() }

        let configDir = (worktreePath as NSString).appendingPathComponent(provider.configDirectoryName)
        let settingsPath = (configDir as NSString).appendingPathComponent(provider.settingsFileName)

        try FileManager.default.createDirectory(atPath: configDir, withIntermediateDirectories: true)

        // Read existing settings or create new
        var settings: [String: Any]
        if let data = try? Data(contentsOf: URL(fileURLWithPath: settingsPath)),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            settings = existing
        } else {
            settings = [:]
        }

        // Read existing hooks, preserving non-ccui hooks
        var hooksDict = settings["hooks"] as? [String: Any] ?? [:]

        let ccuiHookCommand = "echo '$CCUI_PAYLOAD' | nc -U \(socketPath)"

        for eventName in provider.hookEventNames {
            var eventHooks = hooksDict[eventName] as? [[String: Any]] ?? []

            // Remove existing ccui hooks
            eventHooks.removeAll { entry in
                guard let hooks = entry["hooks"] as? [[String: Any]] else { return false }
                return hooks.contains { hook in
                    guard let cmd = hook["command"] as? String else { return false }
                    return cmd.contains("nc -U") && cmd.contains("CCUI")
                }
            }

            // Add ccui hook
            eventHooks.append([
                "hooks": [
                    ["type": "command", "command": ccuiHookCommand]
                ]
            ])

            hooksDict[eventName] = eventHooks
        }

        settings["hooks"] = hooksDict

        let data = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: URL(fileURLWithPath: settingsPath), options: .atomic)
    }

    nonisolated static func uninstall(
        worktreePath: String,
        provider: any AgentProvider = ClaudeCodeProvider()
    ) throws {
        let configDir = (worktreePath as NSString).appendingPathComponent(provider.configDirectoryName)
        let settingsPath = (configDir as NSString).appendingPathComponent(provider.settingsFileName)

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: settingsPath)),
              var settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              var hooksDict = settings["hooks"] as? [String: Any] else {
            return
        }

        for eventName in provider.hookEventNames {
            guard var eventHooks = hooksDict[eventName] as? [[String: Any]] else { continue }
            eventHooks.removeAll { entry in
                guard let hooks = entry["hooks"] as? [[String: Any]] else { return false }
                return hooks.contains { hook in
                    guard let cmd = hook["command"] as? String else { return false }
                    return cmd.contains("nc -U") && cmd.contains("CCUI")
                }
            }
            if eventHooks.isEmpty {
                hooksDict.removeValue(forKey: eventName)
            } else {
                hooksDict[eventName] = eventHooks
            }
        }

        settings["hooks"] = hooksDict
        let newData = try JSONSerialization.data(withJSONObject: settings, options: [.prettyPrinted, .sortedKeys])
        try newData.write(to: URL(fileURLWithPath: settingsPath), options: .atomic)
    }
}

// MARK: - Backward Compatibility

@available(*, deprecated, renamed: "AgentHooksInstaller")
typealias ClaudeHooksInstaller = AgentHooksInstaller

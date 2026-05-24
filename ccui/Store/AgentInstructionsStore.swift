import Foundation
import OSLog

enum AgentInstructionsLevel: String, Sendable, CaseIterable, Identifiable {
    case user = "User"
    case project = "Project"
    case projectLocal = "Project Local"

    var id: String { rawValue }

    func description(provider: any AgentProvider) -> String {
        switch self {
        case .user: "~/\(provider.configDirectoryName)/\(provider.instructionFileName) — applies to all projects"
        case .project: "\(provider.instructionFileName) — checked into the repository"
        case .projectLocal: "\(provider.projectLocalInstructionPath) — gitignored, local only"
        }
    }

    func filePath(provider: any AgentProvider, repositoryPath: String) -> String {
        switch self {
        case .user:
            return (NSHomeDirectory() as NSString)
                .appendingPathComponent(provider.configDirectoryName)
                .appendingPathComponent(provider.instructionFileName)
        case .project:
            return (repositoryPath as NSString)
                .appendingPathComponent(provider.instructionFileName)
        case .projectLocal:
            return (repositoryPath as NSString)
                .appendingPathComponent(provider.projectLocalInstructionPath)
        }
    }
}

// MARK: - Backward Compatibility
@available(*, deprecated, renamed: "AgentInstructionsLevel")
typealias ClaudeMdLevel = AgentInstructionsLevel

struct AgentInstructionsFile: Identifiable, Sendable {
    let id: AgentInstructionsLevel
    let level: AgentInstructionsLevel
    let path: String
    let exists: Bool
    let content: String?
    let modifiedAt: Date?
}

@available(*, deprecated, renamed: "AgentInstructionsFile")
typealias ClaudeMdFile = AgentInstructionsFile

@Observable
@MainActor
final class AgentInstructionsStore {
    private(set) var files: [AgentInstructionsFile] = []
    var selectedLevel: AgentInstructionsLevel?
    var editorContent: String = ""
    var isDirty: Bool = false
    private(set) var loadedContent: String = ""
    var lastError: String?

    private var repositoryPath: String = ""
    private let provider: any AgentProvider

    init(provider: any AgentProvider = AgentProviderRegistry.shared.defaultProvider) {
        self.provider = provider
    }

    func load(repositoryPath: String) {
        self.repositoryPath = repositoryPath
        let fm = FileManager.default

        files = AgentInstructionsLevel.allCases.map { level in
            let path = level.filePath(provider: provider, repositoryPath: repositoryPath)
            let exists = fm.fileExists(atPath: path)
            var content: String?
            var modifiedAt: Date?

            if exists {
                content = try? String(contentsOfFile: path, encoding: .utf8)
                modifiedAt = (try? fm.attributesOfItem(atPath: path))?[.modificationDate] as? Date
            }

            return AgentInstructionsFile(
                id: level,
                level: level,
                path: path,
                exists: exists,
                content: content,
                modifiedAt: modifiedAt
            )
        }

        // selectedLevel を維持（リロード時）
        if let level = selectedLevel, let file = files.first(where: { $0.level == level }) {
            let content = file.content ?? ""
            loadedContent = content
            editorContent = content
            isDirty = false
        }
    }

    func select(_ level: AgentInstructionsLevel) {
        if selectedLevel == level {
            selectedLevel = nil
            loadedContent = ""
            editorContent = ""
            isDirty = false
            return
        }
        selectedLevel = level
        let content: String
        if let file = files.first(where: { $0.level == level }) {
            content = file.content ?? ""
        } else {
            content = ""
        }
        loadedContent = content
        editorContent = content
        isDirty = false
    }

    func save() {
        guard let level = selectedLevel else { return }
        let path = level.filePath(provider: provider, repositoryPath: repositoryPath)

        do {
            let directory = (path as NSString).deletingLastPathComponent
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            try editorContent.write(toFile: path, atomically: true, encoding: .utf8)
            isDirty = false
            lastError = nil
            load(repositoryPath: repositoryPath)
        } catch {
            Logger.store.error("Failed to save \(path, privacy: .public): \(error)")
            lastError = "Failed to save \(level.rawValue): \(error.localizedDescription)"
        }
    }

    func reset() {
        files = []
        selectedLevel = nil
        loadedContent = ""
        editorContent = ""
        isDirty = false
        repositoryPath = ""
    }

    func createFile(at level: AgentInstructionsLevel) {
        let path = level.filePath(provider: provider, repositoryPath: repositoryPath)
        do {
            let directory = (path as NSString).deletingLastPathComponent
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            try "".write(toFile: path, atomically: true, encoding: .utf8)
            lastError = nil
            load(repositoryPath: repositoryPath)
            select(level)
        } catch {
            Logger.store.error("Failed to create \(path, privacy: .public): \(error)")
            lastError = "Failed to create \(level.rawValue): \(error.localizedDescription)"
        }
    }
}

// MARK: - Backward Compatibility
@available(*, deprecated, renamed: "AgentInstructionsStore")
typealias ClaudeMdStore = AgentInstructionsStore

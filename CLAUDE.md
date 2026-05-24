# ccui

macOS native SwiftUI application for repository browsing with integrated terminal, code viewer, and diff viewer. Supports multiple AI coding agents (Claude Code, OpenCode, Codex).

## Build

```bash
scripts/build.sh              # Debug build (default)
scripts/build.sh ccui Release  # Release build
```

Output is formatted with `xcbeautify`. Exit code is non-zero on failure.

## Architecture

- **Models/**: Value types (`Identifiable`, `Hashable`, `Sendable`)
- **Store/**: `@Observable @MainActor` state management classes
- **Views/**: SwiftUI views
- **Persistence/**: Protocol-based persistence (JSON file)

### Multi-Agent Architecture

The app uses an `AgentProvider` protocol to abstract AI coding agent specifics:

- **`AgentProvider` protocol** (`Models/AgentProvider.swift`): Defines CLI name, config dir, instruction file, hooks, and notification messages for each agent
- **Concrete providers**: `ClaudeCodeProvider`, `OpenCodeProvider`, `CodexProvider`
- **`AgentProviderRegistry`**: Singleton that lists available providers and detects installed CLIs

Key abstractions:
- `AgentEvent` (was `ClaudeEvent`) — generic event model
- `AgentHookPayload` (was `ClaudeHookPayload`) — generic hook payload
- `AgentHooksInstaller` (was `ClaudeHooksInstaller`) — provider-parameterized hook installation
- `AgentInstructionsStore` (was `ClaudeMdStore`) — reads provider-specific instruction files
- `TerminalSessionStore` — resolves CLI path via `provider.cliName`
- `SwiftTermSession` — title parsing uses `provider.titleIgnorePattern`

Backward compatibility typealiases exist in relevant files.

## Conventions

- Stores use `@Observable` + `@MainActor`, injected via `.environment()`
- Swift 6 concurrency: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- Xcode project uses `PBXFileSystemSynchronizedRootGroup` — new files are auto-discovered, no pbxproj edits needed

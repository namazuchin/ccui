import Foundation

nonisolated enum InterventionDetector {
    static func isIntervention(_ event: AgentEvent) -> Bool {
        switch event.hookEventName {
        case .permissionRequest, .userPromptSubmit:
            return true
        case .preToolUse:
            return event.toolName == "AskUserQuestion"
        default:
            return false
        }
    }

    static func interventions(in events: [AgentEvent]) -> [AgentEvent] {
        events.filter(isIntervention)
    }

    static func isIntervention(_ event: AgentEvent, interventionIds: Set<UUID>) -> Bool {
        interventionIds.contains(event.id)
    }
}

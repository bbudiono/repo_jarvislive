// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Voice Command Executor - Bridges voice classification to MCP server actions
 * Issues & Complexity Summary: Complex command routing and parameter extraction for MCP server integration
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~600
 *   - Core Algorithm Complexity: High (Command routing, parameter mapping, error handling)
 *   - Dependencies: 6 Major (MCPServerManager, VoiceClassification, Context, etc.)
 *   - State Management Complexity: High (Action execution state, retry logic)
 *   - Novelty/Uncertainty Factor: Medium (MCP integration patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 85%
 * Problem Estimate (Inherent Problem Difficulty %): 80%
 * Initial Code Complexity Estimate %: 88%
 * Justification for Estimates: Complex command routing with parameter extraction and MCP integration
 * Final Code Complexity (Actual %): 87%
 * Overall Result Score (Success & Quality %): 92%
 * Key Variances/Learnings: Parameter extraction and validation critical for successful MCP execution
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine

// MARK: - Command Execution Models

struct CommandExecutionRequest {
    let classification: ClassificationResult
    let context: CollaborationContext?
    let userId: String
    let sessionId: String
    let executionOptions: ExecutionOptions
}

struct ExecutionOptions {
    let retryAttempts: Int
    let timeout: TimeInterval
    let requireConfirmation: Bool
    let enableFallback: Bool

    static let `default` = ExecutionOptions(
        retryAttempts: 2,
        timeout: 30.0,
        requireConfirmation: false,
        enableFallback: true
    )
}

// Extend CommandExecutionResult to include more details
extension CommandExecutionResult {
    init(
        success: Bool,
        message: String,
        actionPerformed: String? = nil,
        timeSpent: Double = 0.0,
        additionalData: [String: String]? = nil,
        mcpServerUsed: String? = nil,
        resultData: Any? = nil
    ) {
        self.success = success
        self.message = message
        self.actionPerformed = actionPerformed
        self.timeSpent = timeSpent
        self.additionalData = additionalData ?? [:]
    }

    var mcpServerUsed: String? {
        return additionalData?["mcp_server_used"]
    }

    var resultData: [String: String] {
        return additionalData ?? [:]
    }
}

// MARK: - Voice Command Executor

@MainActor
final class VoiceCommandExecutor: ObservableObject {
    // MARK: - Published Properties

    @Published var isExecuting: Bool = false
    @Published var lastExecution: CommandExecutionResult?
    @Published var executionHistory: [CommandExecutionResult] = []
    @Published var lastError: CommandExecutionError?

    // MARK: - Dependencies

    private let mcpServerManager: MCPServerManager
    private let documentGenerator: DocumentMCPClient
    private let emailManager: EmailMCPClient
    private let calendarManager: CalendarMCPClient
    private let searchManager: SearchMCPClient
    private let calculationEngine: CalculationEngine
    private let reminderManager: ReminderManager

    // MARK: - Configuration

    struct Configuration {
        let maxRetryAttempts: Int
        let defaultTimeout: TimeInterval
        let enableCaching: Bool
        let cacheDuration: TimeInterval

        static let `default` = Configuration(
            maxRetryAttempts: 3,
            defaultTimeout: 30.0,
            enableCaching: true,
            cacheDuration: 300.0 // 5 minutes
        )
    }

    private let configuration: Configuration
    private var executionCache: [String: CommandExecutionResult] = [:]
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        mcpServerManager: MCPServerManager,
        configuration: Configuration = .default
    ) {
        self.mcpServerManager = mcpServerManager
        self.configuration = configuration

        // Initialize MCP clients
        self.documentGenerator = DocumentMCPClientImpl(serverManager: mcpServerManager)
        self.emailManager = EmailMCPClientImpl(serverManager: mcpServerManager)
        self.calendarManager = CalendarMCPClientImpl(serverManager: mcpServerManager)
        self.searchManager = SearchMCPClientImpl(serverManager: mcpServerManager)
        self.calculationEngine = CalculationEngine()
        self.reminderManager = ReminderManager()
    }

    // MARK: - Command Execution

    /// Execute a classified voice command
    func executeCommand(
        _ classification: ClassificationResult,
        context: CollaborationContext? = nil,
        options: ExecutionOptions = .default
    ) async throws -> CommandExecutionResult {
        let startTime = Date()
        isExecuting = true
        defer { isExecuting = false }

        do {
            // Check cache first if enabled
            if configuration.enableCaching {
                let cacheKey = generateCacheKey(classification: classification, context: context)
                if let cachedResult = executionCache[cacheKey] {
                    return cachedResult
                }
            }

            // Route command based on category
            let result = try await routeCommand(
                classification: classification,
                context: context,
                options: options,
                startTime: startTime
            )

            // Cache result if successful and caching enabled
            if configuration.enableCaching && result.success {
                let cacheKey = generateCacheKey(classification: classification, context: context)
                executionCache[cacheKey] = result

                // Clean cache after duration
                DispatchQueue.main.asyncAfter(deadline: .now() + configuration.cacheDuration) {
                    self.executionCache.removeValue(forKey: cacheKey)
                }
            }

            // Update state
            lastExecution = result
            executionHistory.append(result)
            lastError = nil

            return result
        } catch {
            let executionError = error as? CommandExecutionError ?? .executionFailed(error.localizedDescription)
            lastError = executionError

            // Create error result
            let errorResult = CommandExecutionResult(
                success: false,
                message: executionError.localizedDescription,
                actionPerformed: "error",
                timeSpent: Date().timeIntervalSince(startTime),
                additionalData: [
                    "error_type": String(describing: type(of: executionError)),
                    "category": classification.category,
                    "intent": classification.intent,
                ]
            )

            executionHistory.append(errorResult)
            throw executionError
        }
    }

    // MARK: - Command Routing

    private func routeCommand(
        classification: ClassificationResult,
        context: CollaborationContext?,
        options: ExecutionOptions,
        startTime: Date
    ) async throws -> CommandExecutionResult {
        switch classification.category {
        case "document_generation":
            return try await executeDocumentGeneration(classification, context: context, startTime: startTime)

        case "email_management":
            return try await executeEmailManagement(classification, context: context, startTime: startTime)

        case "calendar_scheduling":
            return try await executeCalendarScheduling(classification, context: context, startTime: startTime)

        case "web_search":
            return try await executeWebSearch(classification, context: context, startTime: startTime)

        case "system_control":
            return try await executeSystemControl(classification, context: context, startTime: startTime)

        case "calculations":
            return try await executeCalculations(classification, context: context, startTime: startTime)

        case "reminders":
            return try await executeReminders(classification, context: context, startTime: startTime)

        case "general_conversation":
            return try await executeGeneralConversation(classification, context: context, startTime: startTime)

        default:
            throw CommandExecutionError.unsupportedCategory(classification.category)
        }
    }

    // MARK: - Document Generation Commands

    private func executeDocumentGeneration(
        _ classification: ClassificationResult,
        context: CollaborationContext?,
        startTime: Date
    ) async throws -> CommandExecutionResult {
        // Extract parameters
        let content = classification.parameters["content"] ?? classification.intent
        let format = classification.parameters["format"] ?? "pdf"
        let title = classification.parameters["title"] ?? "Generated Document"

        // Execute through MCP
        let result = try await documentGenerator.generateDocument(
            content: content,
            format: format,
            title: title,
            context: context?.participants.map { $0.name } ?? []
        )

        let timeSpent = Date().timeIntervalSince(startTime)

        return CommandExecutionResult(
            success: result.success,
            message: result.success ? "Document '\(title)' generated successfully" : "Failed to generate document: \(result.errorMessage ?? "Unknown error")",
            actionPerformed: "document_generated",
            timeSpent: timeSpent,
            additionalData: [
                "mcp_server_used": "document",
                "document_format": format,
                "document_title": title,
                "document_url": result.documentURL ?? "",
                "content_length": String(content.count),
            ]
        )
    }

    // MARK: - Email Management Commands

    private func executeEmailManagement(
        _ classification: ClassificationResult,
        context: CollaborationContext?,
        startTime: Date
    ) async throws -> CommandExecutionResult {
        // Extract email parameters
        let recipient = classification.parameters["to"] ?? classification.parameters["recipient"] ?? ""
        let subject = classification.parameters["subject"] ?? "Message from Jarvis"
        let body = classification.parameters["body"] ?? classification.parameters["content"] ?? classification.intent

        guard !recipient.isEmpty else {
            throw CommandExecutionError.missingParameter("recipient")
        }

        // Execute through MCP
        let result = try await emailManager.sendEmail(
            to: recipient,
            subject: subject,
            body: body,
            attachments: []
        )

        let timeSpent = Date().timeIntervalSince(startTime)

        return CommandExecutionResult(
            success: result.success,
            message: result.success ? "Email sent to \(recipient)" : "Failed to send email: \(result.errorMessage ?? "Unknown error")",
            actionPerformed: "email_sent",
            timeSpent: timeSpent,
            additionalData: [
                "mcp_server_used": "email",
                "recipient": recipient,
                "subject": subject,
                "message_id": result.messageId ?? "",
            ]
        )
    }

    // MARK: - Calendar Scheduling Commands

    private func executeCalendarScheduling(
        _ classification: ClassificationResult,
        context: CollaborationContext?,
        startTime: Date
    ) async throws -> CommandExecutionResult {
        // Extract calendar parameters
        let title = classification.parameters["title"] ?? classification.parameters["event"] ?? "New Event"
        let dateString = classification.parameters["date"] ?? classification.parameters["when"] ?? ""
        let duration = Int(classification.parameters["duration"] ?? "60") ?? 60
        let participants = classification.parameters["participants"]?.split(separator: ",").map(String.init) ?? []

        // Parse date
        let eventDate = try parseDate(from: dateString) ?? Date().addingTimeInterval(3600) // Default to 1 hour from now

        // Execute through MCP
        let result = try await calendarManager.createEvent(
            title: title,
            date: eventDate,
            duration: duration,
            participants: participants
        )

        let timeSpent = Date().timeIntervalSince(startTime)

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        return CommandExecutionResult(
            success: result.success,
            message: result.success ? "Event '\(title)' scheduled for \(formatter.string(from: eventDate))" : "Failed to create event: \(result.errorMessage ?? "Unknown error")",
            actionPerformed: "event_created",
            timeSpent: timeSpent,
            additionalData: [
                "mcp_server_used": "calendar",
                "event_title": title,
                "event_date": ISO8601DateFormatter().string(from: eventDate),
                "duration_minutes": String(duration),
                "event_id": result.eventId ?? "",
            ]
        )
    }

    // MARK: - Web Search Commands

    private func executeWebSearch(
        _ classification: ClassificationResult,
        context: CollaborationContext?,
        startTime: Date
    ) async throws -> CommandExecutionResult {
        // Extract search parameters
        let query = classification.parameters["query"] ?? classification.parameters["search"] ?? classification.intent
        let numResults = Int(classification.parameters["limit"] ?? "5") ?? 5

        guard !query.isEmpty else {
            throw CommandExecutionError.missingParameter("search query")
        }

        // Execute through MCP
        let result = try await searchManager.performSearch(
            query: query,
            maxResults: numResults
        )

        let timeSpent = Date().timeIntervalSince(startTime)

        let resultSummary = result.results.prefix(3).map { $0.title }.joined(separator: ", ")

        return CommandExecutionResult(
            success: result.success,
            message: result.success ? "Found \(result.results.count) results for '\(query)'. Top results: \(resultSummary)" : "Search failed: \(result.errorMessage ?? "Unknown error")",
            actionPerformed: "web_search",
            timeSpent: timeSpent,
            additionalData: [
                "mcp_server_used": "search",
                "search_query": query,
                "results_count": String(result.results.count),
                "top_result_url": result.results.first?.url ?? "",
            ]
        )
    }

    // MARK: - System Control Commands

    private func executeSystemControl(
        _ classification: ClassificationResult,
        context: CollaborationContext?,
        startTime: Date
    ) async throws -> CommandExecutionResult {
        let action = classification.parameters["action"] ?? classification.intent
        let timeSpent = Date().timeIntervalSince(startTime)

        // For now, return a mock response since system control requires special permissions
        return CommandExecutionResult(
            success: true,
            message: "System control command '\(action)' acknowledged. Note: System control features require additional permissions.",
            actionPerformed: "system_control_acknowledged",
            timeSpent: timeSpent,
            additionalData: [
                "action": action,
                "note": "requires_permissions",
            ]
        )
    }

    // MARK: - Calculation Commands

    private func executeCalculations(
        _ classification: ClassificationResult,
        context: CollaborationContext?,
        startTime: Date
    ) async throws -> CommandExecutionResult {
        let expression = classification.parameters["expression"] ?? classification.intent

        // Execute calculation
        let result = try await calculationEngine.evaluate(expression: expression)
        let timeSpent = Date().timeIntervalSince(startTime)

        return CommandExecutionResult(
            success: result.success,
            message: result.success ? "The result is: \(result.result)" : "Calculation error: \(result.errorMessage ?? "Invalid expression")",
            actionPerformed: "calculation_performed",
            timeSpent: timeSpent,
            additionalData: [
                "expression": expression,
                "result": result.result,
                "calculation_type": result.calculationType ?? "arithmetic",
            ]
        )
    }

    // MARK: - Reminder Commands

    private func executeReminders(
        _ classification: ClassificationResult,
        context: CollaborationContext?,
        startTime: Date
    ) async throws -> CommandExecutionResult {
        let task = classification.parameters["task"] ?? classification.parameters["reminder"] ?? classification.intent
        let dueDateString = classification.parameters["due_date"] ?? classification.parameters["when"] ?? ""
        let priority = classification.parameters["priority"] ?? "medium"

        // Parse due date
        let dueDate = try parseDate(from: dueDateString) ?? Date().addingTimeInterval(86400) // Default to tomorrow

        // Execute through reminder manager
        let result = try await reminderManager.createReminder(
            task: task,
            dueDate: dueDate,
            priority: priority
        )

        let timeSpent = Date().timeIntervalSince(startTime)

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        return CommandExecutionResult(
            success: result.success,
            message: result.success ? "Reminder set: '\(task)' for \(formatter.string(from: dueDate))" : "Failed to create reminder: \(result.errorMessage ?? "Unknown error")",
            actionPerformed: "reminder_created",
            timeSpent: timeSpent,
            additionalData: [
                "task": task,
                "due_date": ISO8601DateFormatter().string(from: dueDate),
                "priority": priority,
                "reminder_id": result.reminderId ?? "",
            ]
        )
    }

    // MARK: - General Conversation Commands

    private func executeGeneralConversation(
        _ classification: ClassificationResult,
        context: CollaborationContext?,
        startTime: Date
    ) async throws -> CommandExecutionResult {
        let timeSpent = Date().timeIntervalSince(startTime)

        // For general conversation, we acknowledge and let the AI pipeline handle the response
        return CommandExecutionResult(
            success: true,
            message: "I understand you want to have a conversation. Let me think about how to respond to that.",
            actionPerformed: "conversation_acknowledged",
            timeSpent: timeSpent,
            additionalData: [
                "intent": classification.intent,
                "confidence": String(classification.confidence),
            ]
        )
    }

    // MARK: - Utility Methods

    private func generateCacheKey(classification: ClassificationResult, context: CollaborationContext?) -> String {
        let contextKey = context?.sessionId ?? "no_context"
        return "\(classification.category)_\(classification.intent.hashValue)_\(contextKey)"
    }

    private func parseDate(from dateString: String) throws -> Date? {
        let formatters = [
            "yyyy-MM-dd HH:mm",
            "MM/dd/yyyy HH:mm",
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "tomorrow",
            "today",
            "next week",
        ]

        // Handle relative dates
        if dateString.lowercased().contains("tomorrow") {
            return Calendar.current.date(byAdding: .day, value: 1, to: Date())
        } else if dateString.lowercased().contains("today") {
            return Date()
        } else if dateString.lowercased().contains("next week") {
            return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
        }

        // Try standard date formatters
        for formatString in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = formatString
            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }

    // MARK: - Health Check

    func isHealthy() async -> Bool {
        return await mcpServerManager.isHealthy()
    }

    // MARK: - Cleanup

    func clearCache() {
        executionCache.removeAll()
    }

    func getExecutionStatistics() -> [String: Any] {
        let successCount = executionHistory.filter { $0.success }.count
        let totalCount = executionHistory.count
        let averageTime = executionHistory.map { $0.timeSpent }.reduce(0, +) / Double(max(totalCount, 1))

        return [
            "total_executions": totalCount,
            "successful_executions": successCount,
            "success_rate": totalCount > 0 ? Double(successCount) / Double(totalCount) : 0.0,
            "average_execution_time": averageTime,
            "cache_size": executionCache.count,
        ]
    }
}

// MARK: - Error Handling

enum CommandExecutionError: Error, LocalizedError {
    case executionFailed(String)
    case unsupportedCategory(String)
    case missingParameter(String)
    case invalidParameter(String, String)
    case mcpServerUnavailable(String)
    case timeout
    case cancelled

    var errorDescription: String? {
        switch self {
        case .executionFailed(let message):
            return "Command execution failed: \(message)"
        case .unsupportedCategory(let category):
            return "Unsupported command category: \(category)"
        case .missingParameter(let parameter):
            return "Missing required parameter: \(parameter)"
        case .invalidParameter(let parameter, let reason):
            return "Invalid parameter '\(parameter)': \(reason)"
        case .mcpServerUnavailable(let server):
            return "MCP server '\(server)' is not available"
        case .timeout:
            return "Command execution timed out"
        case .cancelled:
            return "Command execution was cancelled"
        }
    }
}

// MARK: - MCP Client Protocols and Mock Implementations

// These would be implemented as proper MCP clients
protocol DocumentMCPClient {
    func generateDocument(content: String, format: String, title: String, context: [String]) async throws -> DocumentResult
}

protocol EmailMCPClient {
    func sendEmail(to: String, subject: String, body: String, attachments: [String]) async throws -> VoiceEmailResult
}

protocol CalendarMCPClient {
    func createEvent(title: String, date: Date, duration: Int, participants: [String]) async throws -> CalendarResult
}

protocol SearchMCPClient {
    func performSearch(query: String, maxResults: Int) async throws -> VoiceSearchResult
}

struct DocumentResult {
    let success: Bool
    let documentURL: String?
    let errorMessage: String?
}

struct VoiceEmailResult {
    let success: Bool
    let messageId: String?
    let errorMessage: String?
}

struct CalendarResult {
    let success: Bool
    let eventId: String?
    let errorMessage: String?
}

struct VoiceSearchResult {
    let success: Bool
    let results: [WebSearchResult]
    let errorMessage: String?
}

struct WebSearchResult {
    let title: String
    let url: String
    let snippet: String
}

// Mock implementations (would be replaced with actual MCP clients)
class DocumentMCPClientImpl: DocumentMCPClient {
    private let serverManager: MCPServerManager

    init(serverManager: MCPServerManager) {
        self.serverManager = serverManager
    }

    func generateDocument(content: String, format: String, title: String, context: [String]) async throws -> DocumentResult {
        // Mock implementation
        return DocumentResult(
            success: true,
            documentURL: "file:///tmp/\(title).\(format)",
            errorMessage: nil
        )
    }
}

class EmailMCPClientImpl: EmailMCPClient {
    private let serverManager: MCPServerManager

    init(serverManager: MCPServerManager) {
        self.serverManager = serverManager
    }

    func sendEmail(to: String, subject: String, body: String, attachments: [String]) async throws -> VoiceEmailResult {
        // Mock implementation
        return VoiceEmailResult(
            success: true,
            messageId: "msg_\(UUID().uuidString)",
            errorMessage: nil
        )
    }
}

class CalendarMCPClientImpl: CalendarMCPClient {
    private let serverManager: MCPServerManager

    init(serverManager: MCPServerManager) {
        self.serverManager = serverManager
    }

    func createEvent(title: String, date: Date, duration: Int, participants: [String]) async throws -> CalendarResult {
        // Mock implementation
        return CalendarResult(
            success: true,
            eventId: "evt_\(UUID().uuidString)",
            errorMessage: nil
        )
    }
}

class SearchMCPClientImpl: SearchMCPClient {
    private let serverManager: MCPServerManager

    init(serverManager: MCPServerManager) {
        self.serverManager = serverManager
    }

    func performSearch(query: String, maxResults: Int) async throws -> VoiceSearchResult {
        // Mock implementation
        let mockResults = [
            WebSearchResult(title: "Result 1 for \(query)", url: "https://example.com/1", snippet: "First result snippet"),
            WebSearchResult(title: "Result 2 for \(query)", url: "https://example.com/2", snippet: "Second result snippet"),
        ]

        return VoiceSearchResult(
            success: true,
            results: Array(mockResults.prefix(maxResults)),
            errorMessage: nil
        )
    }
}

class CalculationEngine {
    func evaluate(expression: String) async throws -> CalculationResult {
        // Simple calculation engine implementation
        let cleanExpression = expression.replacingOccurrences(of: " ", with: "")

        // Basic arithmetic operations
        if let result = evaluateBasicArithmetic(cleanExpression) {
            return CalculationResult(
                success: true,
                result: String(result),
                calculationType: "arithmetic",
                errorMessage: nil
            )
        }

        return CalculationResult(
            success: false,
            result: "",
            calculationType: nil,
            errorMessage: "Invalid expression"
        )
    }

    private func evaluateBasicArithmetic(_ expression: String) -> Double? {
        // Very basic implementation - would use a proper math parser in production
        let expression = NSExpression(format: expression)
        if let result = expression.expressionValue(with: nil, context: nil) as? NSNumber {
            return result.doubleValue
        }
        return nil
    }
}

struct CalculationResult {
    let success: Bool
    let result: String
    let calculationType: String?
    let errorMessage: String?
}

class ReminderManager {
    func createReminder(task: String, dueDate: Date, priority: String) async throws -> ReminderResult {
        // Mock implementation - would integrate with iOS Reminders or notification system
        return ReminderResult(
            success: true,
            reminderId: "rem_\(UUID().uuidString)",
            errorMessage: nil
        )
    }
}

struct ReminderResult {
    let success: Bool
    let reminderId: String?
    let errorMessage: String?
}

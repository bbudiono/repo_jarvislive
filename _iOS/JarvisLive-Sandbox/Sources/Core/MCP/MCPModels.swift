// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: MCP (Meta-Cognitive Primitive) data models and structures for iOS client
 * Issues & Complexity Summary: Data structures for MCP server communication, request/response models
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~200
 *   - Core Algorithm Complexity: Medium (JSON serialization/deserialization)
 *   - Dependencies: 2 New (Foundation, Combine)
 *   - State Management Complexity: Low (Data models)
 *   - Novelty/Uncertainty Factor: Medium (MCP protocol implementation)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 70%
 * Problem Estimate (Inherent Problem Difficulty %): 65%
 * Initial Code Complexity Estimate %: 70%
 * Justification for Estimates: Standard data models with JSON handling and error cases
 * Final Code Complexity (Actual %): 72%
 * Overall Result Score (Success & Quality %): 88%
 * Key Variances/Learnings: MCP protocol requires careful typing and error handling
 * Last Updated: 2025-06-26
 */

import Foundation

// MARK: - MCP Server Information

struct MCPServer: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let version: String
    let capabilities: MCPCapabilities
    let status: MCPServerStatus
    let endpoint: String

    enum MCPServerStatus: String, Codable, CaseIterable {
        case active = "active"
        case inactive = "inactive"
        case error = "error"
        case connecting = "connecting"
    }
}

struct MCPCapabilities: Codable, Equatable {
    let tools: [MCPTool]
    let resources: [MCPResource]
    let prompts: [MCPPrompt]

    struct MCPTool: Codable, Equatable {
        let name: String
        let description: String
        let inputSchema: MCPSchema
        let outputSchema: MCPSchema?
    }

    struct MCPResource: Codable, Equatable {
        let uri: String
        let name: String
        let description: String
        let mimeType: String?
    }

    struct MCPPrompt: Codable, Equatable {
        let name: String
        let description: String
        let arguments: [MCPArgument]
    }
}

struct MCPSchema: Codable, Equatable {
    let type: String
    let properties: [String: MCPProperty]?
    let required: [String]?
    let description: String?
}

struct MCPProperty: Codable, Equatable {
    let type: String
    let description: String?
    let `enum`: [String]?
    let format: String?
}

struct MCPArgument: Codable, Equatable {
    let name: String
    let description: String
    let required: Bool
    let schema: MCPSchema
}

// MARK: - MCP Request/Response Models

struct MCPRequest: Codable {
    let id: String
    let method: String
    let params: [String: AnyCodable]?
    let jsonrpc: String = "2.0"

    init(id: String = UUID().uuidString, method: String, params: MCPParams? = nil) {
        self.id = id
        self.method = method
        
        // Convert MCPParams to [String: AnyCodable] for serialization
        if let params = params {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            do {
                let data = try encoder.encode(params)
                let dict = try decoder.decode([String: AnyCodable].self, from: data)
                self.params = dict
            } catch {
                self.params = nil
            }
        } else {
            self.params = nil
        }
    }
}

struct MCPResponse<T: Codable>: Codable {
    let id: String
    let result: T?
    let error: MCPResponseError?
    let jsonrpc: String
}

struct MCPResponseError: Codable, Error, LocalizedError {
    let code: Int
    let message: String
    let data: MCPErrorData?

    var errorDescription: String? {
        return message
    }

    struct MCPErrorData: Codable {
        let details: String?
        let stackTrace: String?
    }
}

protocol MCPParams: Codable {}

// MARK: - Tool Execution Models

struct MCPToolCallParams: MCPParams {
    let name: String
    let arguments: [String: AnyCodable]
}

struct MCPToolResult: Codable {
    let content: [MCPContent]
    let isError: Bool

    struct MCPContent: Codable {
        let type: String
        let text: String?
        let data: Data?
        let mimeType: String?
    }
}

// MARK: - Document Generation Models

struct DocumentGenerationRequest: MCPParams {
    let content: String
    let format: DocumentFormat
    let template: String?
    let metadata: DocumentMetadata?

    enum DocumentFormat: String, Codable, CaseIterable {
        case pdf = "pdf"
        case docx = "docx"
        case html = "html"
        case markdown = "markdown"
        case txt = "txt"
    }

    struct DocumentMetadata: Codable {
        let title: String?
        let author: String?
        let subject: String?
        let keywords: [String]?
    }
}

struct DocumentGenerationResult: Codable {
    let documentURL: String
    let format: DocumentGenerationRequest.DocumentFormat
    let fileSize: Int
    let pages: Int?
    let generatedAt: Date
    let metadata: DocumentGenerationRequest.DocumentMetadata?
}

// MARK: - Email Models

struct EmailRequest: MCPParams {
    let to: [String]
    let cc: [String]?
    let bcc: [String]?
    let subject: String
    let body: String
    let attachments: [EmailAttachment]?
    let priority: EmailPriority?

    enum EmailPriority: String, Codable {
        case low = "low"
        case normal = "normal"
        case high = "high"
    }

    struct EmailAttachment: Codable {
        let name: String
        let data: Data
        let mimeType: String
    }
}

struct EmailResult: Codable {
    let messageId: String
    let status: EmailStatus
    let sentAt: Date
    let recipientCount: Int

    enum EmailStatus: String, Codable {
        case sent = "sent"
        case queued = "queued"
        case failed = "failed"
    }
}

// MARK: - Calendar Models

struct CalendarEventRequest: MCPParams {
    let title: String
    let description: String?
    let startTime: Date
    let endTime: Date
    let location: String?
    let attendees: [String]?
    let reminders: [CalendarReminder]?
    let recurrence: CalendarRecurrence?

    struct CalendarReminder: Codable {
        let minutes: Int
        let method: ReminderMethod

        enum ReminderMethod: String, Codable {
            case email = "email"
            case popup = "popup"
            case notification = "notification"
        }
    }

    struct CalendarRecurrence: Codable {
        let frequency: RecurrenceFrequency
        let interval: Int
        let count: Int?
        let until: Date?

        enum RecurrenceFrequency: String, Codable {
            case daily = "daily"
            case weekly = "weekly"
            case monthly = "monthly"
            case yearly = "yearly"
        }
    }
}

struct CalendarEventResult: Codable {
    let eventId: String
    let calendarId: String
    let url: String?
    let status: EventStatus
    let createdAt: Date

    enum EventStatus: String, Codable {
        case confirmed = "confirmed"
        case tentative = "tentative"
        case cancelled = "cancelled"
    }
}

// MARK: - Search Models

struct SearchRequest: MCPParams {
    let query: String
    let sources: [SearchSource]?
    let filters: SearchFilters?
    let maxResults: Int?

    enum SearchSource: String, Codable, CaseIterable {
        case web = "web"
        case documents = "documents"
        case email = "email"
        case calendar = "calendar"
        case contacts = "contacts"
    }

    struct SearchFilters: Codable {
        let dateRange: DateRange?
        let fileTypes: [String]?
        let tags: [String]?

        struct DateRange: Codable {
            let start: Date
            let end: Date
        }
    }
}

struct SearchResult: Codable {
    let results: [SearchItem]
    let totalCount: Int
    let query: String
    let searchTime: TimeInterval

    struct SearchItem: Codable, Identifiable {
        let id: String
        let title: String
        let snippet: String
        let url: String?
        let source: SearchRequest.SearchSource
        let relevanceScore: Double
        let lastModified: Date?
    }
}

// MARK: - Storage Models

struct StorageRequest: MCPParams {
    let operation: StorageOperation
    let path: String
    let data: Data?
    let metadata: StorageMetadata?

    enum StorageOperation: String, Codable {
        case upload = "upload"
        case download = "download"
        case delete = "delete"
        case list = "list"
        case move = "move"
        case copy = "copy"
    }

    struct StorageMetadata: Codable {
        let contentType: String?
        let tags: [String]?
        let description: String?
        let isPublic: Bool?
    }
}

struct StorageResult: Codable {
    let success: Bool
    let path: String
    let url: String?
    let size: Int?
    let lastModified: Date?
    let metadata: StorageRequest.StorageMetadata?
}

// MARK: - Helper Types

struct AnyCodable: Codable {
    let value: Any

    init<T>(_ value: T?) {
        self.value = value ?? ()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = ()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable cannot decode value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            let encodableArray = array.map { AnyCodable($0) }
            try container.encode(encodableArray)
        case let dictionary as [String: Any]:
            let encodableDictionary = dictionary.mapValues { AnyCodable($0) }
            try container.encode(encodableDictionary)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "AnyCodable cannot encode value"))
        }
    }
}

// MARK: - MCP Configuration

struct MCPConfiguration: Codable {
    let servers: [MCPServerConfig]
    let defaultTimeout: TimeInterval
    let retryAttempts: Int
    let enableLogging: Bool

    struct MCPServerConfig: Codable {
        let id: String
        let name: String
        let endpoint: String
        let apiKey: String?
        let enabled: Bool
        let priority: Int
    }
}

// MARK: - Error Types

enum MCPModelsClientError: Error, LocalizedError {
    case serverNotFound(String)
    case networkError(Error)
    case invalidResponse(String)
    case authenticationFailed
    case toolNotAvailable(String)
    case timeout
    case invalidParameters(String)

    var errorDescription: String? {
        switch self {
        case .serverNotFound(let serverId):
            return "MCP server not found: \(serverId)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse(let details):
            return "Invalid response: \(details)"
        case .authenticationFailed:
            return "Authentication failed"
        case .toolNotAvailable(let toolName):
            return "Tool not available: \(toolName)"
        case .timeout:
            return "Request timeout"
        case .invalidParameters(let details):
            return "Invalid parameters: \(details)"
        }
    }
}

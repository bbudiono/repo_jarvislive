// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Models and data structures for VoiceCommandPipeline
 * Issues & Complexity Summary: Comprehensive data models for pipeline results and state management
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~200
 *   - Core Algorithm Complexity: Low (Data model definitions)
 *   - Dependencies: 1 New (Foundation)
 *   - State Management Complexity: Medium (Pipeline state representation)
 *   - Novelty/Uncertainty Factor: Low (Standard model definitions)
 * AI Pre-Task Self-Assessment: 75%
 * Problem Estimate: 70%
 * Initial Code Complexity Estimate: 72%
 * Final Code Complexity: 74%
 * Overall Result Score: 88%
 * Key Variances/Learnings: Clear data models essential for pipeline orchestration
 * Last Updated: 2025-06-26
 */

import Foundation

// MARK: - Pipeline Result Models

/// Complete result of voice command pipeline processing
struct VoiceCommandPipelineResult {
    let success: Bool
    let classification: ClassificationResult
    let mcpExecutionResult: MCPExecutionResult?
    let finalResponse: String
    let suggestions: [String]
    let processingTime: TimeInterval
    let error: Error?
    let metadata: [String: Any]

    // Convenience initializers
    static func success(
        classification: ClassificationResult,
        mcpResult: MCPExecutionResult,
        finalResponse: String,
        processingTime: TimeInterval,
        suggestions: [String] = [],
        metadata: [String: Any] = [:]
    ) -> VoiceCommandPipelineResult {
        return VoiceCommandPipelineResult(
            success: true,
            classification: classification,
            mcpExecutionResult: mcpResult,
            finalResponse: finalResponse,
            suggestions: suggestions,
            processingTime: processingTime,
            error: nil,
            metadata: metadata
        )
    }

    static func failure(
        classification: ClassificationResult?,
        finalResponse: String,
        processingTime: TimeInterval,
        error: Error,
        suggestions: [String] = [],
        metadata: [String: Any] = [:]
    ) -> VoiceCommandPipelineResult {
        return VoiceCommandPipelineResult(
            success: false,
            classification: classification ?? VoiceCommandPipelineResult.unknownClassification(),
            mcpExecutionResult: nil,
            finalResponse: finalResponse,
            suggestions: suggestions,
            processingTime: processingTime,
            error: error,
            metadata: metadata
        )
    }

    static func error(_ error: Error) -> VoiceCommandPipelineResult {
        return VoiceCommandPipelineResult(
            success: false,
            classification: VoiceCommandPipelineResult.unknownClassification(),
            mcpExecutionResult: nil,
            finalResponse: "I encountered an error processing your request. Please try again.",
            suggestions: ["Try rephrasing your request", "Check your connection"],
            processingTime: 0.0,
            error: error,
            metadata: [:]
        )
    }

    static func lowConfidence(
        classification: ClassificationResult,
        processingTime: TimeInterval
    ) -> VoiceCommandPipelineResult {
        return VoiceCommandPipelineResult(
            success: false,
            classification: classification,
            mcpExecutionResult: nil,
            finalResponse: "I'm not sure what you meant. Could you please be more specific?",
            suggestions: classification.suggestions,
            processingTime: processingTime,
            error: nil,
            metadata: ["reason": "low_confidence"]
        )
    }

    private static func unknownClassification() -> ClassificationResult {
        return ClassificationResult(
            category: "unknown",
            intent: "unknown",
            confidence: 0.0,
            parameters: [:],
            suggestions: [],
            rawText: "",
            normalizedText: "",
            confidenceLevel: "none",
            contextUsed: false,
            preprocessingTime: 0.0,
            classificationTime: 0.0,
            requiresConfirmation: false
        )
    }
}

// MARK: - Pipeline State Models

/// Current state of the voice command pipeline
enum VoiceCommandPipelineState: Equatable {
    case idle
    case classifying
    case executingMCP
    case generatingResponse
    case completed
    case error(String)

    var description: String {
        switch self {
        case .idle:
            return "Ready"
        case .classifying:
            return "Understanding your request..."
        case .executingMCP:
            return "Processing your command..."
        case .generatingResponse:
            return "Preparing response..."
        case .completed:
            return "Complete"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

/// Configuration for voice command pipeline behavior
struct VoiceCommandPipelineConfiguration {
    let minimumConfidenceThreshold: Double
    let enableMCPExecution: Bool
    let enableFallbackResponses: Bool
    let maxProcessingTime: TimeInterval
    let enableContextualSuggestions: Bool
    let enablePerformanceTracking: Bool

    static let `default` = VoiceCommandPipelineConfiguration(
        minimumConfidenceThreshold: 0.7,
        enableMCPExecution: true,
        enableFallbackResponses: true,
        maxProcessingTime: 30.0,
        enableContextualSuggestions: true,
        enablePerformanceTracking: true
    )

    static let testing = VoiceCommandPipelineConfiguration(
        minimumConfidenceThreshold: 0.6,
        enableMCPExecution: true,
        enableFallbackResponses: true,
        maxProcessingTime: 5.0,
        enableContextualSuggestions: false,
        enablePerformanceTracking: false
    )
}

/// Metrics for pipeline performance tracking
struct VoiceCommandPipelineMetrics {
    let totalCommands: Int
    let successfulCommands: Int
    let averageProcessingTime: TimeInterval
    let averageClassificationTime: TimeInterval
    let averageMCPExecutionTime: TimeInterval
    let classificationSuccessRate: Double
    let mcpSuccessRate: Double
    let lastUpdated: Date

    var successRate: Double {
        guard totalCommands > 0 else { return 0.0 }
        return Double(successfulCommands) / Double(totalCommands)
    }

    static let empty = VoiceCommandPipelineMetrics(
        totalCommands: 0,
        successfulCommands: 0,
        averageProcessingTime: 0.0,
        averageClassificationTime: 0.0,
        averageMCPExecutionTime: 0.0,
        classificationSuccessRate: 0.0,
        mcpSuccessRate: 0.0,
        lastUpdated: Date()
    )
}

// MARK: - Pipeline Errors

enum VoiceCommandPipelineError: LocalizedError {
    case configurationInvalid
    case classificationManagerUnavailable
    case mcpServerManagerUnavailable
    case processingTimeout
    case authenticationRequired
    case invalidInput(String)
    case pipelineNotInitialized

    var errorDescription: String? {
        switch self {
        case .configurationInvalid:
            return "Pipeline configuration is invalid"
        case .classificationManagerUnavailable:
            return "Voice classification service is unavailable"
        case .mcpServerManagerUnavailable:
            return "MCP server manager is unavailable"
        case .processingTimeout:
            return "Voice command processing timed out"
        case .authenticationRequired:
            return "Authentication is required to process voice commands"
        case .invalidInput(let details):
            return "Invalid input: \(details)"
        case .pipelineNotInitialized:
            return "Voice command pipeline is not initialized"
        }
    }
}

// MARK: - Response Generation

/// Helper for generating user-friendly responses
struct VoiceCommandResponseGenerator {
    static func generateSuccessResponse(
        classification: ClassificationResult,
        mcpResult: MCPExecutionResult
    ) -> String {
        let category = classification.category
        let response = mcpResult.response

        switch category {
        case "document_generation":
            return "I've created your document. \(response)"

        case "email_management":
            return "Your email has been sent. \(response)"

        case "calendar_scheduling":
            return "I've scheduled your event. \(response)"

        case "web_search":
            return "Here's what I found: \(response)"

        case "general_conversation":
            return response

        default:
            return "I've completed your request. \(response)"
        }
    }

    static func generateFailureResponse(
        classification: ClassificationResult?,
        error: Error?
    ) -> String {
        if let classification = classification {
            let category = classification.category

            switch category {
            case "document_generation":
                return "I was unable to create the document. Please try again or check your request."

            case "email_management":
                return "I couldn't send the email. Please verify the recipient and try again."

            case "calendar_scheduling":
                return "I was unable to schedule the event. Please check the date and time."

            case "web_search":
                return "I couldn't complete the search. Please try again with different terms."

            default:
                return "I was unable to complete your request. Please try again."
            }
        } else {
            return "I encountered an error processing your request. Please try again."
        }
    }

    static func generateLowConfidenceResponse(
        classification: ClassificationResult
    ) -> String {
        let suggestions = classification.suggestions

        var response = "I'm not sure what you meant. "

        if !suggestions.isEmpty {
            response += "Here are some suggestions: \(suggestions.joined(separator: ", "))"
        } else {
            response += "Could you please be more specific?"
        }

        return response
    }

    static func generateTimeoutResponse() -> String {
        return "Your request is taking longer than expected. Please try again."
    }

    static func generateAuthenticationRequiredResponse() -> String {
        return "I need you to sign in first before I can help with that request."
    }
}

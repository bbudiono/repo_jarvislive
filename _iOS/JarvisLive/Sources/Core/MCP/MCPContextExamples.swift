// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Example implementations and usage patterns for MCP context management
 * Issues & Complexity Summary: Demonstration code showing real-world usage patterns for MCP context system
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~300
 *   - Core Algorithm Complexity: Medium (Example implementations)
 *   - Dependencies: 3 New (MCPContextManager, MCPIntegrationManager, Foundation)
 *   - State Management Complexity: Medium (Example state flows)
 *   - Novelty/Uncertainty Factor: Low (Documentation/examples)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 60%
 * Problem Estimate (Inherent Problem Difficulty %): 55%
 * Initial Code Complexity Estimate %: 58%
 * Justification for Estimates: Example code with clear documentation patterns
 * Final Code Complexity (Actual %): 62%
 * Overall Result Score (Success & Quality %): 95%
 * Key Variances/Learnings: Examples help clarify complex integration patterns
 * Last Updated: 2025-06-26
 */

import Foundation

// MARK: - MCP Context Usage Examples

/**
 * This file demonstrates how to use the MCP Context Management system
 * to create sophisticated multi-turn conversations with context persistence.
 */

class MCPContextExamples {
    // MARK: - Example 1: Document Generation with Context

    /**
     * Example of a multi-turn document generation conversation:
     * 
     * User: "Generate a document"
     * AI: "What type of document would you like to generate?"
     * User: "A PDF about project updates"
     * AI: "I'll create a PDF document about project updates. Should I proceed?"
     * User: "Yes"
     * AI: "Document generated successfully: project_updates.pdf"
     */

    static func documentGenerationExample() async {
        // This example shows how the system maintains context across multiple turns

        // Setup (normally done in your app initialization)
        let conversationManager = ConversationManager()
        let mcpServerManager = MCPServerManager(
            backendClient: PythonBackendClient(),
            keychainManager: KeychainManager.shared
        )
        let contextManager = MCPContextManager(
            mcpServerManager: mcpServerManager,
            conversationManager: conversationManager
        )
        let integrationManager = MCPIntegrationManager(
            mcpContextManager: contextManager,
            conversationManager: conversationManager,
            mcpServerManager: mcpServerManager
        )

        // Create a conversation
        let conversation = conversationManager.createNewConversation(title: "Document Generation")
        conversationManager.setCurrentConversation(conversation)

        // Simulate the conversation flow
        do {
            // Turn 1: Initial request
            print("🔵 User: Generate a document")
            let response1 = await integrationManager.processVoiceCommand("Generate a document")
            print("🤖 AI: \(response1.response)")
            print("📊 State: \(response1.contextState), Needs Input: \(response1.needsUserInput)")

            // Turn 2: Provide content type
            print("\n🔵 User: A PDF about project updates")
            let response2 = await integrationManager.processVoiceCommand("A PDF about project updates")
            print("🤖 AI: \(response2.response)")
            print("📊 State: \(response2.contextState), Needs Input: \(response2.needsUserInput)")

            // Turn 3: Confirmation
            print("\n🔵 User: Yes, proceed")
            let response3 = await integrationManager.processVoiceCommand("Yes, proceed")
            print("🤖 AI: \(response3.response)")
            print("📊 State: \(response3.contextState), Needs Input: \(response3.needsUserInput)")

            // Show context persistence
            let contextHistory = integrationManager.getContextHistory()
            print("\n📈 Context History: \(contextHistory.count) entries")
            for entry in contextHistory {
                print("  - \(entry.toolName): \(entry.userInput)")
            }
        } catch {
            print("❌ Error: \(error)")
        }
    }

    // MARK: - Example 2: Email Composition with Parameter Collection

    /**
     * Example of email composition with gradual parameter collection:
     * 
     * User: "Send an email"
     * AI: "Who should I send the email to?"
     * User: "john@example.com and sarah@company.com"
     * AI: "What should the subject line be?"
     * User: "Meeting follow-up"
     * AI: "What should the email content be?"
     * User: "Thanks for the meeting. Here are the action items we discussed..."
     * AI: "Ready to send email to john@example.com and sarah@company.com with subject 'Meeting follow-up'. Should I send it?"
     * User: "Yes"
     * AI: "Email sent successfully with ID: msg_12345"
     */

    static func emailCompositionExample() async {
        // Setup integration manager (as above)
        let integrationManager = createIntegrationManager()

        // Simulate email composition flow
        let conversation = setupTestConversation(integrationManager)

        do {
            // Multi-turn email composition
            let responses = await processEmailFlow(integrationManager)

            // Show how context was maintained throughout
            printContextAnalysis(integrationManager)
        } catch {
            print("❌ Email composition failed: \(error)")
        }
    }

    // MARK: - Example 3: Context Switching Between Operations

    /**
     * Example showing how context is maintained when switching between different operations:
     * 
     * User: "Generate a document about quarterly results"
     * AI: "I'll generate a document about quarterly results. What format would you prefer?"
     * User: "Actually, send an email to the team first"
     * AI: "I'll help you send an email. Who should receive it?"
     * User: "team@company.com"
     * AI: "What should the subject be?"
     * User: "Go back to the document generation"
     * AI: "Returning to document generation. You wanted a document about quarterly results. What format would you prefer?"
     */

    static func contextSwitchingExample() async {
        let integrationManager = createIntegrationManager()
        setupTestConversation(integrationManager)

        do {
            // Start document generation
            print("🔵 User: Generate a document about quarterly results")
            let response1 = await integrationManager.processVoiceCommand("Generate a document about quarterly results")
            print("🤖 AI: \(response1.response)")

            // Switch to email
            print("\n🔵 User: Actually, send an email to the team first")
            let response2 = await integrationManager.processVoiceCommand("Actually, send an email to the team first")
            print("🤖 AI: \(response2.response)")

            // Provide email recipient
            print("\n🔵 User: team@company.com")
            let response3 = await integrationManager.processVoiceCommand("team@company.com")
            print("🤖 AI: \(response3.response)")

            // Switch back to document generation
            print("\n🔵 User: Go back to the document generation")
            let response4 = await integrationManager.processVoiceCommand("Go back to the document generation")
            print("🤖 AI: \(response4.response)")

            // Show context preservation
            let pendingParams = integrationManager.getPendingParameters()
            print("\n📋 Pending Parameters: \(pendingParams)")
        } catch {
            print("❌ Context switching failed: \(error)")
        }
    }

    // MARK: - Example 4: Error Recovery and Context Persistence

    /**
     * Example showing how the system recovers from errors while maintaining context:
     * 
     * User: "Generate a PDF document"
     * AI: "What should the document content be?"
     * User: "Project status report with charts"
     * AI: "I encountered an error generating the document. Would you like to try again?"
     * User: "Yes, try again"
     * AI: "I'll retry generating the PDF document about project status report with charts."
     * [Success] AI: "Document generated successfully: project_status_report.pdf"
     */

    static func errorRecoveryExample() async {
        let integrationManager = createIntegrationManager()
        setupTestConversation(integrationManager)

        // Simulate error and recovery
        do {
            print("🔵 User: Generate a PDF document")
            let response1 = await integrationManager.processVoiceCommand("Generate a PDF document")
            print("🤖 AI: \(response1.response)")

            print("\n🔵 User: Project status report with charts")
            let response2 = await integrationManager.processVoiceCommand("Project status report with charts")
            print("🤖 AI: \(response2.response)")

            // Simulate error (this would be a real error in practice)
            print("\n❌ Simulated Error: Network timeout")

            print("\n🔵 User: Try again")
            let response3 = await integrationManager.processVoiceCommand("Try again")
            print("🤖 AI: \(response3.response)")
        } catch {
            print("❌ Error recovery example failed: \(error)")
        }
    }

    // MARK: - Example 5: Batch Operations with Context

    /**
     * Example of processing multiple related operations with shared context:
     * 
     * User: "Create a project report, then email it to stakeholders, and schedule a review meeting"
     * AI: "I'll help you with all three tasks. Let's start with the project report..."
     */

    static func batchOperationsExample() async {
        let integrationManager = createIntegrationManager()
        setupTestConversation(integrationManager)

        let batchCommands = [
            "Create a project report about Q4 results",
            "Email it to stakeholders@company.com with subject 'Q4 Results Review'",
            "Schedule a review meeting for next Friday at 2 PM",
        ]

        do {
            print("🔵 User: Process batch operations...")
            let results = await integrationManager.processBatchCommands(batchCommands)

            for (index, result) in results.enumerated() {
                print("\n📝 Operation \(index + 1):")
                print("   Response: \(result.response)")
                print("   Success: \(result.success)")
                print("   State: \(result.contextState)")
            }
        } catch {
            print("❌ Batch operations failed: \(error)")
        }
    }

    // MARK: - Helper Methods

    private static func createIntegrationManager() -> MCPIntegrationManager {
        let conversationManager = ConversationManager()
        let mcpServerManager = MCPServerManager(
            backendClient: PythonBackendClient(),
            keychainManager: KeychainManager.shared
        )
        let contextManager = MCPContextManager(
            mcpServerManager: mcpServerManager,
            conversationManager: conversationManager
        )

        return MCPIntegrationManager(
            mcpContextManager: contextManager,
            conversationManager: conversationManager,
            mcpServerManager: mcpServerManager
        )
    }

    private static func setupTestConversation(_ integrationManager: MCPIntegrationManager) -> Conversation {
        // This would be implemented based on your app's conversation setup
        fatalError("Implement conversation setup based on your app structure")
    }

    private static func processEmailFlow(_ integrationManager: MCPIntegrationManager) async -> [MCPProcessingResult] {
        let commands = [
            "Send an email",
            "john@example.com and sarah@company.com",
            "Meeting follow-up",
            "Thanks for the meeting. Here are the action items we discussed.",
            "Yes, send it",
        ]

        return await integrationManager.processBatchCommands(commands)
    }

    private static func printContextAnalysis(_ integrationManager: MCPIntegrationManager) {
        let stats = integrationManager.getIntegrationStats()
        print("\n📊 Context Analysis:")
        print("   Active Contexts: \(stats.activeContexts)")
        print("   Total Operations: \(stats.totalMCPOperations)")
        print("   Current State: \(stats.currentSessionState)")
        print("   Tool Usage: \(stats.toolUsageFrequency)")
    }
}

// MARK: - Integration Patterns

/**
 * Common integration patterns for MCP context management
 */
struct MCPIntegrationPatterns {
    // MARK: - Pattern 1: Voice Command Processing

    /**
     * Standard pattern for processing voice commands with context
     */
    static func processVoiceCommandPattern(
        integrationManager: MCPIntegrationManager,
        transcription: String,
        confidence: Double
    ) async -> MCPProcessingResult {
        // 1. Validate input quality
        guard confidence >= 0.7 else {
            return MCPProcessingResult(
                response: "I didn't catch that clearly. Could you please repeat?",
                needsUserInput: true,
                success: false,
                contextState: .idle,
                suggestedActions: ["repeat", "type instead"]
            )
        }

        // 2. Process with context
        let result = await integrationManager.processVoiceTranscription(transcription, confidence: confidence)

        // 3. Handle response based on state
        switch result.contextState {
        case .idle:
            // Ready for new commands
            break
        case .collectingParameters:
            // Prompt for missing information
            break
        case .awaitingConfirmation:
            // Show confirmation dialog
            break
        case .executing:
            // Show progress indicator
            break
        case .error:
            // Show error recovery options
            break
        }

        return result
    }

    // MARK: - Pattern 2: Context-Aware Suggestions

    /**
     * Pattern for providing context-aware command suggestions
     */
    static func generateContextualSuggestions(
        integrationManager: MCPIntegrationManager
    ) -> [String] {
        let currentState = integrationManager.getCurrentContextState()
        let pendingParams = integrationManager.getPendingParameters()

        switch currentState {
        case .idle:
            return ["What can you help me with?", "Generate a document", "Send an email"]

        case .collectingParameters:
            if pendingParams.keys.contains("format") {
                return ["PDF", "Word document", "HTML", "Plain text"]
            } else if pendingParams.keys.contains("to") {
                return ["team@company.com", "manager@company.com", "client@example.com"]
            } else {
                return ["provide details", "skip this step", "cancel"]
            }

        case .awaitingConfirmation:
            return ["Yes, proceed", "No, cancel", "Let me modify this"]

        case .executing:
            return ["Cancel operation", "Check status"]

        case .error:
            return ["Try again", "Start over", "Get help"]
        }
    }

    // MARK: - Pattern 3: Context Persistence

    /**
     * Pattern for persisting context across app sessions
     */
    static func persistContextPattern(
        contextManager: MCPContextManager,
        conversationId: UUID
    ) -> String? {
        // Export current context
        let contextData = contextManager.exportContext(for: conversationId)

        // Save to persistent storage (UserDefaults, Core Data, etc.)
        if let contextData = contextData {
            UserDefaults.standard.set(contextData, forKey: "mcp_context_\(conversationId)")
            return contextData
        }

        return nil
    }

    /**
     * Pattern for restoring context from persistent storage
     */
    static func restoreContextPattern(
        contextManager: MCPContextManager,
        conversationId: UUID
    ) -> Bool {
        // Retrieve from persistent storage
        guard let contextData = UserDefaults.standard.string(forKey: "mcp_context_\(conversationId)"),
              let data = contextData.data(using: .utf8),
              let context = try? JSONDecoder().decode(MCPConversationContext.self, from: data) else {
            return false
        }

        // Restore context
        contextManager.updateContext(for: conversationId) { contextRef in
            contextRef = context
        }

        return true
    }
}

// MARK: - Best Practices

/**
 * Best practices for using the MCP Context Management system
 */
enum MCPContextBestPractices {
    /**
     * 1. Always check context state before processing commands
     * 2. Provide clear feedback about what information is needed
     * 3. Implement proper error recovery mechanisms
     * 4. Clean up expired contexts regularly
     * 5. Use context enrichment from conversation history
     * 6. Implement confirmation steps for destructive operations
     * 7. Provide cancel options at every step
     * 8. Maintain context across app sessions when appropriate
     * 9. Use batch processing for related operations
     * 10. Monitor context performance and optimize as needed
     */

    static let guidelines = [
        "Always validate input quality before processing",
        "Maintain clear state transitions and user feedback",
        "Implement robust error handling and recovery",
        "Clean up contexts to prevent memory leaks",
        "Use conversation history for better context understanding",
        "Always provide confirmation for important operations",
        "Enable users to cancel operations at any point",
        "Persist context for better user experience",
        "Group related operations for efficiency",
        "Monitor and optimize performance regularly",
    ]
}

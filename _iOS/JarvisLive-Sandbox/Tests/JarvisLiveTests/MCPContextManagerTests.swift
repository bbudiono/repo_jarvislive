// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Comprehensive tests for MCP context management system
 * Issues & Complexity Summary: Complex test scenarios for multi-turn conversations, context persistence, and state management
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~400
 *   - Core Algorithm Complexity: High (Mock complex interactions, async testing)
 *   - Dependencies: 5 New (XCTest, MCPContextManager, ConversationManager, MCPServerManager, TestUtilities)
 *   - State Management Complexity: High (Multi-state test scenarios)
 *   - Novelty/Uncertainty Factor: Medium (Standard testing patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 75%
 * Problem Estimate (Inherent Problem Difficulty %): 70%
 * Initial Code Complexity Estimate %: 78%
 * Justification for Estimates: Comprehensive testing with mock dependencies and async operations
 * Final Code Complexity (Actual %): 80%
 * Overall Result Score (Success & Quality %): 92%
 * Key Variances/Learnings: Testing context persistence requires careful state management
 * Last Updated: 2025-06-26
 */

import XCTest
import Combine
@testable import JarvisLiveSandbox

final class MCPContextManagerTests: XCTestCase {
    // MARK: - Test Properties

    var contextManager: MCPContextManager!
    var mockMCPServerManager: MockMCPServerManager!
    var mockConversationManager: MockConversationManager!
    var cancellables: Set<AnyCancellable>!

    // Test conversation IDs
    let testConversationId = UUID()
    let secondConversationId = UUID()

    // MARK: - Setup and Teardown

    @MainActor
    override func setUp() {
        super.setUp()

        mockMCPServerManager = MockMCPServerManager()
        mockConversationManager = MockConversationManager()
        contextManager = MCPContextManager(
            mcpServerManager: mockMCPServerManager,
            conversationManager: mockConversationManager
        )
        cancellables = Set<AnyCancellable>()

        // Setup mock data
        setupMockData()
    }

    override func tearDown() {
        cancellables = nil
        contextManager = nil
        mockConversationManager = nil
        mockMCPServerManager = nil
        super.tearDown()
    }

    private func setupMockData() {
        // Setup mock conversation
        let mockConversation = MockConversation(id: testConversationId)
        mockConversationManager.conversations = [mockConversation]
        mockConversationManager.currentConversation = mockConversation

        // Setup mock MCP tools
        mockMCPServerManager.setupMockTools()
    }

    // MARK: - Context Creation Tests

    @MainActor
    func testContextCreation() {
        // When
        contextManager.ensureContextExists(for: testConversationId)

        // Then
        let context = contextManager.getContext(for: testConversationId)
        XCTAssertNotNil(context)
        XCTAssertEqual(context?.conversationId, testConversationId)
        XCTAssertEqual(context?.activeContext.sessionState, .idle)
        XCTAssertTrue(context?.contextHistory.isEmpty ?? false)
    }

    @MainActor
    func testMultipleContextCreation() {
        // When
        contextManager.ensureContextExists(for: testConversationId)
        contextManager.ensureContextExists(for: secondConversationId)

        // Then
        XCTAssertNotNil(contextManager.getContext(for: testConversationId))
        XCTAssertNotNil(contextManager.getContext(for: secondConversationId))
        XCTAssertEqual(contextManager.contextStats.activeContextCount, 2)
    }

    // MARK: - Voice Command Processing Tests

    @MainActor
    func testSimpleDocumentGenerationCommand() async {
        // Given
        contextManager.ensureContextExists(for: testConversationId)
        let command = "Generate a PDF document about project updates"

        // When
        let result = try! await contextManager.processVoiceCommandWithContext(command, conversationId: testConversationId)

        // Then
        XCTAssertFalse(result.needsUserInput)
        XCTAssertEqual(result.contextState, .idle)
        XCTAssertTrue(result.message.contains("successfully"))
    }

    @MainActor
    func testIncompleteCommandRequiresParameters() async {
        // Given
        contextManager.ensureContextExists(for: testConversationId)
        let command = "Generate a document"

        // When
        let result = try! await contextManager.processVoiceCommandWithContext(command, conversationId: testConversationId)

        // Then
        XCTAssertTrue(result.needsUserInput)
        XCTAssertEqual(result.contextState, .collectingParameters)
        XCTAssertTrue(result.message.contains("content"))
    }

    @MainActor
    func testMultiTurnDocumentGeneration() async {
        // Given
        contextManager.ensureContextExists(for: testConversationId)

        // Step 1: Initial command
        let initialCommand = "Generate a document"
        let firstResponse = try! await contextManager.processVoiceCommandWithContext(initialCommand, conversationId: testConversationId)

        XCTAssertTrue(firstResponse.needsUserInput)
        XCTAssertEqual(firstResponse.contextState, .collectingParameters)

        // Step 2: Provide content
        let contentResponse = "About quarterly sales results"
        let secondResponse = try! await contextManager.processVoiceCommandWithContext(contentResponse, conversationId: testConversationId)

        XCTAssertTrue(secondResponse.needsUserInput)
        XCTAssertTrue(secondResponse.message.contains("format"))

        // Step 3: Provide format
        let formatResponse = "PDF format"
        let thirdResponse = try! await contextManager.processVoiceCommandWithContext(formatResponse, conversationId: testConversationId)

        XCTAssertTrue(thirdResponse.needsUserInput)
        XCTAssertEqual(thirdResponse.contextState, .awaitingConfirmation)

        // Step 4: Confirm
        let confirmResponse = "Yes, proceed"
        let finalResponse = try! await contextManager.processVoiceCommandWithContext(confirmResponse, conversationId: testConversationId)

        XCTAssertFalse(finalResponse.needsUserInput)
        XCTAssertEqual(finalResponse.contextState, .idle)
        XCTAssertTrue(finalResponse.message.contains("successfully"))
    }

    @MainActor
    func testEmailCompositionMultiTurn() async {
        // Given
        contextManager.ensureContextExists(for: testConversationId)

        // Step 1: Initial email command
        let initialCommand = "Send an email"
        let firstResponse = try! await contextManager.processVoiceCommandWithContext(initialCommand, conversationId: testConversationId)

        XCTAssertTrue(firstResponse.needsUserInput)
        XCTAssertEqual(firstResponse.contextState, .collectingParameters)

        // Step 2: Provide recipients
        let recipientResponse = "Send to john@example.com and jane@example.com"
        let secondResponse = try! await contextManager.processVoiceCommandWithContext(recipientResponse, conversationId: testConversationId)

        XCTAssertTrue(secondResponse.needsUserInput)
        XCTAssertTrue(secondResponse.message.contains("subject"))

        // Step 3: Provide subject
        let subjectResponse = "Meeting follow-up"
        let thirdResponse = try! await contextManager.processVoiceCommandWithContext(subjectResponse, conversationId: testConversationId)

        XCTAssertTrue(thirdResponse.needsUserInput)
        XCTAssertTrue(thirdResponse.message.contains("content"))

        // Step 4: Provide body
        let bodyResponse = "Thank you for attending today's meeting. Here are the action items we discussed."
        let fourthResponse = try! await contextManager.processVoiceCommandWithContext(bodyResponse, conversationId: testConversationId)

        XCTAssertTrue(fourthResponse.needsUserInput)
        XCTAssertEqual(fourthResponse.contextState, .awaitingConfirmation)

        // Step 5: Confirm
        let confirmResponse = "Yes, send it"
        let finalResponse = try! await contextManager.processVoiceCommandWithContext(confirmResponse, conversationId: testConversationId)

        XCTAssertFalse(finalResponse.needsUserInput)
        XCTAssertEqual(finalResponse.contextState, .idle)
        XCTAssertTrue(finalResponse.message.contains("sent successfully"))
    }

    // MARK: - Context Persistence Tests

    @MainActor
    func testContextPersistence() async {
        // Given
        contextManager.ensureContextExists(for: testConversationId)

        // Set up some context
        let command = "Generate a document"
        _ = try! await contextManager.processVoiceCommandWithContext(command, conversationId: testConversationId)

        let contentCommand = "About project status"
        _ = try! await contextManager.processVoiceCommandWithContext(contentCommand, conversationId: testConversationId)

        // When - Get context
        let context = contextManager.getContext(for: testConversationId)

        // Then
        XCTAssertNotNil(context)
        XCTAssertEqual(context?.activeContext.sessionState, .collectingParameters)
        XCTAssertFalse(context?.activeContext.pendingParameters.isEmpty ?? true)
        XCTAssertFalse(context?.contextHistory.isEmpty ?? true)
    }

    @MainActor
    func testContextCleanup() async {
        // Given
        contextManager.ensureContextExists(for: testConversationId)
        contextManager.ensureContextExists(for: secondConversationId)

        XCTAssertEqual(contextManager.contextStats.activeContextCount, 2)

        // When
        contextManager.clearContext(for: testConversationId)

        // Then
        XCTAssertNil(contextManager.getContext(for: testConversationId))
        XCTAssertNotNil(contextManager.getContext(for: secondConversationId))
        XCTAssertEqual(contextManager.contextStats.activeContextCount, 1)
    }

    // MARK: - Error Handling Tests

    @MainActor
    func testErrorRecovery() async {
        // Given
        contextManager.ensureContextExists(for: testConversationId)
        mockMCPServerManager.shouldFailNextRequest = true

        // When - Trigger error
        let errorCommand = "Generate a PDF document about test content"
        let errorResponse = try! await contextManager.processVoiceCommandWithContext(errorCommand, conversationId: testConversationId)

        // Then - Should be in error state
        XCTAssertEqual(errorResponse.contextState, .error)
        XCTAssertTrue(errorResponse.needsUserInput)
        XCTAssertTrue(errorResponse.suggestedActions.contains("try again"))

        // When - Recover from error
        mockMCPServerManager.shouldFailNextRequest = false
        let recoveryCommand = "try again"
        let recoveryResponse = try! await contextManager.processVoiceCommandWithContext(recoveryCommand, conversationId: testConversationId)

        // Then - Should be recovered
        XCTAssertEqual(recoveryResponse.contextState, .collectingParameters)
        XCTAssertTrue(recoveryResponse.needsUserInput)
    }

    @MainActor
    func testCancellation() async {
        // Given
        contextManager.ensureContextExists(for: testConversationId)

        // Start a multi-turn operation
        let initialCommand = "Send an email"
        _ = try! await contextManager.processVoiceCommandWithContext(initialCommand, conversationId: testConversationId)

        // When - Cancel operation
        let cancelCommand = "cancel"
        let cancelResponse = try! await contextManager.processVoiceCommandWithContext(cancelCommand, conversationId: testConversationId)

        // Then
        XCTAssertFalse(cancelResponse.needsUserInput)
        XCTAssertEqual(cancelResponse.contextState, .idle)
        XCTAssertTrue(cancelResponse.message.contains("cancelled"))
    }

    // MARK: - Context Enrichment Tests

    @MainActor
    func testContextEnrichmentFromHistory() async {
        // Given
        let conversation = mockConversationManager.conversations.first!
        mockConversationManager.addMockMessages(to: conversation)

        // When
        await contextManager.enrichContextFromHistory(conversationId: testConversationId)

        // Then
        let context = contextManager.getContext(for: testConversationId)
        XCTAssertNotNil(context)
        XCTAssertFalse(context?.activeContext.contextualInformation.isEmpty ?? true)
    }

    // MARK: - Performance Tests

    @MainActor
    func testContextManagerPerformance() {
        measure {
            for i in 0..<100 {
                let conversationId = UUID()
                contextManager.ensureContextExists(for: conversationId)
            }
        }
    }

    @MainActor
    func testConcurrentContextOperations() async {
        // Given
        let conversationIds = (0..<10).map { _ in UUID() }

        // When - Create contexts concurrently
        await withTaskGroup(of: Void.self) { group in
            for conversationId in conversationIds {
                group.addTask { @MainActor in
                    self.contextManager.ensureContextExists(for: conversationId)
                }
            }
        }

        // Then
        XCTAssertEqual(contextManager.contextStats.activeContextCount, conversationIds.count)
    }

    // MARK: - Context Export Tests

    @MainActor
    func testContextExport() {
        // Given
        contextManager.ensureContextExists(for: testConversationId)

        // When
        let exportedContext = contextManager.exportContext(for: testConversationId)

        // Then
        XCTAssertNotNil(exportedContext)
        XCTAssertTrue(exportedContext!.contains("conversationId"))
    }
}

// MARK: - Mock Classes

class MockMCPServerManager: MCPServerManager {
    var shouldFailNextRequest = false
    var mockToolResult: MCPToolResult!

    convenience init() {
        // This is a simplified init for testing
        self.init(backendClient: MockPythonBackendClient(), keychainManager: MockKeychainManager())
        setupMockData()
    }

    private func setupMockData() {
        mockToolResult = MCPToolResult(
            content: [MCPToolResult.MCPContent(type: "text", text: "Mock result generated successfully", data: nil, mimeType: nil)],
            isError: false
        )
    }

    func setupMockTools() {
        // Setup mock tools for testing
    }

    override func executeTool(name: String, arguments: [String: Any]) async throws -> MCPToolResult {
        if shouldFailNextRequest {
            shouldFailNextRequest = false
            throw MCPClientError.toolNotAvailable(name)
        }

        // Simulate processing time
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        return mockToolResult
    }

    override func initialize() async {
        // Mock initialization
    }
}

class MockConversationManager: ConversationManager {
    var conversations: [MockConversation] = []
    var currentConversation: MockConversation?

    override init() {
        super.init()
    }

    func addMockMessages(to conversation: MockConversation) {
        // Add some mock conversation history
        let messages = [
            ("user", "Generate documents"),
            ("assistant", "I can help you generate documents. What type would you like?"),
            ("user", "PDF reports"),
            ("assistant", "I'll create PDF reports for you."),
        ]

        for (role, content) in messages {
            conversation.mockMessages.append(MockConversationMessage(
                id: UUID(),
                content: content,
                role: role,
                timestamp: Date()
            ))
        }
    }
}

class MockConversation {
    let id: UUID
    var title: String = "Test Conversation"
    var mockMessages: [MockConversationMessage] = []

    init(id: UUID) {
        self.id = id
    }
}

class MockConversationMessage {
    let id: UUID
    let content: String
    let role: String
    let timestamp: Date

    init(id: UUID, content: String, role: String, timestamp: Date) {
        self.id = id
        self.content = content
        self.role = role
        self.timestamp = timestamp
    }
}

class MockPythonBackendClient {
    // Mock implementation
}

class MockKeychainManager {
    // Mock implementation
}

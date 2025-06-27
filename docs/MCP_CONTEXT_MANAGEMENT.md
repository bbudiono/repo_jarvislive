# MCP Context Management System

## Overview

The MCP (Meta-Cognitive Primitive) Context Management System is a sophisticated conversation context management solution that maintains state across multi-turn conversations and MCP tool calls. This system enables seamless voice interactions where users can have natural, contextual conversations with the AI assistant.

## Key Features

### 🧠 **Multi-Turn Conversation Support**
- Maintains conversation context across multiple voice commands
- Supports complex operations requiring multiple parameters
- Intelligent parameter collection and validation

### 💾 **Context Persistence**
- Persistent storage of conversation context using Core Data
- Context enrichment from conversation history
- Automatic context cleanup and memory management

### 🔄 **State Management**
- Five distinct conversation states: `idle`, `collecting_parameters`, `executing`, `awaiting_confirmation`, `error`
- Smooth state transitions with user feedback
- Error recovery and cancellation support

### 🎯 **Intelligent Parameter Resolution**
- Automatic parameter extraction from voice commands
- Smart defaults based on conversation history
- Contextual parameter suggestions

## Architecture

### Core Components

```
MCPContextManager
├── Context Creation & Management
├── Voice Command Processing
├── Parameter Collection
├── State Transitions
└── Context Persistence

MCPIntegrationManager
├── Voice Processing Integration
├── MCP Server Orchestration
├── Conversation Updates
└── Error Handling

ConversationManager (Extended)
├── MCP Context Integration
├── History Management
├── Context Enrichment
└── Persistent Storage
```

## Implementation Example

### Basic Multi-Turn Document Generation

```swift
// User: "Generate a document"
// AI: "What type of document would you like to generate?"
// User: "A PDF about project updates"  
// System: Uses context to complete document generation

let integrationManager = MCPIntegrationManager(
    mcpContextManager: contextManager,
    conversationManager: conversationManager,
    mcpServerManager: mcpServerManager
)

// Process voice command with context
let result = await integrationManager.processVoiceCommand("Generate a document")

if result.needsUserInput {
    // Show suggested actions: ["PDF", "Word document", "HTML"]
    displaySuggestions(result.suggestedActions)
}
```

### Context State Management

```swift
// Check current context state
let currentState = integrationManager.getCurrentContextState()

switch currentState {
case .idle:
    // Ready for new commands
    suggestedActions = ["generate document", "send email", "schedule meeting"]
case .collectingParameters:
    // Collecting missing information
    suggestedActions = ["provide details", "skip", "cancel"]
case .awaitingConfirmation:
    // Waiting for user confirmation
    suggestedActions = ["yes", "no", "modify"]
case .executing:
    // Processing request
    suggestedActions = ["cancel"]
case .error:
    // Error recovery
    suggestedActions = ["try again", "start over", "cancel"]
}
```

## Conversation Flow Examples

### Example 1: Document Generation

```
🔵 User: "Generate a document"
🤖 AI: "What content would you like me to include?"
📊 State: collecting_parameters

🔵 User: "About quarterly sales results"  
🤖 AI: "What format would you prefer? (PDF, Word, etc.)"
📊 State: collecting_parameters

🔵 User: "PDF format"
🤖 AI: "Ready to generate PDF about quarterly sales results. Proceed?"
📊 State: awaiting_confirmation

🔵 User: "Yes"
🤖 AI: "✅ PDF document generated successfully!"
📊 State: idle
```

### Example 2: Email Composition

```
🔵 User: "Send an email"
🤖 AI: "Who should I send the email to?"
📊 State: collecting_parameters

🔵 User: "john@example.com and sarah@company.com"
🤖 AI: "What should the subject line be?"
📊 State: collecting_parameters

🔵 User: "Meeting follow-up"
🤖 AI: "What should the email content be?"
📊 State: collecting_parameters

🔵 User: "Thanks for the meeting. Here are the action items..."
🤖 AI: "Ready to send email to 2 recipients with subject 'Meeting follow-up'. Send?"
📊 State: awaiting_confirmation

🔵 User: "Yes, send it"
🤖 AI: "✅ Email sent successfully! Message ID: msg_12345"
📊 State: idle
```

### Example 3: Context Switching

```
🔵 User: "Generate a document about quarterly results"
🤖 AI: "What format would you prefer?"
📊 State: collecting_parameters

🔵 User: "Actually, send an email to the team first"
🤖 AI: "I'll help you send an email. Who should receive it?"
📊 State: collecting_parameters (switched context)

🔵 User: "Go back to the document generation"
🤖 AI: "Returning to document generation. You wanted a document about quarterly results. What format?"
📊 State: collecting_parameters (restored context)
```

## API Reference

### MCPContextManager

#### Core Methods

```swift
// Context Management
func ensureContextExists(for conversationId: UUID)
func getContext(for conversationId: UUID) -> MCPConversationContext?
func updateContext(for conversationId: UUID, _ updateBlock: (inout MCPConversationContext) -> Void)

// Voice Processing
func processVoiceCommandWithContext(_ command: String, conversationId: UUID) async throws -> MCPContextualResponse

// Context Operations
func enrichContextFromHistory(conversationId: UUID) async
func clearContext(for conversationId: UUID)
func exportContext(for conversationId: UUID) -> String?
```

#### State Properties

```swift
@Published private(set) var activeContexts: [UUID: MCPConversationContext]
@Published private(set) var isProcessingContext: Bool
@Published private(set) var contextStats: MCPContextStats
```

### MCPIntegrationManager

#### Main Interface

```swift
// Voice Processing
func processVoiceCommand(_ command: String) async -> MCPProcessingResult
func processVoiceTranscription(_ transcription: String, confidence: Double) async -> MCPProcessingResult

// Direct Operations
func generateDocument(content: String, format: String) async -> MCPProcessingResult
func sendEmail(to: [String], subject: String, body: String) async -> MCPProcessingResult
func scheduleEvent(title: String, startTime: Date, endTime: Date) async -> MCPProcessingResult

// Context Access
func getCurrentContextState() -> MCPConversationContext.MCPSessionState
func getPendingParameters() -> [String: Any]
func getContextHistory() -> [MCPConversationContext.MCPContextEntry]
```

### Data Models

#### MCPConversationContext

```swift
struct MCPConversationContext {
    let conversationId: UUID
    let activeContext: MCPActiveContext
    let contextHistory: [MCPContextEntry]
    let pendingOperations: [MCPPendingOperation]
    let lastUpdated: Date
    let expiresAt: Date?
}
```

#### MCPContextualResponse

```swift
struct MCPContextualResponse {
    let message: String
    let needsUserInput: Bool
    let contextState: MCPConversationContext.MCPSessionState
    let suggestedActions: [String]
}
```

## Testing

### Unit Tests

The system includes comprehensive unit tests covering:

- Context creation and management
- Multi-turn conversation flows
- Parameter collection and validation
- Error recovery scenarios
- Context persistence and cleanup

### Running Tests

```bash
cd _iOS/JarvisLive-Sandbox
xcodebuild test -scheme JarvisLive-Sandbox -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:JarvisLiveTests/MCPContextManagerTests
```

### Demo Script

A Python demonstration script shows the system behavior:

```bash
python3 scripts/demo_mcp_context.py
```

## Integration Guide

### Basic Setup

1. **Initialize Components**
```swift
let conversationManager = ConversationManager()
let mcpServerManager = MCPServerManager(
    backendClient: backendClient,
    keychainManager: keychainManager
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
```

2. **Process Voice Commands**
```swift
let result = await integrationManager.processVoiceCommand(transcription)
updateUI(with: result)
```

3. **Handle State Changes**
```swift
switch result.contextState {
case .collectingParameters:
    showParameterInput(result.suggestedActions)
case .awaitingConfirmation:
    showConfirmationDialog(result.message)
case .executing:
    showProgressIndicator()
default:
    break
}
```

### Advanced Integration

#### Custom Parameter Resolvers

```swift
class CustomParameterResolver: MCPParameterResolver {
    override func extractParameters(from input: String, analysis: MCPCommandAnalysis) async -> [String: Any] {
        // Custom parameter extraction logic
        var parameters = await super.extractParameters(from: input, analysis: analysis)
        
        // Add custom extraction patterns
        if input.contains("urgent") {
            parameters["priority"] = "high"
        }
        
        return parameters
    }
}
```

#### Context Enrichment

```swift
// Enrich context from conversation history
await contextManager.enrichContextFromHistory(conversationId: conversationId)

// Custom context enrichment
contextManager.updateContext(for: conversationId) { context in
    context.activeContext.contextualInformation["user_preferences"] = AnyCodable(userPreferences)
}
```

## Performance Considerations

### Memory Management

- **Context Cleanup**: Automatic cleanup of expired contexts every 5 minutes
- **History Limits**: Maximum 20 context entries per conversation
- **Cache Management**: Tool execution results cached for 5 minutes

### Optimization Strategies

1. **Batch Processing**: Group related operations for efficiency
2. **Lazy Loading**: Load context only when needed
3. **Background Processing**: Use background queues for heavy operations
4. **Smart Caching**: Cache frequently used parameters and results

## Best Practices

### 1. State Management
- Always check context state before processing commands
- Provide clear feedback about current state
- Implement proper error recovery mechanisms

### 2. User Experience
- Offer contextual suggestions based on current state
- Enable cancellation at every step
- Provide confirmation for destructive operations

### 3. Performance
- Clean up expired contexts regularly
- Use appropriate cache expiration times
- Monitor memory usage with large conversation histories

### 4. Error Handling
- Graceful degradation when context is lost
- Clear error messages with recovery options
- Automatic retry with exponential backoff

## Troubleshooting

### Common Issues

#### Context Not Persisting
```swift
// Ensure conversation is properly set
conversationManager.setCurrentConversation(conversation)

// Verify context creation
contextManager.ensureContextExists(for: conversation.id)
```

#### Parameter Collection Failing
```swift
// Check required parameters definition
let missingParams = analysis.missingParameters
print("Missing parameters: \(missingParams)")

// Verify parameter extraction
let extractedParams = await parameterResolver.extractParameters(from: input, analysis: analysis)
print("Extracted: \(extractedParams)")
```

#### State Transition Issues
```swift
// Monitor state changes
contextManager.$activeContexts
    .sink { contexts in
        for (id, context) in contexts {
            print("Context \(id): \(context.activeContext.sessionState)")
        }
    }
    .store(in: &cancellables)
```

### Debug Mode

Enable detailed logging for troubleshooting:

```swift
// Enable debug logging
UserDefaults.standard.set(true, forKey: "MCPContextDebugMode")

// This will print detailed state transitions and parameter extraction
```

## Future Enhancements

### Planned Features

1. **Multi-Language Support**: Context management for multiple languages
2. **Voice Recognition Integration**: Confidence-based processing
3. **Advanced Parameter Types**: Support for complex parameter types
4. **Context Sharing**: Share context between conversations
5. **Analytics Dashboard**: Usage statistics and performance metrics

### Extension Points

The system is designed for extensibility:

- **Custom Tool Integrations**: Add new MCP tools easily
- **Advanced Context Enrichment**: Implement custom enrichment strategies
- **Alternative Storage Backends**: Support different persistence mechanisms
- **Custom State Machines**: Implement domain-specific conversation flows

## License

This MCP Context Management System is part of the Jarvis Live project and follows the project's licensing terms.

---

*For additional support or questions, please refer to the project documentation or create an issue in the repository.*
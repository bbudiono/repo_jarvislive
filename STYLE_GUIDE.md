# Jarvis Live Style Guide

## Overview

This style guide establishes the visual, interaction, and code conventions for Jarvis Live. It ensures consistency across all components and provides clear guidelines for designers and developers.

## Table of Contents
- [Visual Design System](#visual-design-system)
- [UI Components](#ui-components)
- [Code Style](#code-style)
- [Naming Conventions](#naming-conventions)
- [Documentation Style](#documentation-style)
- [Error Handling](#error-handling)

## Visual Design System

### 1. Glassmorphism Theme

Jarvis Live uses a consistent Glassmorphism design language that creates depth and visual hierarchy through translucent layers and subtle shadows.

#### Core Principles
- **Transparency:** Use material backgrounds with opacity
- **Blur Effects:** Apply backdrop blur for depth
- **Subtle Borders:** White/gray borders with low opacity
- **Layered Composition:** Stack translucent elements
- **Minimal Shadows:** Soft, subtle drop shadows

#### Material Hierarchy
```swift
// Primary containers
.background(.ultraThinMaterial)      // Main content areas

// Secondary containers  
.background(.thinMaterial)           // Interactive elements

// Tertiary containers
.background(.regularMaterial)        // Input fields, secondary content
```

### 2. Color Palette

#### System Colors
```swift
// Primary Text
.foregroundColor(.primary)           // High contrast text
.foregroundColor(.secondary)         // Medium contrast text  
.foregroundColor(.tertiary)          // Low contrast text

// Interactive Colors
Color.blue                          // Primary actions, links
Color.green                         // Success states, confirmations
Color.red                           // Errors, destructive actions
Color.orange                        // Warnings, attention needed
Color.purple                        // Special features, AI responses

// Background Colors
Color.clear                         // Transparent backgrounds
.background(.ultraThinMaterial)     // Primary content areas
```

#### Custom Brand Colors
```swift
extension Color {
    // Jarvis Live brand colors
    static let jarvisBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let jarvisAccent = Color(red: 0.8, green: 0.3, blue: 1.0)
    static let jarvisSuccess = Color(red: 0.3, green: 0.8, blue: 0.4)
}
```

### 3. Typography Scale

#### Font Hierarchy
```swift
// Headings
.font(.largeTitle)                  // 34pt - Main page titles
.font(.title)                       // 28pt - Section headers
.font(.title2)                      // 22pt - Subsection headers
.font(.title3)                      // 20pt - Card titles

// Body Text
.font(.headline)                    // 17pt - Important body text
.font(.body)                        // 17pt - Regular body text
.font(.callout)                     // 16pt - Secondary information

// Supporting Text
.font(.subheadline)                 // 15pt - Supporting text
.font(.footnote)                    // 13pt - Fine print
.font(.caption)                     // 12pt - Labels, captions
.font(.caption2)                    // 11pt - Timestamps, metadata
```

#### Font Weight Usage
```swift
.fontWeight(.black)                 // Main headlines only
.fontWeight(.bold)                  // Emphasis, important information
.fontWeight(.semibold)              // Section headers, buttons
.fontWeight(.medium)                // Card titles, navigation
.fontWeight(.regular)               // Body text (default)
.fontWeight(.light)                 // Large display text
```

### 4. Spacing System

#### Layout Spacing
```swift
// Margins and padding
let spacing4: CGFloat = 4           // Tight spacing
let spacing8: CGFloat = 8           // Small spacing
let spacing12: CGFloat = 12         // Medium-small spacing
let spacing16: CGFloat = 16         // Standard spacing
let spacing24: CGFloat = 24         // Large spacing
let spacing32: CGFloat = 32         // Extra large spacing
let spacing48: CGFloat = 48         // Section spacing
```

#### Component Spacing
```swift
VStack(spacing: 16) {               // Standard component spacing
    HStack(spacing: 12) {           // Icon-text spacing
        VStack(spacing: 8) {        // Tight content spacing
```

### 5. Corner Radius Standards

```swift
// Border radius scale
let radius4: CGFloat = 4            // Small elements (badges)
let radius8: CGFloat = 8            // Buttons, small cards
let radius12: CGFloat = 12          // Standard interactive elements
let radius16: CGFloat = 16          // Cards, main containers
let radius20: CGFloat = 20          // Large cards, modals
let radius24: CGFloat = 24          // Full-screen containers
```

## UI Components

### 1. Cards and Containers

#### Standard Glass Card
```swift
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// Usage
GlassCard {
    VStack {
        Text("Card Title")
            .font(.headline)
        Text("Card content goes here")
            .font(.body)
    }
}
```

#### Interactive Container
```swift
struct InteractiveGlassContainer<Content: View>: View {
    let content: Content
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            content
                .padding(16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

### 2. Buttons

#### Primary Button
```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
```

#### Secondary Button
```swift
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.blue.opacity(0.5), lineWidth: 1)
                )
        }
    }
}
```

#### Glass Button
```swift
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
```

### 3. Input Fields

#### Standard Text Field
```swift
struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(PlainTextFieldStyle())
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
    }
}
```

#### Search Field
```swift
struct SearchField: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
```

### 4. Status and Feedback

#### Status Badge
```swift
struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color, in: RoundedRectangle(cornerRadius: 4))
    }
}

// Usage examples
StatusBadge(text: "Success", color: .green)
StatusBadge(text: "Error", color: .red)
StatusBadge(text: "Processing", color: .orange)
```

#### Loading Indicator
```swift
struct GlassLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle())
            
            Text("Processing...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
```

### 5. Navigation

#### Tab Bar Item
```swift
struct GlassTabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.caption)
        }
        .foregroundColor(isSelected ? .blue : .secondary)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            isSelected ? .thinMaterial : Color.clear,
            in: RoundedRectangle(cornerRadius: 8)
        )
    }
}
```

## Code Style

### 1. Swift Code Style

#### Naming Conventions
```swift
// Classes and Structs: PascalCase
class VoiceCommandProcessor
struct ClassificationResult

// Functions and Variables: camelCase
func processVoiceCommand()
var isProcessing: Bool

// Constants: camelCase
let maximumRetryAttempts = 3
let defaultTimeoutInterval: TimeInterval = 30

// Enums: PascalCase with camelCase cases
enum CommandCategory {
    case documentGeneration
    case emailManagement
    case calendarScheduling
}

// Protocols: PascalCase with -ing or -able suffix
protocol VoiceProcessing
protocol Authenticatable
```

#### Code Organization
```swift
// MARK: - Properties
@Published var isAuthenticated = false
private let apiClient: APIClient

// MARK: - Lifecycle
override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
}

// MARK: - Public Methods
func authenticate() async throws {
    // Implementation
}

// MARK: - Private Methods
private func setupUI() {
    // Implementation
}

// MARK: - Extensions
extension ViewController: UITableViewDelegate {
    // Delegate methods
}
```

#### Function Structure
```swift
/// Processes voice command and returns classification result
/// - Parameters:
///   - text: The voice command text to process
///   - context: Optional context from previous commands
/// - Returns: Classification result with category and confidence
/// - Throws: VoiceProcessingError if classification fails
func processVoiceCommand(
    _ text: String,
    context: ConversationContext? = nil
) async throws -> ClassificationResult {
    guard !text.isEmpty else {
        throw VoiceProcessingError.emptyInput
    }
    
    let processedText = preprocess(text)
    let result = try await classifier.classify(processedText, context: context)
    
    return result
}
```

### 2. Python Code Style

#### Naming Conventions
```python
# Classes: PascalCase
class VoiceClassifier:
class ClassificationResult:

# Functions and variables: snake_case
def classify_voice_command():
def process_audio_stream():
is_authenticated: bool = False

# Constants: UPPER_SNAKE_CASE
MAX_RETRY_ATTEMPTS = 3
DEFAULT_TIMEOUT_SECONDS = 30

# Private methods: leading underscore
def _preprocess_text(text: str) -> str:
def _extract_features(text: str) -> Dict[str, Any]:
```

#### Type Annotations
```python
from typing import Optional, Dict, List, Union, Callable
from dataclasses import dataclass

@dataclass
class ClassificationResult:
    category: str
    confidence: float
    parameters: Dict[str, Any]
    processing_time_ms: float

async def classify_voice_command(
    text: str,
    context: Optional[Dict[str, Any]] = None,
    session_id: Optional[str] = None
) -> ClassificationResult:
    """Classify voice command with context awareness."""
    pass
```

#### Error Handling
```python
class VoiceProcessingError(Exception):
    """Base exception for voice processing errors."""
    pass

class ClassificationError(VoiceProcessingError):
    """Raised when voice classification fails."""
    pass

async def process_command(text: str) -> ClassificationResult:
    try:
        result = await classifier.classify(text)
        return result
    except ClassificationError as e:
        logger.error(f"Classification failed: {e}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise VoiceProcessingError(f"Processing failed: {e}")
```

## Naming Conventions

### 1. File and Directory Names

#### iOS Files
```
// Views: [Feature]View.swift
ContentView.swift
SettingsView.swift
AuthenticationView.swift

// Managers: [Feature]Manager.swift
VoiceCommandManager.swift
AuthenticationManager.swift
NetworkManager.swift

// Models: [Entity]Model.swift
ConversationModel.swift
UserModel.swift
ClassificationModel.swift

// Extensions: [Type]+[Feature].swift
String+Validation.swift
View+GlassModifier.swift
```

#### Python Files
```
# Modules: descriptive_name.py
voice_classifier.py
authentication_manager.py
mcp_bridge.py

# Tests: test_[module_name].py
test_voice_classifier.py
test_api_endpoints.py
test_performance.py
```

### 2. API Endpoints

```python
# RESTful conventions
GET    /voice/categories          # List all voice categories
POST   /voice/classify            # Classify voice command
GET    /voice/history             # Get classification history

POST   /auth/login               # Authenticate user
POST   /auth/refresh             # Refresh token
DELETE /auth/logout              # Logout user

POST   /mcp/execute              # Execute MCP command
GET    /mcp/servers              # List available MCP servers
```

### 3. Environment Variables

```bash
# Configuration
JARVIS_API_URL=https://api.jarvis-live.com
JARVIS_API_KEY=your_api_key_here

# Database
DATABASE_URL=postgresql://user:pass@localhost/jarvis
REDIS_URL=redis://localhost:6379

# External Services  
ELEVENLABS_API_KEY=your_elevenlabs_key
LIVEKIT_API_KEY=your_livekit_key
LIVEKIT_SECRET_KEY=your_livekit_secret

# Security
JWT_SECRET_KEY=your_jwt_secret_key
JWT_EXPIRATION_HOURS=24
```

## Documentation Style

### 1. Code Comments

#### Swift Documentation
```swift
/// Main voice processing pipeline that handles end-to-end voice command processing
///
/// This class orchestrates the entire voice command flow from audio input to action execution:
/// 1. Voice classification using ML models
/// 2. Parameter extraction and validation  
/// 3. MCP server routing and execution
/// 4. Result formatting and error handling
///
/// - Important: All voice commands must be classified before execution
/// - Note: Supports both synchronous and asynchronous processing
class VoiceCommandPipeline {
    
    /// Processes a voice command and returns the execution result
    /// - Parameter text: The transcribed voice command text
    /// - Returns: Structured result containing success status and data
    /// - Throws: `VoiceProcessingError` if classification or execution fails
    func processVoiceCommand(_ text: String) async throws -> VoiceCommandPipelineResult {
        // Implementation
    }
}
```

#### Python Documentation
```python
class VoiceClassifier:
    """
    Advanced voice command classifier using hybrid ML and rule-based approaches.
    
    This classifier combines multiple techniques to achieve high accuracy:
    - Natural language processing for intent recognition
    - Machine learning models for category classification  
    - Rule-based systems for parameter extraction
    - Confidence scoring for result validation
    
    Attributes:
        model: The trained classification model
        confidence_threshold: Minimum confidence for valid classifications
        
    Example:
        >>> classifier = VoiceClassifier()
        >>> result = await classifier.classify("Create a PDF document")
        >>> print(result.category)
        'document_generation'
    """
    
    async def classify_async(
        self, 
        text: str, 
        context: Optional[Dict] = None
    ) -> ClassificationResult:
        """
        Classify voice command with contextual awareness.
        
        Args:
            text: The voice command text to classify
            context: Optional context from previous commands for better accuracy
            
        Returns:
            ClassificationResult containing category, confidence, and extracted parameters
            
        Raises:
            ClassificationError: If the text cannot be reliably classified
            ValueError: If the input text is empty or invalid
            
        Example:
            >>> result = await classifier.classify_async("Send email to John")
            >>> assert result.category == "email_management"
            >>> assert result.confidence > 0.8
        """
        pass
```

### 2. README Structure

```markdown
# Component Name

Brief description of what this component does and why it exists.

## Features

- Feature 1: Brief description
- Feature 2: Brief description  
- Feature 3: Brief description

## Usage

### Basic Example
```swift
// Swift code example
let manager = VoiceCommandManager()
let result = await manager.process("create document")
```

### Advanced Example
```swift
// More complex example with error handling
do {
    let result = try await manager.processWithContext("create document", context: context)
    print("Success: \(result.data)")
} catch {
    print("Error: \(error.localizedDescription)")
}
```

## API Reference

### Methods

#### `processVoiceCommand(_:)`
- **Parameters:** `text: String` - The voice command to process
- **Returns:** `VoiceCommandPipelineResult` - The processing result
- **Throws:** `VoiceProcessingError` - If processing fails

## Testing

```bash
# Run tests
swift test

# Run with coverage
swift test --enable-code-coverage
```
```

## Error Handling

### 1. Error Types and Messages

#### iOS Error Handling
```swift
enum VoiceProcessingError: LocalizedError {
    case emptyInput
    case classificationFailed(reason: String)
    case mcpExecutionFailed(serverName: String, error: String)
    case networkUnavailable
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Voice command cannot be empty"
        case .classificationFailed(let reason):
            return "Could not understand voice command: \(reason)"
        case .mcpExecutionFailed(let serverName, let error):
            return "Action failed on \(serverName): \(error)"
        case .networkUnavailable:
            return "Network connection required for voice processing"
        case .authenticationRequired:
            return "Please sign in to use voice commands"
        }
    }
}
```

#### Python Error Handling
```python
class JarvisError(Exception):
    """Base exception for Jarvis Live errors."""
    
    def __init__(self, message: str, error_code: str = None):
        self.message = message
        self.error_code = error_code
        super().__init__(self.message)

class VoiceProcessingError(JarvisError):
    """Raised when voice processing fails."""
    pass

class AuthenticationError(JarvisError):
    """Raised when authentication fails."""
    pass

# Usage with proper logging
import logging

logger = logging.getLogger(__name__)

try:
    result = await process_voice_command(text)
except VoiceProcessingError as e:
    logger.error(f"Voice processing failed: {e.message}", extra={
        "error_code": e.error_code,
        "input_text": text[:100]  # Truncate for logging
    })
    raise
```

### 2. User-Friendly Error Messages

```swift
struct ErrorDisplayView: View {
    let error: Error
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Oops! Something went wrong")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(userFriendlyMessage(for: error))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                // Retry action
            }
            .buttonStyle(SecondaryButton())
        }
        .padding()
        .modifier(GlassViewModifier())
    }
    
    private func userFriendlyMessage(for error: Error) -> String {
        if let voiceError = error as? VoiceProcessingError {
            return voiceError.errorDescription ?? "Unknown voice processing error"
        }
        return "We're having trouble processing your request. Please try again."
    }
}
```

---

**Last Updated:** 2025-06-26  
**Version:** 1.0.0  
**Maintained By:** Development Team
# Contributing to Jarvis Live

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Development Workflow](#development-workflow)
- [Adding Voice Commands](#adding-voice-commands)
- [iOS UI Development](#ios-ui-development)
- [UI Development Standards](#ui-development-standards)
- [Testing Requirements](#testing-requirements)
- [Code Quality Standards](#code-quality-standards)
- [CI/CD Pipeline](#cicd-pipeline)
- [Troubleshooting](#troubleshooting)

## Overview

Jarvis Live is a comprehensive iOS Voice AI Assistant with a Python backend. This guide establishes the development standards, architectural patterns, and workflows that ensure consistent, high-quality code across all contributions.

**Core Principles:**
- **Sandbox-First Development**: All iOS changes must be tested in Sandbox before Production
- **Test-Driven Development (TDD)**: Write tests before implementation
- **Quality Gates**: All code must pass automated linting, testing, and security checks
- **Design Consistency**: Follow Glassmorphism UI theme and established patterns

## Architecture

### High-Level System Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   iOS Frontend  │◄──►│  Python Backend  │◄──►│  MCP Servers    │
│                 │    │                  │    │                 │
│ • SwiftUI Views │    │ • FastAPI        │    │ • Document Gen  │
│ • Voice Pipeline│    │ • Voice Classify │    │ • Email Send    │
│ • MCP Client    │    │ • JWT Auth       │    │ • Web Search    │
│ • Core Data     │    │ • Performance    │    │ • Calendar      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### iOS Application Architecture

**Pattern**: MVVM + SwiftUI with TDD validation

```
Sources/
├── App/                     # Application lifecycle
├── Core/                    # Business logic and services
│   ├── AI/                  # Voice classification and AI
│   ├── Audio/               # LiveKit audio processing
│   ├── MCP/                 # MCP server communication
│   ├── Network/             # Backend API clients
│   ├── Security/            # Keychain and authentication
│   └── Data/                # Core Data and persistence
├── Features/                # Feature-specific modules
│   ├── DocumentGeneration/
│   ├── Settings/
│   └── VoiceChat/
└── UI/                      # User interface components
    ├── Components/          # Reusable UI components
    ├── Views/               # Screen-level views
    └── Styles/              # Theme and styling
```

### Python Backend Architecture

**Pattern**: FastAPI with async/await and modular design

```
src/
├── api/                     # FastAPI routes and models
├── ai/                      # Voice classification logic
├── auth/                    # JWT authentication
├── mcp/                     # MCP server implementations
└── main.py                  # Application entry point
```

## Development Workflow

### 1. Sandbox-First Development (iOS Only)

**MANDATORY:** All iOS features must follow this workflow:

```bash
# 1. Develop in Sandbox
cd _iOS/JarvisLive-Sandbox

# 2. Write tests first (TDD)
# Create test file in Tests/JarvisLiveSandboxTests/

# 3. Implement feature
# Add implementation in Sources/

# 4. Validate Sandbox build
xcodebuild -workspace JarvisLive.xcworkspace -scheme JarvisLive-Sandbox build
xcodebuild test -workspace JarvisLive.xcworkspace -scheme JarvisLive-Sandbox

# 5. Only after ALL tests pass, promote to Production
# Copy implementation to _iOS/JarvisLive/
# The ONLY difference should be watermark removal

# 6. Validate Production build
xcodebuild -workspace JarvisLive.xcworkspace -scheme JarvisLive build
xcodebuild test -workspace JarvisLive.xcworkspace -scheme JarvisLive
```

### 2. Python Development Workflow

```bash
# 1. Set up environment
cd _python
python3 -m venv venv
source venv/bin/activate
pip install -r requirements-dev.txt

# 2. Write tests first (TDD)
# Create test file in tests/

# 3. Implement feature
# Add implementation in src/

# 4. Run quality checks
python run_minimal_ci_tests.py

# 5. Run comprehensive tests
python -m pytest tests/ -v
```

### 3. Git Workflow

```bash
# 1. Create feature branch
git checkout -b feature/your-feature-name

# 2. Make atomic commits
git commit -m "Add voice classification for document generation

- Implement document category detection
- Add confidence scoring
- Include parameter extraction for title/format

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

# 3. Push and create PR
git push -u origin feature/your-feature-name
# CI/CD pipeline will automatically validate
```

## Adding Voice Commands

### Step-by-Step Guide

**1. Backend: Voice Classification**

```python
# File: src/ai/voice_classifier.py
# Add new command category

class CommandCategory(Enum):
    DOCUMENT_GENERATION = "document_generation"
    EMAIL_MANAGEMENT = "email_management"
    YOUR_NEW_CATEGORY = "your_new_category"  # Add here

# Add classification logic
def classify_command(self, text: str) -> ClassificationResult:
    # Add keywords and patterns for your category
    if any(keyword in text.lower() for keyword in ['your', 'keywords']):
        return ClassificationResult(
            category=CommandCategory.YOUR_NEW_CATEGORY,
            confidence=0.85,
            parameters={'extracted': 'params'}
        )
```

**2. Backend: MCP Server Integration**

```python
# File: src/mcp/your_new_server.py
# Create MCP server for the new functionality

from mcp import Server

class YourNewMCPServer(Server):
    def __init__(self):
        super().__init__("your-new-server")
        self.setup_tools()
    
    def setup_tools(self):
        @self.call_tool()
        async def your_action(param: str) -> str:
            # Implement your MCP action
            return "Action completed"
```

**3. iOS: MCP Client Integration**

```swift
// File: Sources/Core/MCP/MCPServerManager.swift
// Add handling for new command category

func processVoiceCommand(_ text: String) async throws -> VoiceCommandPipelineResult {
    let classification = try await classificationManager.classifyVoiceCommand(text)
    
    switch classification.category {
    case "your_new_category":
        return try await handleYourNewCategory(classification)
    // ... existing cases
    }
}

private func handleYourNewCategory(_ classification: ClassificationResult) async throws -> VoiceCommandPipelineResult {
    // Call your MCP server
    let result = try await mcpClient.callTool("your-action", parameters: classification.parameters)
    return VoiceCommandPipelineResult.success(result: result)
}
```

**4. iOS: UI Integration**

```swift
// File: Sources/UI/Views/YourNewFeatureView.swift
// Create SwiftUI view with Glassmorphism theme

struct YourNewFeatureView: View {
    var body: some View {
        VStack {
            // Your UI content
        }
        .modifier(GlassViewModifier()) // MANDATORY: Use glass theme
    }
}
```

**5. Testing**

```swift
// File: Tests/JarvisLiveSandboxTests/YourNewFeatureTests.swift
class YourNewFeatureTests: XCTestCase {
    func testVoiceCommandClassification() async throws {
        let result = try await voiceClassifier.classify("your test command")
        XCTAssertEqual(result.category, "your_new_category")
        XCTAssertGreaterThan(result.confidence, 0.8)
    }
}
```

## iOS UI Development

### Creating Theme-Compliant SwiftUI Views

This section provides step-by-step guidance for creating new SwiftUI views that correctly use the project's GlassViewModifier theme and includes associated snapshot testing.

#### Step 1: Create the SwiftUI View

**File Location**: `Sources/UI/Views/YourNewFeatureView.swift`

```swift
import SwiftUI

/// Your new feature view with Glassmorphism theme compliance
struct YourNewFeatureView: View {
    // MARK: - State Properties
    @State private var isLoading = false
    @State private var userInput = ""
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            // Main content area
            headerSection
            contentSection
            actionSection
        }
        .padding()
        .modifier(GlassViewModifier()) // MANDATORY: Apply glass theme
        .navigationBarTitle("Your Feature", displayMode: .large)
        .accessibilityIdentifier("YourNewFeatureView") // MANDATORY: For UI testing
    }
    
    // MARK: - View Components
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Feature Title")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .accessibilityIdentifier("FeatureTitle")
            
            Text("Feature description goes here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var contentSection: some View {
        VStack(spacing: 16) {
            // Input field using project's text field style
            TextField("Enter your input", text: $userInput)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .accessibilityIdentifier("UserInputField")
            
            // Status indicator
            if isLoading {
                ProgressView("Processing...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .accessibilityIdentifier("LoadingIndicator")
            }
        }
    }
    
    private var actionSection: some View {
        HStack(spacing: 16) {
            // Secondary button
            Button("Cancel") {
                // Cancel action
                userInput = ""
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("CancelButton")
            
            // Primary button
            Button("Process") {
                // Primary action
                isLoading = true
                // Simulate processing
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isLoading = false
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(userInput.isEmpty || isLoading)
            .accessibilityIdentifier("ProcessButton")
        }
    }
}

// MARK: - Button Styles (Following project patterns)
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
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
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        YourNewFeatureView()
    }
}
```

#### Step 2: Create the Snapshot Test

**File Location**: `Tests/JarvisLiveSandboxTests/YourNewFeatureSnapshotTests.swift`

```swift
import XCTest
import SwiftUI
import SnapshotTesting
@testable import JarvisLiveCore

/// Automated UI snapshot tests for YourNewFeatureView
final class YourNewFeatureSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        isRecording = false // CRITICAL: false for regression testing
    }
    
    // MARK: - Device Matrix Tests
    func testYourNewFeatureView_iPhone15Pro() {
        let view = YourNewFeatureView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone15Pro),
            named: "YourNewFeatureView_iPhone15Pro"
        )
    }
    
    func testYourNewFeatureView_iPadPro() {
        let view = YourNewFeatureView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPadPro12_9),
            named: "YourNewFeatureView_iPadPro"
        )
    }
    
    func testYourNewFeatureView_iPhoneSE() {
        let view = YourNewFeatureView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhoneSe2ndGeneration),
            named: "YourNewFeatureView_iPhoneSE"
        )
    }
    
    // MARK: - Appearance Tests
    func testYourNewFeatureView_DarkMode() {
        let view = YourNewFeatureView()
            .preferredColorScheme(.dark)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone15Pro, traits: .init(userInterfaceStyle: .dark)),
            named: "YourNewFeatureView_DarkMode"
        )
    }
    
    func testYourNewFeatureView_LightMode() {
        let view = YourNewFeatureView()
            .preferredColorScheme(.light)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone15Pro, traits: .init(userInterfaceStyle: .light)),
            named: "YourNewFeatureView_LightMode"
        )
    }
    
    // MARK: - Accessibility Tests
    func testYourNewFeatureView_LargeText() {
        let view = YourNewFeatureView()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone15Pro),
            named: "YourNewFeatureView_LargeText"
        )
    }
    
    func testYourNewFeatureView_HighContrast() {
        let view = YourNewFeatureView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone15Pro, traits: .init(accessibilityContrast: .high)),
            named: "YourNewFeatureView_HighContrast"
        )
    }
    
    // MARK: - State Tests
    func testYourNewFeatureView_LoadingState() {
        // Note: In real implementation, you would set up the view in loading state
        let view = YourNewFeatureView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone15Pro),
            named: "YourNewFeatureView_LoadingState"
        )
    }
}
```

#### Step 3: Development Checklist

Use this checklist for every new SwiftUI view:

**Theme Compliance:**
- [ ] Applied `GlassViewModifier()` to main container
- [ ] Used project color palette (`.primary`, `.secondary`, `.blue`, etc.)
- [ ] Applied consistent typography scale (`.largeTitle`, `.headline`, `.body`)
- [ ] Used standard spacing values (8, 16, 20, 24 pt)
- [ ] Applied consistent corner radius (10-16 pt for most elements)

**Accessibility:**
- [ ] Added `accessibilityIdentifier` for all interactive elements
- [ ] Provided meaningful accessibility labels
- [ ] Tested with VoiceOver (if possible)
- [ ] Ensured text scales properly with Dynamic Type
- [ ] Verified color contrast meets accessibility standards

**Code Quality:**
- [ ] Organized code with proper MARK comments
- [ ] Created reusable components when appropriate
- [ ] Used meaningful variable and function names
- [ ] Added preview for SwiftUI Canvas testing
- [ ] Followed project naming conventions

**Testing:**
- [ ] Created comprehensive snapshot tests
- [ ] Tested on multiple device sizes (iPhone, iPad)
- [ ] Tested both light and dark modes
- [ ] Tested accessibility configurations
- [ ] Tested different state variations (loading, error, success)
- [ ] Verified all tests pass before committing

**Integration:**
- [ ] Integrated with existing navigation flow
- [ ] Connected to appropriate ViewModels/ObservableObjects
- [ ] Handled error states gracefully
- [ ] Implemented proper loading states
- [ ] Added to appropriate feature module

#### Step 4: Running Tests

```bash
# Run snapshot tests for your new view
cd _iOS/JarvisLive-Sandbox
xcodebuild test -workspace JarvisLive.xcworkspace -scheme JarvisLive-Sandbox \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest' \
  -only-testing:JarvisLiveSandboxTests/YourNewFeatureSnapshotTests

# Generate new snapshots (only when intentionally changing UI)
# Temporarily set isRecording = true in test setUp, run tests once, then set back to false
```

#### Step 5: Promotion to Production

After all sandbox tests pass:

1. **Copy implementation** to `_iOS/JarvisLive/Sources/UI/Views/`
2. **Copy tests** to `_iOS/JarvisLive/Tests/JarvisLiveTests/`
3. **Remove sandbox watermarks** (if any) from production version
4. **Run production tests** to ensure compatibility
5. **Commit both sandbox and production versions** together

### Common Patterns and Components

#### Loading States
```swift
if isLoading {
    ProgressView("Processing...")
        .progressViewStyle(CircularProgressViewStyle())
        .scaleEffect(1.2)
}
```

#### Error States
```swift
if let errorMessage = errorMessage {
    VStack {
        Image(systemName: "exclamationmark.triangle")
            .font(.system(size: 48))
            .foregroundColor(.orange)
        Text(errorMessage)
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }
    .modifier(GlassViewModifier())
}
```

#### Empty States
```swift
VStack(spacing: 16) {
    Image(systemName: "doc.text")
        .font(.system(size: 64))
        .foregroundColor(.secondary)
    Text("No items yet")
        .font(.headline)
    Text("Create your first item to get started")
        .font(.body)
        .foregroundColor(.secondary)
}
.modifier(GlassViewModifier())
```

## UI Development Standards

### 1. Glassmorphism Theme (MANDATORY)

All UI components MUST use the established Glassmorphism design system:

```swift
// REQUIRED: Apply to all containers
.modifier(GlassViewModifier())

// Glass card pattern
VStack {
    // Content
}
.padding()
.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
.overlay(
    RoundedRectangle(cornerRadius: 16)
        .stroke(.white.opacity(0.2), lineWidth: 1)
)
```

### 2. Color Palette

```swift
// Primary Colors
.foregroundColor(.primary)      // Primary text
.foregroundColor(.secondary)    // Secondary text
.foregroundColor(.tertiary)     // Tertiary text

// Accent Colors
Color.blue                      // Primary actions
Color.green                     // Success states
Color.red                       // Error states
Color.orange                    // Warning states
```

### 3. Typography

```swift
.font(.largeTitle)             // Main headings
.font(.headline)               // Section headings
.font(.body)                   // Body text
.font(.caption)                // Secondary info
```

### 4. Component Patterns

**Button Style:**
```swift
Button("Action") {
    // Action
}
.padding()
.background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
.overlay(
    RoundedRectangle(cornerRadius: 12)
        .stroke(.white.opacity(0.3), lineWidth: 1)
)
```

**Input Field Style:**
```swift
TextField("Placeholder", text: $text)
    .padding()
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    .overlay(
        RoundedRectangle(cornerRadius: 10)
            .stroke(.white.opacity(0.1), lineWidth: 1)
    )
```

### 5. Accessibility Requirements

```swift
// MANDATORY: All interactive elements must have labels
.accessibilityLabel("Descriptive label")
.accessibilityHint("What this does")

// Support for VoiceOver
.accessibilityAddTraits(.isButton)

// Support for large text
.font(.body)
.lineLimit(nil)
```

## Testing Requirements

### 1. iOS Testing Strategy

**Unit Tests (Business Logic):**
```swift
func testVoiceCommandProcessing() async throws {
    // Test core business logic
    let result = try await voiceProcessor.processCommand("test")
    XCTAssertTrue(result.success)
}
```

**Integration Tests (Component Interaction):**
```swift
func testMCPServerIntegration() async throws {
    // Test cross-component functionality
    let response = try await mcpManager.processVoiceCommand("create document")
    XCTAssertEqual(response.category, "document_generation")
}
```

**UI Tests (Visual Validation):**
```swift
func testMainContentView_iPhone15Pro() {
    let contentView = ContentView()
    let hostingController = UIHostingController(rootView: contentView)
    
    assertSnapshot(
        matching: hostingController,
        as: .image(on: .iPhone15Pro),
        named: "ContentView_iPhone15Pro"
    )
}
```

### 2. Python Testing Strategy

**Unit Tests:**
```python
def test_voice_classification():
    classifier = VoiceClassifier()
    result = classifier.classify("create a PDF document")
    assert result.category == "document_generation"
    assert result.confidence > 0.8
```

**API Tests:**
```python
def test_voice_classify_endpoint(client):
    response = client.post("/voice/classify", json={
        "text": "create document",
        "session_id": "test"
    })
    assert response.status_code == 200
    assert response.json()["category"] == "document_generation"
```

### 3. Performance Tests

**Load Testing (Locust):**
```python
class VoiceClassificationUser(HttpUser):
    @task
    def classify_command(self):
        self.client.post("/voice/classify", json={
            "text": "create document",
            "session_id": f"test_{time.time()}"
        })
```

## Code Quality Standards

### 1. Python Standards

**Formatting:**
- Black (line length: 88)
- isort for import sorting

**Linting:**
- Flake8 with complexity limits
- MyPy for type checking

**Type Annotations:**
```python
def process_command(text: str, session_id: Optional[str] = None) -> ClassificationResult:
    """Process voice command with proper typing."""
    pass
```

### 2. iOS Standards

**SwiftLint Configuration:**
- Force unwrapping: Error level
- Missing documentation: Warning level
- Line length: 120 characters

**Naming Conventions:**
```swift
// Classes: PascalCase
class VoiceCommandProcessor

// Functions: camelCase
func processVoiceCommand()

// Constants: camelCase
let maximumRetryCount = 3

// Enums: PascalCase with camelCase cases
enum CommandCategory {
    case documentGeneration
}
```

### 3. Documentation Standards

**Swift Documentation:**
```swift
/// Processes voice commands using AI classification
/// - Parameter text: The voice command text to process
/// - Returns: Classification result with category and confidence
/// - Throws: VoiceProcessingError if classification fails
func processVoiceCommand(_ text: String) async throws -> ClassificationResult {
    // Implementation
}
```

**Python Documentation:**
```python
def classify_voice_command(text: str, context: Optional[Dict] = None) -> ClassificationResult:
    """
    Classify voice command into appropriate category.
    
    Args:
        text: The voice command text to classify
        context: Optional context from previous commands
        
    Returns:
        ClassificationResult with category, confidence, and parameters
        
    Raises:
        ClassificationError: If text cannot be classified
    """
    pass
```

## CI/CD Pipeline

### 1. Automated Quality Gates

The CI/CD pipeline runs automatically on all Pull Requests:

**Python Checks:**
- Black formatting validation
- isort import sorting
- Flake8 linting
- MyPy type checking
- pytest unit tests
- Security scanning (Bandit)

**iOS Checks:**
- SwiftLint validation
- Xcode build verification
- Unit test execution
- UI test validation

### 2. Local Validation

**Before committing, run:**
```bash
# Python validation
cd _python && python run_minimal_ci_tests.py

# Full pipeline validation
./scripts/validate_ci_setup.sh
```

### 3. Performance Testing

**Manual performance testing:**
```bash
cd _python && python tests/performance/run_performance_tests.py --ci
```

## Troubleshooting

### Common iOS Build Issues

**Issue:** Swift Package Manager resolution fails
```bash
# Solution: Clean and rebuild
rm -rf _iOS/.build
cd _iOS && swift package resolve
```

**Issue:** Sandbox/Production build differences
```bash
# Solution: Verify only watermark differences
diff -r JarvisLive-Sandbox/Sources JarvisLive/Sources
```

### Common Python Issues

**Issue:** Import errors in tests
```bash
# Solution: Ensure proper module structure
export PYTHONPATH="${PYTHONPATH}:$(pwd)/src"
```

**Issue:** Dependency conflicts
```bash
# Solution: Clean virtual environment
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements-dev.txt
```

### CI/CD Pipeline Issues

**Issue:** Tests failing in CI but passing locally
```bash
# Solution: Check environment differences
python run_minimal_ci_tests.py  # Use CI-compatible runner
```

**Issue:** SwiftLint configuration conflicts
```bash
# Solution: Validate configuration
swiftlint lint --config _iOS/JarvisLive-Sandbox/.swiftlint.yml
```

---

## Getting Help

- **Architecture Questions:** Review this guide and existing code patterns
- **Testing Issues:** Check test examples in `Tests/` directories
- **CI/CD Problems:** See `.github/workflows/README.md`
- **Performance Concerns:** Use provided performance testing tools

Remember: **Quality is non-negotiable.** All code must pass automated checks before merge.

---

**Last Updated:** 2025-06-26  
**Version:** 1.0.0  
**Maintained By:** Development Team
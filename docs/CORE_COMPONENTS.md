# Core UI Components Documentation

**Project:** Jarvis Live iOS Voice AI Assistant  
**Version:** 1.0.0-sandbox  
**Last Updated:** 2025-06-27  

## Overview

This document serves as the centralized reference for reusable UI components in the Jarvis Live iOS application. All components follow the established glassmorphism design system and modular architecture principles.

## Component Architecture

The UI components are organized in a hierarchical structure:

```
Sources/UI/
├── Components/           # Reusable modifiers and styles
│   └── GlassViewModifier.swift
├── Views/
│   ├── MainContentView/  # Modular ContentView components
│   │   ├── HeaderView.swift
│   │   ├── TitleView.swift
│   │   ├── ConnectionStatusView.swift
│   │   ├── VoiceRecordingView.swift
│   │   ├── MCPActionsView.swift
│   │   ├── ConnectionButtonView.swift
│   │   └── FooterView.swift
│   └── [Other Views]
└── Styles/              # Custom button styles and themes
```

## Core Components Reference

### 1. GlassViewModifier

**Purpose:** Central glassmorphism theme modifier providing consistent visual effects across the application.

**Location:** `Sources/UI/Components/GlassViewModifier.swift`

**Usage:**
```swift
VStack {
    Text("Content")
}
.modifier(GlassViewModifier())

// Or using the convenience extension:
VStack {
    Text("Content")
}
.glassmorphic()
```

**Features:**
- Ultra-thin material background with blur effects
- Gradient stroke borders (white opacity 0.4 → 0.1)
- Drop shadow with 8px radius
- 16px corner radius with continuous style
- Automatic frame expansion (.infinity width)
- Built-in padding

**Design System Integration:** This modifier is the foundation of the glassmorphism theme and should be used consistently across all card-style UI elements.

---

### 2. HeaderView

**Purpose:** Navigation header with sandbox watermark and feature access buttons.

**Location:** `Sources/UI/Views/MainContentView/HeaderView.swift`

**Usage:**
```swift
HeaderView(
    onConversationHistoryTap: { showingConversationHistory = true },
    onDocumentScannerTap: { showingDocumentScanner = true },
    onSettingsTap: { showingSettings = true }
)
```

**Parameters:**
- `onConversationHistoryTap: () -> Void` - Callback for conversation history access
- `onDocumentScannerTap: () -> Void` - Callback for document scanner access  
- `onSettingsTap: () -> Void` - Callback for settings access

**Features:**
- Prominent "🧪 SANDBOX MODE" watermark with orange branding
- Three navigation buttons: Conversation History (purple), Document Scanner (blue), Settings (cyan)
- Automatic glassmorphism styling via GlassViewModifier
- Full accessibility support with identifiers and labels

---

### 3. TitleView

**Purpose:** Main application title and branding display.

**Location:** `Sources/UI/Views/MainContentView/TitleView.swift`

**Usage:**
```swift
TitleView()
```

**Features:**
- "Jarvis Live" title with ultra-light rounded font (32pt)
- "AI Voice Assistant" subtitle with opacity styling
- Integrated "SANDBOX MODE" badge with P0 compliance
- Orange-themed sandbox watermark with stroke and background
- Automatic glassmorphism styling

---

### 4. ConnectionStatusView

**Purpose:** LiveKit connection status indicator with animations.

**Location:** `Sources/UI/Views/MainContentView/ConnectionStatusView.swift`

**Usage:**
```swift
ConnectionStatusView(
    statusText: "Connected to LiveKit",
    statusColor: .mint,
    isConnected: true,
    isConnecting: false
)
```

**Parameters:**
- `statusText: String` - Current connection status message
- `statusColor: Color` - Status indicator color (mint/orange/cyan/pink)
- `isConnected: Bool` - Whether connection is established
- `isConnecting: Bool` - Whether connection is in progress

**Features:**
- Animated status indicator circle with scale effects during connection
- Dynamic status text with accessibility identifier
- Optional "Voice commands are active" message when connected
- Color-coded status states: Connected (mint), Connecting (orange), Disconnected (cyan), Error (pink)

---

### 5. VoiceRecordingView

**Purpose:** Complete voice recording interface with transcription and AI response display.

**Location:** `Sources/UI/Views/MainContentView/VoiceRecordingView.swift`

**Usage:**
```swift
VoiceRecordingView(
    voiceCoordinator: voiceCoordinator,
    audioLevel: liveKitManager.audioLevel,
    onToggleRecording: toggleRecording
)
```

**Parameters:**
- `voiceCoordinator: VoiceActivityCoordinator` - Voice state manager (ObservableObject)
- `audioLevel: Float` - Current audio input level for meter display
- `onToggleRecording: () -> Void` - Callback to start/stop recording

**Features:**
- Animated recording button with voice activity indicators
- Real-time audio level meter during recording
- Live transcription display with scroll view (60-120px height)
- AI response display with placeholder text
- Three-section layout: controls, transcription, AI response
- Full accessibility support for recording states

---

### 6. MCPActionsView

**Purpose:** MCP (Meta-Cognitive Primitive) action buttons with progress tracking.

**Location:** `Sources/UI/Views/MainContentView/MCPActionsView.swift`

**Usage:**
```swift
MCPActionsView(
    mcpActionInProgress: mcpActionInProgress,
    mcpActionResult: mcpActionResult,
    onDocumentGeneration: { showingDocumentGeneration = true },
    onSendEmail: { /* email action */ },
    onSearch: { /* search action */ },
    onCreateEvent: { /* calendar action */ }
)
```

**Parameters:**
- `mcpActionInProgress: Bool` - Whether an MCP action is currently executing
- `mcpActionResult: String` - Result text from completed actions
- `onDocumentGeneration: () -> Void` - Document generation callback
- `onSendEmail: () -> Void` - Email sending callback
- `onSearch: () -> Void` - Search execution callback
- `onCreateEvent: () -> Void` - Calendar event creation callback

**Features:**
- 2x2 grid layout for four primary MCP actions
- Color-coded action buttons: Document (blue), Email (green), Search (orange), Calendar (purple)
- Progress indicator with spinner and status text
- Result display area with scrollable text (max 60px height)
- Automatic button disabling during action execution

---

### 7. ConnectionButtonView

**Purpose:** Connect button display when LiveKit is disconnected.

**Location:** `Sources/UI/Views/MainContentView/ConnectionButtonView.swift`

**Usage:**
```swift
ConnectionButtonView(
    statusColor: .cyan,
    microphoneIcon: "mic.slash.fill",
    isConnecting: false,
    onConnect: { Task { await liveKitManager.connect() } }
)
```

**Parameters:**
- `statusColor: Color` - Connection status color for gradients
- `microphoneIcon: String` - SF Symbol for microphone state
- `isConnecting: Bool` - Whether connection attempt is in progress
- `onConnect: () -> Void` - Connection initiation callback

**Features:**
- Layered circular design with gradient effects
- Outer glow ring (100px) and main button (80px) with status color
- Animated scaling during connection attempts
- Dynamic microphone icon based on connection state
- "Connect to start voice chat" caption

---

### 8. FooterView

**Purpose:** Development build information display.

**Location:** `Sources/UI/Views/MainContentView/FooterView.swift`

**Usage:**
```swift
FooterView()
```

**Features:**
- "Development Build" caption with reduced opacity
- "Version 1.0.0-sandbox" version display
- Minimal design with glassmorphism styling
- Bottom padding for proper layout spacing

---

## Design System Guidelines

### Glassmorphism Theme

All components utilize the `GlassViewModifier` for consistent glassmorphism effects:

- **Background:** Ultra-thin material with system blur
- **Border:** Linear gradient stroke (white 0.4 → 0.1 opacity)
- **Shadow:** 8px blur radius with 0.2 black opacity
- **Corners:** 16px continuous rounded rectangles
- **Padding:** Automatic internal spacing

### Color System

- **Orange:** Sandbox branding and warnings (#FF9500)
- **Cyan:** Primary action and connection states (#32D0F0)
- **Purple:** Secondary actions and AI branding (#AF5EDD) 
- **Mint:** Success and connected states (#3DD68C)
- **Blue:** Document and file actions (#007AFF)
- **Green:** Communication actions (#34C759)

### Typography

- **Titles:** System rounded, ultra-light weight
- **Headlines:** System default, semibold weight
- **Body:** System default, regular weight
- **Captions:** System default, reduced opacity for hierarchy

### Accessibility

All components include:
- `accessibilityIdentifier` for UI testing
- `accessibilityLabel` for screen readers
- Appropriate contrast ratios
- Touch target sizes (minimum 44x44 points)

## Testing & Validation

### Snapshot Testing

Components are validated using the `ThemeUISnapshotTests.swift` suite:

```swift
func testComponentName_VariantDescription() {
    let component = ComponentView(/* parameters */)
    let hostingController = UIHostingController(rootView: component)
    
    assertSnapshot(
        matching: hostingController,
        as: .image(on: .iPhone16Pro),
        named: "ComponentName_VariantDescription"
    )
}
```

### Device Support Matrix

Components are tested across:
- iPhone 16 Pro (393x852 points)
- iPhone 16 Pro Max (430x932 points)  
- iPad Pro 11" (834x1194 points)

### Accessibility Testing

- High contrast mode compatibility
- Dynamic type support (up to accessibility XL)
- VoiceOver navigation testing
- Color differentiation support

## Usage Best Practices

### Component Composition

```swift
// ✅ Good: Modular composition with clear responsibilities
VStack(spacing: 30) {
    HeaderView(onSettingsTap: { showingSettings = true })
    TitleView()
    ConnectionStatusView(statusText: statusText, ...)
}

// ❌ Bad: Monolithic view with inline UI
VStack {
    // 100+ lines of inline UI code
}
```

### State Management

```swift
// ✅ Good: Pass state via parameters
VoiceRecordingView(
    voiceCoordinator: voiceCoordinator,
    audioLevel: liveKitManager.audioLevel,
    onToggleRecording: toggleRecording
)

// ❌ Bad: Direct environment object access in components
@EnvironmentObject var liveKitManager: LiveKitManager
```

### Styling Consistency

```swift
// ✅ Good: Use GlassViewModifier for consistency
content.modifier(GlassViewModifier())

// ❌ Bad: Custom inline styling
content.background(.ultraThinMaterial)
      .cornerRadius(16)
      .shadow(radius: 8)
```

## Maintenance Notes

### Adding New Components

1. Create component file in appropriate directory
2. Follow established naming conventions (`ComponentNameView.swift`)
3. Include comprehensive documentation header
4. Add to this documentation with usage examples
5. Create corresponding snapshot tests
6. Verify accessibility compliance

### Modifying Existing Components

1. Update component implementation
2. Update documentation if interface changes
3. Update snapshot tests for visual changes
4. Verify accessibility is maintained
5. Test across device matrix

### Component Dependencies

- All components depend on `SwiftUI` framework
- `GlassViewModifier` is a universal dependency
- Voice-related components require `VoiceActivityCoordinator`
- Action components require closure-based callbacks for separation of concerns

---

**Next Developer Note:** This documentation is maintained as components evolve. When adding new reusable UI components, ensure they follow the established patterns and add them to this reference guide.
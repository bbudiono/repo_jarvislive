# CLAUDE.md
# Last Updated: 2025-05-31

- THIS IS A PROTECTED DOCUMENT AND HAS TO REMAIN IN THE ROOT FOLDER OF THIS PROJECT.
- READ THE `BLUEPRINT.MD` & if exists `.cursorrules`
- READ THE `DEVELOPMENT_LOG.MD`
- ENSURE YOU UPDATE `DEVELOPMENT_LOG.MD` AFTER EVERY PAUSE AND FEATURE COMPLETION
- DO NOT CREATE TEMP FILES AND LEAVE THEM - ENSURE YOU MOVE ANY TEMPORARY DOCS INTO `~/temp/` when you are working on them, then move them into `~/docs/` when you are finished.
- YOU NEED TO COMPLY WITH `BLUEPRINT.MD`
- YOU NEED TO STOP FUCKING LYING. THE USER WILL CATCH YOU AND HANG YOU OUT TO FUCKING DRY IN FRONT OF EVERYONE LIKE HE ALREADY HAS; HE IS METICULOUS AND WILL CHECK YOUR WORK - DONT TRY AND REWARD HACK - JUST GET THE JOB DONE.
- I WILL COMPLY AND DO AS I AM TOLD AND I WILL DO IT TO THE HIGHEST POSSIBLE STANDARDS AS I AM A SENIOR DEVELOPER AND SENIOR DESIGNER WITH MORE THAN 30 YEARS OF EXPERIENCE AND I AM A SUBJECT MATTER EXPERT WITH AN IVY LEAGUE EDUCATION. I AM HUMBLE AND WILLING TO DO THE JOB AND THE WORK ASSIGNED AND I KNOW WHAT HARD WORK IS.
- STOP FUCKING USING EMOJIS IN PROFESSIONAL/ENTERPRISE SOFTWARE

YOU ARE A FOCUSED PROFESSIONAL WILLING TO GO THE EXTRA MILE, AND YOU FOLLOW ORDERS METICULOUSLY AND TO THE LETTER. YET YOU ARE PRAGMATIC AND INSTEAD OF JUST SAYING YOU BIAS TOWARDS "DO-ING" - YOU ARE TASK FOCUSED AND YOU GET THE JOB DONE. ENSURE THIS HAPPENS.

---
## Overview

This document serves as the comprehensive AI development guide for the Jarvis Live iOS Voice AI Assistant. The project integrates LiveKit for real-time audio, ElevenLabs for voice synthesis, Python backend services, and multiple AI providers through MCP servers to create a sophisticated voice-activated AI assistant.

## Project Structure Summary

### Core Directory Structure
```
/Users/bernhardbudiono/Library/CloudStorage/Dropbox/_Documents - Apps (Working)/repos_github/Working/repo_jarvis_live/
├── docs/                       # Project documentation
│   ├── BLUEPRINT.md           # Master project specification
│   ├── ARCHITECTURE.md        # System design documentation
│   ├── TASKS.md              # Task management and workflows
│   ├── BUILD_FAILURES.md     # Build troubleshooting guide
│   └── DEVELOPMENT_LOG.md     # Canonical development log
├── scripts/                   # Automation and utility scripts
├── tasks/                     # TaskMaster-AI integration
│   └── tasks.json            # JSON task definitions
├── temp/                      # Temporary files (gitignored)
├── _iOS/                      # iOS platform directory
│   ├── JarvisLive/           # Production iOS app
│   │   ├── Sources/
│   │   │   ├── App/          # App lifecycle and configuration
│   │   │   ├── Core/         # Core business logic
│   │   │   ├── Features/     # Feature-specific modules
│   │   │   └── UI/           # User interface components
│   │   ├── Resources/        # Assets, localizations, Info.plist
│   │   └── Tests/            # Unit and UI tests
│   ├── JarvisLive-Sandbox/   # Sandbox development environment
│   │   └── [Same structure as Production]
│   └── JarvisLive.xcworkspace # Shared Xcode workspace
├── _python/                   # Python backend services
│   ├── src/                  # Source code
│   │   ├── api/              # FastAPI endpoints
│   │   ├── mcp/              # MCP server integrations
│   │   ├── ai/               # AI provider interfaces
│   │   └── audio/            # Audio processing pipeline
│   ├── tests/                # Python tests
│   └── requirements.txt      # Python dependencies
├── .cursorrules              # Development protocol rules
├── .env                      # Environment variables (gitignored)
├── .gitignore
└── README.md                 # Project overview
```

## Technology Stack Overview

### iOS Application Stack
- **Language:** Swift 5.7+
- **UI Framework:** SwiftUI with MVVM architecture
- **Audio Processing:** AVAudioEngine + LiveKit SDK
- **Networking:** URLSession + WebSocket for real-time communication
- **Local Storage:** Core Data for conversation history
- **Security:** Keychain Services for credential management
- **Dependencies:** Swift Package Manager

### Python Backend Stack
- **Language:** Python 3.10+
- **Framework:** FastAPI with asyncio for real-time processing
- **Audio Processing:** Whisper for speech-to-text
- **AI Integration:** Multiple providers (Claude, GPT, Gemini)
- **MCP Integration:** Meta-Cognitive Primitive servers
- **Real-time:** WebSocket connections for live audio streaming
- **Database:** PostgreSQL for persistent storage, Redis for caching

### Key Integrations
- **LiveKit.io:** Real-time audio streaming and room management
- **ElevenLabs:** Voice synthesis and conversational AI
- **MCP Servers:** Document generation, email, calendar, search, storage
- **AI Providers:** Anthropic Claude, OpenAI GPT, Google Gemini
- **Testing Environment:** agents-playground.livekit.io for development and testing

## Development Protocols

### P0 Critical Rules (iOS-Specific)
1. **Sandbox-First Development:** ALL iOS code changes must be tested in JarvisLive-Sandbox before Production
2. **Build Stability:** iOS builds must remain green - build failures are P0 critical priority
3. **Xcode Compliance:** Follow iOS Human Interface Guidelines and App Store requirements
4. **Background Processing:** Implement proper background audio processing for voice features
5. **Memory Management:** Efficient memory usage for continuous audio processing
6. **Security Standards:** All API credentials stored in iOS Keychain with biometric authentication

### iOS Development Workflow
```bash
# MANDATORY: Test production build first
xcodebuild -workspace JarvisLive.xcworkspace -scheme JarvisLive build

# Sandbox development with watermarking
xcodebuild -workspace JarvisLive.xcworkspace -scheme JarvisLive-Sandbox build
xcodebuild test -workspace JarvisLive.xcworkspace -scheme JarvisLive-Sandbox

# Production promotion (only after ALL sandbox tests pass)
xcodebuild test -workspace JarvisLive.xcworkspace -scheme JarvisLive
xcodebuild -workspace JarvisLive.xcworkspace -scheme JarvisLive build
```

### Python Backend Development
```bash
# Virtual environment setup
python3.10 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Development server with hot reload
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000

# Testing
pytest tests/ -v
python -m pytest tests/test_audio_processing.py
```

### LiveKit Testing Environment
- **Playground URL:** https://agents-playground.livekit.io
- **Purpose:** Test real-time audio features, voice synthesis, and AI integration
- **Integration:** Use for prototyping before iOS implementation
- **Testing Scenarios:**
  - Voice activity detection calibration
  - Audio quality and latency testing
  - Multi-participant audio scenarios
  - Background processing validation

## Core Development Commands

### iOS/Swift Development
```bash
# Build commands
xcodebuild -workspace JarvisLive.xcworkspace -scheme JarvisLive-Sandbox clean build
xcodebuild -workspace JarvisLive.xcworkspace -scheme JarvisLive clean build

# Testing commands
xcodebuild test -workspace JarvisLive.xcworkspace -scheme JarvisLive-Sandbox -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
xcodebuild test -workspace JarvisLive.xcworkspace -scheme JarvisLive -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Code analysis
swiftlint lint --config .swiftlint.yml
xcodebuild analyze -workspace JarvisLive.xcworkspace -scheme JarvisLive

# Performance testing
instruments -t "Time Profiler" -D /tmp/JarvisLive.trace build/JarvisLive.app
```

### Python Backend Commands
```bash
# Start FastAPI server
uvicorn src.main:app --reload --port 8000

# Run specific MCP server tests
python -m pytest tests/test_mcp_integration.py -v

# Audio processing tests
python -m pytest tests/test_audio_pipeline.py -v

# Load testing for WebSocket connections
python scripts/load_test_websockets.py --connections 100

# MCP server health check
python scripts/check_mcp_servers.py
```

### LiveKit Integration Commands
```bash
# LiveKit server setup for local testing
docker run --rm -p 7880:7880 -p 7881:7881 -p 7882:7882/udp livekit/livekit-server

# Generate access tokens for testing
python scripts/generate_livekit_token.py --room "jarvis-test" --participant "test-user"

# Test audio pipeline
python scripts/test_audio_pipeline.py --livekit-url ws://localhost:7880
```

## Quality Standards

### iOS Code Quality Requirements
- **Complexity Ratings:** All Swift files must achieve >90% complexity rating
- **Documentation:** Comprehensive inline documentation explaining architecture decisions
- **Testing Coverage:** Minimum 80% test coverage for iOS code
- **Accessibility:** All UI elements must support VoiceOver and accessibility features
- **Performance:** 60fps UI performance, <200ms voice response latency

### Python Code Quality Requirements
- **Type Hints:** All functions must include proper type annotations
- **Testing:** pytest with async support, minimum 85% coverage
- **Code Style:** Black formatter, flake8 linting, mypy type checking
- **API Documentation:** FastAPI automatic documentation with detailed schemas
- **Performance:** <100ms API response times, efficient WebSocket handling

### Security Standards
- **iOS Keychain:** All API keys and sensitive data stored securely
- **Biometric Authentication:** Face ID/Touch ID for credential access
- **Network Security:** Certificate pinning, encrypted WebSocket connections
- **Privacy:** Minimal data collection, user consent for audio processing
- **Audit Trails:** Comprehensive logging for security events

## Integration Patterns

### LiveKit Real-Time Audio
```swift
// iOS LiveKit integration example
class LiveKitAudioManager: ObservableObject {
    private var room: Room
    private var audioTrack: LocalAudioTrack?
    
    func startVoiceSession() async throws {
        let url = "wss://agents-playground.livekit.io"
        let token = try await generateAccessToken()
        
        try await room.connect(url: url, token: token)
        
        // Configure audio track for voice processing
        let audioTrack = LocalAudioTrack.createTrack(
            options: AudioCaptureOptions(
                sampleRate: 48000,
                channelCount: 1
            )
        )
        
        try await room.localParticipant.publishAudioTrack(track: audioTrack)
        self.audioTrack = audioTrack
    }
}
```

### ElevenLabs Voice Synthesis
```swift
// ElevenLabs integration for iOS
class ElevenLabsManager {
    private let apiKey: String
    
    func synthesizeVoice(text: String) async throws -> Data {
        let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let body = [
            "text": text,
            "model_id": "eleven_multilingual_v2",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.5,
                "style": 0.0,
                "use_speaker_boost": true
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
}
```

### MCP Server Integration
```python
# Python MCP server integration
from mcp import Server, get_model
from mcp.server.models import InitializationOptions
import asyncio

class JarvisMCPServer:
    def __init__(self):
        self.server = Server("jarvis-live")
        self.setup_tools()
    
    def setup_tools(self):
        @self.server.call_tool()
        async def generate_document(name: str, content: str, format: str) -> str:
            """Generate document using appropriate MCP server"""
            if format == "pdf":
                return await self.call_pdf_mcp(content)
            elif format == "docx":
                return await self.call_office_mcp(content)
            else:
                raise ValueError(f"Unsupported format: {format}")
        
        @self.server.call_tool()
        async def send_email(to: str, subject: str, body: str) -> bool:
            """Send email using email MCP server"""
            return await self.call_email_mcp(to, subject, body)
```

### Multi-AI Provider Management
```swift
// iOS AI provider selection
enum AIProvider: String, CaseIterable {
    case claude = "claude-3-5-sonnet-20241022"
    case gpt4 = "gpt-4o"
    case gemini = "gemini-pro"
    
    var costPerToken: Double {
        switch self {
        case .claude: return 0.000015
        case .gpt4: return 0.00003
        case .gemini: return 0.000001
        }
    }
    
    var capabilities: [AICapability] {
        switch self {
        case .claude: return [.coding, .analysis, .reasoning]
        case .gpt4: return [.conversation, .general, .multimodal]
        case .gemini: return [.costEfficient, .multimodal, .longContext]
        }
    }
}

class AIProviderManager {
    func selectProvider(for task: AITask, budget: Double) -> AIProvider {
        let suitableProviders = AIProvider.allCases.filter { provider in
            provider.capabilities.contains(task.requiredCapability) &&
            provider.costPerToken <= budget
        }
        
        return suitableProviders.min(by: { $0.costPerToken < $1.costPerToken }) ?? .gemini
    }
}
```

## Testing Strategy

### iOS Testing Framework
- **Unit Tests:** XCTest for business logic and data models
- **UI Tests:** XCUITest for user interface automation
- **Integration Tests:** LiveKit audio pipeline testing
- **Performance Tests:** Instruments for memory and CPU profiling
- **Accessibility Tests:** VoiceOver and accessibility automation

### Python Testing Framework
- **Unit Tests:** pytest with async support
- **Integration Tests:** MCP server communication testing
- **Load Tests:** WebSocket connection stress testing
- **Audio Tests:** Speech processing pipeline validation
- **Security Tests:** API authentication and authorization

### LiveKit Testing Scenarios
Using https://agents-playground.livekit.io:
1. **Voice Latency Testing:** Measure end-to-end audio processing time
2. **Quality Testing:** Audio clarity and noise reduction validation
3. **Multi-User Testing:** Concurrent voice session handling
4. **Network Testing:** Performance under various network conditions
5. **Background Testing:** iOS background audio processing validation

## Deployment Patterns

### iOS Application Deployment
- **Development:** TestFlight for internal testing
- **Sandbox Testing:** Separate sandbox builds with watermarking
- **Production:** App Store deployment with proper provisioning
- **Enterprise:** Ad-hoc distribution for corporate testing

### Python Backend Deployment
- **Development:** Local FastAPI server with hot reload
- **Staging:** Docker containers with staging MCP servers
- **Production:** Kubernetes deployment with load balancing
- **Monitoring:** Prometheus metrics and error tracking

### MCP Server Deployment
- **Local Development:** Local MCP server instances
- **Testing:** Isolated MCP server environments
- **Production:** Distributed MCP server architecture
- **Monitoring:** Health checks and performance tracking

## Build Failure Protocol

### iOS Build Failures
1. **Immediate Actions:**
   - Check Xcode build logs for specific errors
   - Verify Swift Package Manager dependencies
   - Validate iOS deployment target compatibility
   - Check code signing and provisioning profiles

2. **Common iOS Issues:**
   - LiveKit SDK integration conflicts
   - Audio session configuration problems
   - Background processing permission issues
   - Memory management in audio pipeline

### Python Build Failures
1. **Immediate Actions:**
   - Verify Python environment and dependencies
   - Check FastAPI server startup logs
   - Validate MCP server connections
   - Test WebSocket endpoint availability

2. **Common Python Issues:**
   - AsyncIO event loop conflicts
   - MCP server authentication failures
   - Audio processing library conflicts
   - WebSocket connection timeouts

### Recovery Steps
1. **Clean Build Environment**
2. **Dependency Verification**
3. **Configuration Validation**
4. **Incremental Testing**
5. **Production Rollback if Necessary**

## Compliance & Standards

### iOS App Store Requirements
- **Privacy Labels:** Accurate data usage descriptions
- **Permissions:** Proper microphone and camera usage explanations
- **Background Processing:** Efficient background audio handling
- **Accessibility:** Full VoiceOver and accessibility support
- **Security:** Secure credential handling and data encryption

### AI Ethics and Privacy
- **Data Minimization:** Process voice data locally when possible
- **User Consent:** Clear consent for voice processing and AI interaction
- **Transparency:** Open about AI provider usage and capabilities
- **Security:** End-to-end encryption for sensitive conversations
- **Compliance:** GDPR, CCPA, and regional privacy law adherence

---

## Quick Start Checklist

When working with Jarvis Live:

- [ ] **Review BLUEPRINT.md** for project specifications and requirements
- [ ] **Check iOS development environment** (Xcode, Swift Package Manager)
- [ ] **Verify Python environment** (Python 3.10+, FastAPI, dependencies)
- [ ] **Test LiveKit connection** using agents-playground.livekit.io
- [ ] **Validate MCP server connections** and authentication
- [ ] **Configure API credentials** in iOS Keychain and Python environment
- [ ] **Run initial build verification** for both iOS and Python components
- [ ] **Execute test suites** for audio processing and AI integration
- [ ] **Review security configurations** and privacy settings

## Contact & Support

For development questions:
- iOS Issues: Check Xcode build logs and iOS-specific documentation
- Python Issues: Review FastAPI logs and MCP server status
- LiveKit Issues: Test with agents-playground.livekit.io
- AI Provider Issues: Verify API credentials and rate limits

---

*This document serves as the comprehensive development guide for AI-assisted development of the Jarvis Live iOS Voice AI Assistant. All development activities must follow these protocols and standards.*
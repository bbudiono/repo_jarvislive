# Jarvis Live - iOS Voice AI Assistant

[![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.7+-orange.svg)](https://swift.org/)
[![Python](https://img.shields.io/badge/Python-3.10+-green.svg)](https://python.org/)
[![LiveKit](https://img.shields.io/badge/LiveKit-Voice-purple.svg)](https://livekit.io/)
[![ElevenLabs](https://img.shields.io/badge/ElevenLabs-AI_Voice-blue.svg)](https://elevenlabs.io/)

An intelligent iOS voice AI assistant that provides real-time conversational AI capabilities with multi-modal support. Jarvis Live integrates LiveKit for real-time audio, ElevenLabs for voice synthesis, and multiple AI providers through MCP servers to create documents, emails, PDFs, presentations, and interact with everyday services.

## 🌟 Features

- **🎙️ Real-Time Voice Conversation** - LiveKit-powered real-time voice interaction with AI
- **🤖 Multi-AI Provider Support** - Seamless integration with Claude, GPT-4, and Gemini
- **📷 Camera Vision Integration** - Real-time camera feed processing and document scanning
- **🔍 Web Search & Knowledge Base** - Comprehensive search and knowledge management
- **📄 Document Generation** - Create PDFs, presentations, emails, and office documents
- **📧 Communication Integration** - Email, calendar, and service integrations via MCP servers
- **🔐 Secure Credential Management** - iOS Keychain integration with biometric authentication

## 🏗️ Architecture

### iOS Application
- **Framework:** SwiftUI with MVVM architecture
- **Audio Processing:** AVAudioEngine + LiveKit SDK
- **Security:** Keychain Services for credential management
- **Real-time:** WebSocket connections for live audio streaming

### Python Backend
- **Framework:** FastAPI with asyncio for real-time processing
- **AI Integration:** Multiple providers (Claude, GPT, Gemini)
- **MCP Integration:** Meta-Cognitive Primitive servers
- **Audio Processing:** Whisper for speech-to-text

## 🚀 Quick Start

### Prerequisites

- Xcode 15.0+ with iOS 16.0+ deployment target
- Python 3.10+
- LiveKit account and API credentials
- ElevenLabs API key
- AI provider API keys (Anthropic, OpenAI, Google)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/repo_jarvis_live.git
   cd repo_jarvis_live
   ```

2. **Configure API keys**
   - Add your API keys through the iOS app's Settings screen
   - Or configure environment variables for the Python backend in `_python/.env`

3. **Set up Python backend**
   ```bash
   cd _python
   python3.10 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

4. **Open iOS project**
   ```bash
   open _iOS/JarvisLive-Sandbox/JarvisLive-Sandbox.xcodeproj
   ```

5. **Run the application**
   - Start Python backend: `uvicorn src.main:app --reload`
   - Build and run iOS app in Xcode

## 🧪 Testing

### iOS Testing
```bash
# Run iOS unit tests
xcodebuild test -project _iOS/JarvisLive-Sandbox/JarvisLive-Sandbox.xcodeproj -scheme JarvisLive-Sandbox -destination 'platform=iOS Simulator,name=iPhone 16 Pro' CODE_SIGNING_ALLOWED=NO

# Run iOS UI tests
xcodebuild test -project _iOS/JarvisLive-Sandbox/JarvisLive-Sandbox.xcodeproj -scheme JarvisLive-Sandbox -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:JarvisLiveUITests CODE_SIGNING_ALLOWED=NO
```

### Python Testing
```bash
cd _python
pytest tests/ -v
```

### LiveKit Testing
Use [agents-playground.livekit.io](https://agents-playground.livekit.io) for testing real-time audio features and voice synthesis integration.

## 📱 Usage

### Voice Interaction
1. Launch the app and grant microphone permissions
2. Tap the voice button or say "Hey Jarvis"
3. Speak your request naturally
4. Receive voice and text responses

### Document Generation
```
"Hey Jarvis, create a meeting summary from today's discussion"
"Generate a PDF report on renewable energy trends"
"Draft an email to the team about the project update"
```

### Visual Processing
1. Point camera at document or object
2. Ask "What's this about?" or "Summarize this document"
3. Receive immediate analysis and summary

## 🔧 Configuration

### MCP Servers

The app integrates with various MCP servers for extended functionality:

- **Document Generation:** `pdf-generator-mcp`, `office-suite-mcp`
- **Communication:** `email-mcp`, `calendar-mcp`, `contacts-mcp`
- **Search & Knowledge:** `web-search-mcp`, `weather-mcp`, `knowledge-base-mcp`
- **Voice & Audio:** `elevenlabs-mcp`, `livekit-mcp`

### AI Providers

Configure multiple AI providers for optimal performance and cost:

```swift
// Provider selection based on task type and budget
let provider = AIProviderManager.selectProvider(for: .conversation, budget: 0.00002)
```

## 🗂️ Project Structure

```
repo_jarvis_live/
├── docs/                       # Project documentation
│   ├── BLUEPRINT.md           # Master project specification
│   ├── ARCHITECTURE.md        # System design
│   └── TASKS.md              # Development tasks
├── _iOS/                      # iOS application
│   ├── JarvisLive/           # Production app
│   ├── JarvisLive-Sandbox/   # Development sandbox
│   └── JarvisLive.xcworkspace # Xcode workspace
├── _python/                   # Python backend
│   ├── src/                  # Source code
│   └── tests/                # Tests
├── scripts/                   # Automation scripts
└── .cursorrules              # Development protocols
```

## 🔐 Security

- **Credential Storage:** All API keys stored securely in iOS Keychain
- **Biometric Authentication:** Face ID/Touch ID for sensitive operations
- **Network Security:** Certificate pinning for API communications
- **Privacy:** Minimal data collection with user consent
- **Encryption:** End-to-end encryption for sensitive conversations

## 🤝 Contributing

1. Read the development guidelines in [CLAUDE.md](CLAUDE.md)
2. Follow the protocols defined in [.cursorrules](.cursorrules)
3. Ensure all tests pass before submitting pull requests
4. Use the Sandbox environment for all development work

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation:** Check [docs/](docs/) for comprehensive guides
- **Issues:** Report bugs and feature requests via GitHub Issues
- **Development:** Follow protocols in [CLAUDE.md](CLAUDE.md)

## 🙏 Acknowledgments

- [LiveKit](https://livekit.io/) for real-time audio infrastructure
- [ElevenLabs](https://elevenlabs.io/) for voice synthesis
- [Anthropic](https://anthropic.com/) for Claude AI
- [OpenAI](https://openai.com/) for GPT models
- [Google](https://ai.google/) for Gemini AI

---

**Built with ❤️ for seamless voice AI interaction on iOS**
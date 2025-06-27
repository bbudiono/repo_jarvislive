# MCP ARCHITECTURE.md - Jarvis Live MCP Integration Technical Specification
**Version:** 1.0.0  
**Last Updated:** 2025-06-26  
**Status:** DESIGN SPECIFICATION - IMPLEMENTATION IN PROGRESS

## EXECUTIVE SUMMARY

This document defines the technical architecture for integrating Meta-Cognitive Primitive (MCP) servers with the Jarvis Live iOS Voice AI Assistant. The MCP integration will transform voice commands into actionable productivity tasks including document generation, email management, calendar scheduling, and web search capabilities.

## SYSTEM ARCHITECTURE OVERVIEW

### High-Level Architecture
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   iOS Client    │    │   MCP Bridge     │    │  MCP Server     │
│   (Swift)       │◄──►│   (HTTP/WS)     │◄──►│   (Python)      │
│                 │    │                  │    │                 │
│ Voice Input     │    │ Request Routing  │    │ Document Gen    │
│ ├─ LiveKit      │    │ ├─ Authentication│    │ ├─ PDF Creator  │
│ ├─ AI Provider  │    │ ├─ Load Balancer │    │ ├─ DOCX Creator │
│ ├─ Command      │    │ ├─ Error Handler │    │ ├─ PPT Creator  │
│ │  Classifier   │    │ └─ Response      │    │ │               │
│ └─ MCP Client   │    │    Formatter     │    │ Email Service   │
│                 │    │                  │    │ ├─ SMTP Client  │
│ UI Layer        │    │ Performance      │    │ ├─ API Gateway  │
│ ├─ Conversation │    │ ├─ Caching       │    │ └─ Template Eng │
│ ├─ Settings     │    │ ├─ Rate Limiting │    │                 │
│ ├─ MCP Status   │    │ └─ Monitoring    │    │ Calendar Svc    │
│ └─ Export       │    │                  │    │ ├─ CalDAV       │
└─────────────────┘    └──────────────────┘    │ ├─ Exchange     │
                                               │ └─ Google Cal   │
                                               │                 │
                                               │ Search Service  │
                                               │ ├─ Web Search   │
                                               │ ├─ AI Summary   │
                                               │ └─ Result Cache │
                                               └─────────────────┘
```

## TECHNICAL COMPONENTS

### 1. iOS Client Architecture (Swift)

#### 1.1 MCPServerManager
**Location:** `/Sources/Core/MCP/MCPServerManager.swift`  
**Responsibility:** Primary interface between iOS app and MCP server  

```swift
@MainActor
class MCPServerManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isConnected: Bool = false
    @Published var connectionStatus: MCPConnectionStatus = .disconnected
    @Published var availableServices: [MCPService] = []
    @Published var lastOperation: MCPOperation?
    @Published var operationHistory: [MCPOperation] = []
    
    // MARK: - Private Properties
    private let baseURL: String
    private let session: URLSession
    private var webSocket: URLSessionWebSocketTask?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Initialization
    init(baseURL: String = "http://localhost:8000") {
        self.baseURL = baseURL
        self.session = URLSession(configuration: .default)
        setupDateFormatters()
    }
    
    // MARK: - Connection Management
    func connect() async throws {
        let healthURL = URL(string: "\(baseURL)/health")!
        let (_, response) = try await session.data(from: healthURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw MCPError.connectionFailed("Server health check failed")
        }
        
        await discoverServices()
        await setupWebSocket()
        
        await MainActor.run {
            self.isConnected = true
            self.connectionStatus = .connected
        }
    }
    
    // MARK: - Document Generation
    func generateDocument(content: String, format: DocumentFormat, 
                         template: String? = nil) async throws -> MCPDocumentResult {
        let request = MCPRequest(
            id: UUID().uuidString,
            method: "generate_document",
            params: [
                "content": content,
                "format": format.rawValue,
                "template": template ?? "default",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        
        let response = try await sendRequest(request)
        let result = try parseDocumentResponse(response)
        
        // Update operation history
        let operation = MCPOperation(
            id: request.id,
            type: .documentGeneration,
            status: .completed,
            startTime: Date(),
            endTime: Date(),
            result: .document(result)
        )
        
        await MainActor.run {
            self.operationHistory.append(operation)
            self.lastOperation = operation
        }
        
        return result
    }
    
    // MARK: - Email Service
    func sendEmail(to: String, subject: String, body: String, 
                   attachments: [MCPAttachment] = []) async throws -> MCPEmailResult {
        let request = MCPRequest(
            id: UUID().uuidString,
            method: "send_email",
            params: [
                "to": to,
                "subject": subject,
                "body": body,
                "attachments": attachments.map { $0.toDictionary() },
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        
        let response = try await sendRequest(request)
        return try parseEmailResponse(response)
    }
    
    // MARK: - Calendar Service
    func createCalendarEvent(title: String, startDate: Date, endDate: Date,
                           description: String? = nil, 
                           location: String? = nil) async throws -> MCPCalendarResult {
        let request = MCPRequest(
            id: UUID().uuidString,
            method: "create_calendar_event",
            params: [
                "title": title,
                "start_date": ISO8601DateFormatter().string(from: startDate),
                "end_date": ISO8601DateFormatter().string(from: endDate),
                "description": description ?? "",
                "location": location ?? "",
                "calendar_id": "primary"
            ]
        )
        
        let response = try await sendRequest(request)
        return try parseCalendarResponse(response)
    }
    
    // MARK: - Web Search Service
    func performWebSearch(query: String, maxResults: Int = 10,
                         summarize: Bool = true) async throws -> MCPSearchResult {
        let request = MCPRequest(
            id: UUID().uuidString,
            method: "perform_web_search",
            params: [
                "query": query,
                "max_results": maxResults,
                "summarize": summarize,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        
        let response = try await sendRequest(request)
        return try parseSearchResponse(response)
    }
}
```

#### 1.2 Voice Command Classification Engine
**Location:** `/Sources/Core/AI/VoiceCommandProcessor.swift`  
**Responsibility:** Intent recognition and parameter extraction  

```swift
class VoiceCommandProcessor: ObservableObject {
    // MARK: - Dependencies
    private let aiProvider: AIProviderManager
    private let mcpManager: MCPServerManager
    private let conversationManager: ConversationManager
    
    // MARK: - Command Classification
    func classifyCommand(_ input: String, 
                        context: ConversationContext? = nil) async throws -> VoiceCommand {
        // Step 1: Use AI provider for intent classification
        let classificationPrompt = buildClassificationPrompt(input, context: context)
        let aiResponse = try await aiProvider.processInput(classificationPrompt)
        
        // Step 2: Parse AI response into structured intent
        let intent = try parseIntentFromAI(aiResponse)
        
        // Step 3: Extract parameters using NLP techniques
        let parameters = try await extractParameters(input, for: intent, context: context)
        
        // Step 4: Validate parameters and build command
        return try buildValidatedCommand(intent, parameters: parameters)
    }
    
    // MARK: - Command Execution
    func executeCommand(_ command: VoiceCommand) async throws -> CommandResult {
        switch command {
        case .generateDocument(let content, let format, let template):
            let result = try await mcpManager.generateDocument(
                content: content, 
                format: format, 
                template: template
            )
            return .documentGenerated(result)
            
        case .sendEmail(let recipient, let subject, let body, let attachments):
            let result = try await mcpManager.sendEmail(
                to: recipient, 
                subject: subject, 
                body: body, 
                attachments: attachments
            )
            return .emailSent(result)
            
        case .createEvent(let title, let startDate, let endDate, let description, let location):
            let result = try await mcpManager.createCalendarEvent(
                title: title, 
                startDate: startDate, 
                endDate: endDate, 
                description: description, 
                location: location
            )
            return .eventCreated(result)
            
        case .searchWeb(let query, let maxResults, let summarize):
            let result = try await mcpManager.performWebSearch(
                query: query, 
                maxResults: maxResults, 
                summarize: summarize
            )
            return .searchCompleted(result)
            
        case .scheduleReminder(let task, let date, let priority):
            // Handle reminder scheduling
            return .reminderScheduled(task: task, date: date)
            
        case .generalConversation(let input):
            let response = try await aiProvider.processConversation(input)
            return .conversationResponse(response)
        }
    }
    
    // MARK: - Context Building
    private func buildClassificationPrompt(_ input: String, 
                                         context: ConversationContext?) -> String {
        var prompt = """
        You are a voice command classifier for Jarvis, an AI assistant. 
        Analyze the following user input and classify it into one of these categories:
        
        1. DOCUMENT_GENERATION - User wants to create a document (PDF, DOCX, PPT)
        2. EMAIL_COMPOSITION - User wants to send an email
        3. CALENDAR_EVENT - User wants to create a calendar event or meeting
        4. WEB_SEARCH - User wants to search for information online
        5. REMINDER_CREATION - User wants to set a reminder or task
        6. GENERAL_CONVERSATION - General conversation or question
        
        User Input: "\(input)"
        """
        
        if let context = context {
            prompt += "\n\nConversation Context:\n\(context.recentMessages)"
        }
        
        prompt += """
        
        Respond with JSON in this format:
        {
            "intent": "DOCUMENT_GENERATION|EMAIL_COMPOSITION|CALENDAR_EVENT|WEB_SEARCH|REMINDER_CREATION|GENERAL_CONVERSATION",
            "confidence": 0.95,
            "parameters": {
                // Extract relevant parameters based on intent
            }
        }
        """
        
        return prompt
    }
}
```

### 2. Python MCP Server Architecture

#### 2.1 FastAPI Server Implementation
**Location:** `/_python/src/mcp/server.py`  
**Responsibility:** Main MCP server with service coordination  

```python
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.websockets import WebSocket, WebSocketDisconnect
import asyncio
import json
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class JarvisMCPServer:
    def __init__(self):
        self.app = FastAPI(
            title="Jarvis Live MCP Server",
            description="Meta-Cognitive Primitive server for Jarvis Live iOS app",
            version="1.0.0"
        )
        
        # Service instances
        self.document_service = DocumentGenerationService()
        self.email_service = EmailService()
        self.calendar_service = CalendarService()
        self.search_service = WebSearchService()
        
        # Connection management
        self.active_connections: List[WebSocket] = []
        self.request_cache: Dict[str, Any] = {}
        
        self.setup_middleware()
        self.setup_routes()
        self.setup_websocket()
    
    def setup_middleware(self):
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],  # Configure for iOS app
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )
    
    def setup_routes(self):
        @self.app.get("/health")
        async def health_check():
            return {
                "status": "healthy",
                "timestamp": datetime.utcnow().isoformat(),
                "services": {
                    "document_generation": self.document_service.is_available(),
                    "email": self.email_service.is_available(),
                    "calendar": self.calendar_service.is_available(),
                    "web_search": self.search_service.is_available()
                }
            }
        
        @self.app.get("/services")
        async def list_services():
            return {
                "available_services": [
                    {
                        "name": "document_generation",
                        "description": "Generate PDF, DOCX, and PowerPoint documents",
                        "methods": ["generate_document"],
                        "formats": ["pdf", "docx", "pptx"]
                    },
                    {
                        "name": "email",
                        "description": "Send emails with attachments",
                        "methods": ["send_email", "compose_email"],
                        "providers": ["smtp", "sendgrid", "ses"]
                    },
                    {
                        "name": "calendar",
                        "description": "Create and manage calendar events",
                        "methods": ["create_event", "update_event", "delete_event"],
                        "providers": ["caldav", "google", "outlook"]
                    },
                    {
                        "name": "web_search",
                        "description": "Perform web searches with AI summarization",
                        "methods": ["search", "summarize_results"],
                        "engines": ["google", "bing", "duckduckgo"]
                    }
                ]
            }
        
        @self.app.post("/mcp/request")
        async def handle_mcp_request(request: MCPRequest):
            try:
                logger.info(f"Processing MCP request: {request.method}")
                
                # Route to appropriate service
                if request.method == "generate_document":
                    result = await self.document_service.generate_document(
                        content=request.params.get("content"),
                        format=request.params.get("format"),
                        template=request.params.get("template", "default")
                    )
                elif request.method == "send_email":
                    result = await self.email_service.send_email(
                        to=request.params.get("to"),
                        subject=request.params.get("subject"),
                        body=request.params.get("body"),
                        attachments=request.params.get("attachments", [])
                    )
                elif request.method == "create_calendar_event":
                    result = await self.calendar_service.create_event(
                        title=request.params.get("title"),
                        start_date=request.params.get("start_date"),
                        end_date=request.params.get("end_date"),
                        description=request.params.get("description"),
                        location=request.params.get("location")
                    )
                elif request.method == "perform_web_search":
                    result = await self.search_service.search(
                        query=request.params.get("query"),
                        max_results=request.params.get("max_results", 10),
                        summarize=request.params.get("summarize", True)
                    )
                else:
                    raise HTTPException(status_code=400, detail=f"Unknown method: {request.method}")
                
                return MCPResponse(
                    id=request.id,
                    success=True,
                    result=result,
                    timestamp=datetime.utcnow().isoformat()
                )
                
            except Exception as e:
                logger.error(f"Error processing MCP request: {str(e)}")
                return MCPResponse(
                    id=request.id,
                    success=False,
                    error=str(e),
                    timestamp=datetime.utcnow().isoformat()
                )
    
    def setup_websocket(self):
        @self.app.websocket("/ws")
        async def websocket_endpoint(websocket: WebSocket):
            await self.connect_websocket(websocket)
            try:
                while True:
                    data = await websocket.receive_text()
                    request = json.loads(data)
                    
                    # Process real-time request
                    response = await self.process_realtime_request(request)
                    await websocket.send_text(json.dumps(response))
                    
            except WebSocketDisconnect:
                self.disconnect_websocket(websocket)
    
    async def connect_websocket(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        logger.info(f"WebSocket connected. Total connections: {len(self.active_connections)}")
    
    def disconnect_websocket(self, websocket: WebSocket):
        self.active_connections.remove(websocket)
        logger.info(f"WebSocket disconnected. Total connections: {len(self.active_connections)}")
```

#### 2.2 Document Generation Service
**Location:** `/_python/src/mcp/services/document_service.py`  
**Responsibility:** PDF, DOCX, and PowerPoint generation  

```python
from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from docx import Document
from pptx import Presentation
from pptx.util import Inches
import tempfile
import os
import asyncio
from typing import Optional, Dict, Any

class DocumentGenerationService:
    def __init__(self):
        self.temp_dir = tempfile.mkdtemp()
        self.templates = {
            "default": self.get_default_template(),
            "business": self.get_business_template(),
            "academic": self.get_academic_template(),
            "technical": self.get_technical_template()
        }
    
    async def generate_document(self, content: str, format: str, 
                              template: str = "default") -> Dict[str, Any]:
        """Generate document in specified format"""
        try:
            if format.lower() == "pdf":
                file_path = await self.generate_pdf(content, template)
            elif format.lower() == "docx":
                file_path = await self.generate_docx(content, template)
            elif format.lower() == "pptx":
                file_path = await self.generate_presentation(content, template)
            else:
                raise ValueError(f"Unsupported format: {format}")
            
            return {
                "file_path": file_path,
                "file_size": os.path.getsize(file_path),
                "format": format.lower(),
                "template": template,
                "created_at": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            raise Exception(f"Document generation failed: {str(e)}")
    
    async def generate_pdf(self, content: str, template: str) -> str:
        """Generate PDF document"""
        filename = f"jarvis_document_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        file_path = os.path.join(self.temp_dir, filename)
        
        # Create PDF document
        doc = SimpleDocTemplate(file_path, pagesize=A4)
        story = []
        styles = getSampleStyleSheet()
        
        # Apply template styling
        template_config = self.templates.get(template, self.templates["default"])
        
        # Parse content and create PDF elements
        paragraphs = content.split('\n\n')
        for para in paragraphs:
            if para.strip():
                if para.startswith('#'):
                    # Header
                    story.append(Paragraph(para.lstrip('# '), styles['Heading1']))
                elif para.startswith('##'):
                    # Subheader
                    story.append(Paragraph(para.lstrip('## '), styles['Heading2']))
                else:
                    # Regular paragraph
                    story.append(Paragraph(para, styles['Normal']))
                story.append(Spacer(1, 0.2*inch))
        
        # Build PDF
        doc.build(story)
        return file_path
    
    async def generate_docx(self, content: str, template: str) -> str:
        """Generate DOCX document"""
        filename = f"jarvis_document_{datetime.now().strftime('%Y%m%d_%H%M%S')}.docx"
        file_path = os.path.join(self.temp_dir, filename)
        
        # Create Word document
        doc = Document()
        
        # Apply template styling
        template_config = self.templates.get(template, self.templates["default"])
        
        # Parse content and create Word elements
        paragraphs = content.split('\n\n')
        for para in paragraphs:
            if para.strip():
                if para.startswith('#'):
                    # Header
                    doc.add_heading(para.lstrip('# '), level=1)
                elif para.startswith('##'):
                    # Subheader
                    doc.add_heading(para.lstrip('## '), level=2)
                else:
                    # Regular paragraph
                    doc.add_paragraph(para)
        
        # Save document
        doc.save(file_path)
        return file_path
    
    async def generate_presentation(self, content: str, template: str) -> str:
        """Generate PowerPoint presentation"""
        filename = f"jarvis_presentation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pptx"
        file_path = os.path.join(self.temp_dir, filename)
        
        # Create presentation
        prs = Presentation()
        
        # Parse content into slides
        slides_content = content.split('\n---\n')  # Slide separator
        
        for slide_content in slides_content:
            if slide_content.strip():
                slide = prs.slides.add_slide(prs.slide_layouts[1])  # Title and Content layout
                
                lines = slide_content.strip().split('\n')
                if lines:
                    # First line as title
                    title = slide.shapes.title
                    title.text = lines[0].lstrip('# ')
                    
                    # Remaining lines as content
                    if len(lines) > 1:
                        content_shape = slide.placeholders[1]
                        content_shape.text = '\n'.join(lines[1:])
        
        # Save presentation
        prs.save(file_path)
        return file_path
    
    def is_available(self) -> bool:
        """Check if document generation service is available"""
        return os.path.exists(self.temp_dir) and os.access(self.temp_dir, os.W_OK)
```

### 3. Integration Protocol

#### 3.1 Request/Response Format
```json
// MCP Request Format
{
    "id": "uuid-string",
    "method": "generate_document|send_email|create_calendar_event|perform_web_search",
    "params": {
        // Method-specific parameters
    },
    "timestamp": "2025-06-26T10:30:00Z"
}

// MCP Response Format
{
    "id": "uuid-string",
    "success": true|false,
    "result": {
        // Method-specific result data
    },
    "error": "error message if success=false",
    "timestamp": "2025-06-26T10:30:05Z"
}
```

#### 3.2 Voice Command Examples
```
User: "Create a PDF report about our Q2 sales performance"
→ VoiceCommand.generateDocument(content: "Q2 Sales Performance Report...", format: .pdf)

User: "Send an email to john@company.com about tomorrow's meeting"
→ VoiceCommand.sendEmail(recipient: "john@company.com", subject: "Tomorrow's Meeting", body: "...")

User: "Schedule a team meeting for next Friday at 2 PM"
→ VoiceCommand.createEvent(title: "Team Meeting", date: nextFriday2PM, duration: 3600)

User: "Search for the latest iOS development best practices"
→ VoiceCommand.searchWeb(query: "iOS development best practices 2025", summarize: true)
```

---

## PERFORMANCE & SCALABILITY

### Performance Targets
- **Voice Command Classification:** <500ms for intent recognition
- **Document Generation:** <5 seconds for standard documents
- **Email Sending:** <2 seconds for simple emails
- **Calendar Event Creation:** <1 second for basic events
- **Web Search:** <3 seconds for search + summarization

### Scalability Architecture
- **Horizontal Scaling:** Multiple MCP server instances with load balancing
- **Caching Strategy:** Redis for frequently accessed data and templates
- **Rate Limiting:** Per-client request throttling to prevent abuse
- **Background Processing:** Async task queue for long-running operations

### Monitoring & Observability
- **Health Endpoints:** Real-time service status monitoring
- **Performance Metrics:** Request latency, throughput, error rates
- **Logging:** Structured logging with correlation IDs
- **Alerting:** Automated alerts for service degradation

---

## SECURITY & COMPLIANCE

### Authentication & Authorization
- **API Keys:** Secure storage in iOS Keychain
- **Token-based Auth:** JWT tokens for MCP server communication
- **Rate Limiting:** Prevent abuse and DoS attacks
- **Input Validation:** Comprehensive parameter validation

### Data Protection
- **Encryption:** All data encrypted in transit and at rest
- **Privacy:** Minimal data retention policies
- **Compliance:** GDPR, CCPA compliance measures
- **Audit Logging:** Complete audit trail for all operations

---

## DEPLOYMENT & OPERATIONS

### Development Environment
- **Python Environment:** Python 3.10+ with FastAPI
- **iOS Development:** Xcode with Swift Package Manager
- **Testing:** Comprehensive unit and integration tests
- **Local Development:** Docker containers for easy setup

### Production Deployment
- **Containerization:** Docker images for consistent deployment
- **Orchestration:** Kubernetes for production scaling
- **CI/CD:** Automated testing and deployment pipeline
- **Monitoring:** Prometheus, Grafana for production monitoring

---

## CONCLUSION

The MCP integration architecture provides a robust, scalable foundation for transforming Jarvis Live from a voice AI assistant into a comprehensive productivity platform. The modular design allows for incremental implementation and easy extension with additional services.

**Next Steps:**
1. Implement Python MCP server with FastAPI
2. Develop Swift MCPServerManager client
3. Create voice command classification system
4. Integration testing and performance optimization

This architecture supports the long-term vision of Jarvis Live as an AI-powered productivity assistant while maintaining the high-quality standards established in Phase 2 development.

---

*This document serves as the technical specification for MCP integration and will be updated as implementation progresses.*
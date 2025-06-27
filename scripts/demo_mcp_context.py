#!/usr/bin/env python3
"""
Demo script showing MCP context management functionality
This demonstrates how the iOS MCP context system would work in practice.

SANDBOX FILE: For testing/development. See .cursorrules.
"""

import asyncio
import json
from datetime import datetime
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from enum import Enum


class SessionState(Enum):
    IDLE = "idle"
    COLLECTING_PARAMETERS = "collecting_parameters"
    EXECUTING = "executing"
    AWAITING_CONFIRMATION = "awaiting_confirmation"
    ERROR = "error"


@dataclass
class MCPContextualResponse:
    message: str
    needs_user_input: bool
    context_state: SessionState
    suggested_actions: List[str]


class MCPContextManager:
    def __init__(self):
        self.active_contexts = {}
        self.context_history = {}
        
    def ensure_context_exists(self, conversation_id: str):
        if conversation_id not in self.active_contexts:
            self.active_contexts[conversation_id] = {
                "session_state": SessionState.IDLE,
                "current_tool": None,
                "pending_parameters": {},
                "required_parameters": [],
                "context_history": []
            }
    
    async def process_voice_command_with_context(self, command: str, conversation_id: str) -> MCPContextualResponse:
        self.ensure_context_exists(conversation_id)
        context = self.active_contexts[conversation_id]
        
        print(f"🔵 Processing: '{command}' (State: {context['session_state'].value})")
        
        if context["session_state"] == SessionState.IDLE:
            return await self._handle_idle_state(command, conversation_id)
        elif context["session_state"] == SessionState.COLLECTING_PARAMETERS:
            return await self._handle_parameter_collection(command, conversation_id)
        elif context["session_state"] == SessionState.AWAITING_CONFIRMATION:
            return await self._handle_confirmation(command, conversation_id)
        else:
            return MCPContextualResponse(
                message="I'm processing your request...",
                needs_user_input=False,
                context_state=SessionState.EXECUTING,
                suggested_actions=[]
            )
    
    async def _handle_idle_state(self, command: str, conversation_id: str) -> MCPContextualResponse:
        context = self.active_contexts[conversation_id]
        
        # Analyze command
        if "document" in command.lower() or "generate" in command.lower():
            context["current_tool"] = "document_generator"
            context["session_state"] = SessionState.COLLECTING_PARAMETERS
            
            # Check what parameters we already have
            if "pdf" in command.lower():
                context["pending_parameters"]["format"] = "pdf"
            elif "word" in command.lower():
                context["pending_parameters"]["format"] = "docx"
            
            # Extract content if provided
            content_keywords = ["about", "on", "regarding"]
            for keyword in content_keywords:
                if keyword in command.lower():
                    content_start = command.lower().find(keyword) + len(keyword) + 1
                    content = command[content_start:].strip()
                    if content:
                        context["pending_parameters"]["content"] = content
                        break
            
            # Determine what we still need
            required = ["content", "format"]
            missing = [param for param in required if param not in context["pending_parameters"]]
            
            if missing:
                context["required_parameters"] = missing
                next_param = missing[0]
                
                if next_param == "content":
                    return MCPContextualResponse(
                        message="What content would you like me to include in the document?",
                        needs_user_input=True,
                        context_state=SessionState.COLLECTING_PARAMETERS,
                        suggested_actions=["project updates", "meeting notes", "report"]
                    )
                elif next_param == "format":
                    return MCPContextualResponse(
                        message="What format would you prefer? (PDF, Word, HTML, etc.)",
                        needs_user_input=True,
                        context_state=SessionState.COLLECTING_PARAMETERS,
                        suggested_actions=["PDF", "Word document", "HTML"]
                    )
            else:
                # All parameters collected, go to confirmation
                context["session_state"] = SessionState.AWAITING_CONFIRMATION
                return await self._generate_confirmation_prompt(conversation_id)
        
        elif "email" in command.lower() or "send" in command.lower():
            context["current_tool"] = "email_sender"
            context["session_state"] = SessionState.COLLECTING_PARAMETERS
            context["required_parameters"] = ["to", "subject", "body"]
            
            return MCPContextualResponse(
                message="Who should I send the email to? Please provide email addresses.",
                needs_user_input=True,
                context_state=SessionState.COLLECTING_PARAMETERS,
                suggested_actions=["team@company.com", "manager@company.com"]
            )
        
        else:
            return MCPContextualResponse(
                message="I can help you generate documents, send emails, schedule meetings, or search for information. What would you like to do?",
                needs_user_input=True,
                context_state=SessionState.IDLE,
                suggested_actions=["generate document", "send email", "schedule meeting", "search"]
            )
    
    async def _handle_parameter_collection(self, command: str, conversation_id: str) -> MCPContextualResponse:
        context = self.active_contexts[conversation_id]
        
        # Extract parameters from the input
        if context["current_tool"] == "document_generator":
            if "content" in context["required_parameters"]:
                context["pending_parameters"]["content"] = command
                context["required_parameters"].remove("content")
            elif "format" in context["required_parameters"]:
                if "pdf" in command.lower():
                    context["pending_parameters"]["format"] = "pdf"
                elif "word" in command.lower() or "docx" in command.lower():
                    context["pending_parameters"]["format"] = "docx"
                elif "html" in command.lower():
                    context["pending_parameters"]["format"] = "html"
                else:
                    context["pending_parameters"]["format"] = "pdf"  # Default
                context["required_parameters"].remove("format")
        
        elif context["current_tool"] == "email_sender":
            if "to" in context["required_parameters"]:
                # Simple email extraction
                import re
                emails = re.findall(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', command)
                if emails:
                    context["pending_parameters"]["to"] = emails
                    context["required_parameters"].remove("to")
                else:
                    # Try common patterns
                    if "@" in command:
                        context["pending_parameters"]["to"] = [command.strip()]
                        context["required_parameters"].remove("to")
            elif "subject" in context["required_parameters"]:
                context["pending_parameters"]["subject"] = command
                context["required_parameters"].remove("subject")
            elif "body" in context["required_parameters"]:
                context["pending_parameters"]["body"] = command
                context["required_parameters"].remove("body")
        
        # Check if we still need more parameters
        if context["required_parameters"]:
            next_param = context["required_parameters"][0]
            
            if next_param == "format":
                return MCPContextualResponse(
                    message="What format would you prefer? (PDF, Word, HTML, etc.)",
                    needs_user_input=True,
                    context_state=SessionState.COLLECTING_PARAMETERS,
                    suggested_actions=["PDF", "Word document", "HTML"]
                )
            elif next_param == "subject":
                return MCPContextualResponse(
                    message="What should the subject line be?",
                    needs_user_input=True,
                    context_state=SessionState.COLLECTING_PARAMETERS,
                    suggested_actions=["Meeting follow-up", "Project update", "Quick question"]
                )
            elif next_param == "body":
                return MCPContextualResponse(
                    message="What should the email content be?",
                    needs_user_input=True,
                    context_state=SessionState.COLLECTING_PARAMETERS,
                    suggested_actions=["Thanks for the meeting...", "Quick update on...", "Following up on..."]
                )
        else:
            # All parameters collected
            context["session_state"] = SessionState.AWAITING_CONFIRMATION
            return await self._generate_confirmation_prompt(conversation_id)
    
    async def _handle_confirmation(self, command: str, conversation_id: str) -> MCPContextualResponse:
        context = self.active_contexts[conversation_id]
        
        # Analyze confirmation
        positive_words = ["yes", "okay", "ok", "sure", "proceed", "go ahead", "do it"]
        negative_words = ["no", "cancel", "stop", "don't", "abort"]
        
        command_lower = command.lower()
        is_confirmed = any(word in command_lower for word in positive_words)
        is_cancelled = any(word in command_lower for word in negative_words)
        
        if is_confirmed:
            # Execute the operation
            return await self._execute_operation(conversation_id)
        elif is_cancelled:
            # Cancel operation
            context["session_state"] = SessionState.IDLE
            context["current_tool"] = None
            context["pending_parameters"] = {}
            context["required_parameters"] = []
            
            return MCPContextualResponse(
                message="Operation cancelled. How else can I help you?",
                needs_user_input=False,
                context_state=SessionState.IDLE,
                suggested_actions=["generate document", "send email", "schedule meeting"]
            )
        else:
            return MCPContextualResponse(
                message="I didn't understand. Would you like me to proceed with the operation? Please say 'yes' to continue or 'no' to cancel.",
                needs_user_input=True,
                context_state=SessionState.AWAITING_CONFIRMATION,
                suggested_actions=["yes", "no", "cancel"]
            )
    
    async def _generate_confirmation_prompt(self, conversation_id: str) -> MCPContextualResponse:
        context = self.active_contexts[conversation_id]
        
        tool_name = context["current_tool"]
        params = context["pending_parameters"]
        
        if tool_name == "document_generator":
            summary = f"I'm ready to generate a {params.get('format', 'PDF').upper()} document"
            if 'content' in params:
                summary += f" about: {params['content']}"
            summary += "\n\nShould I proceed?"
        
        elif tool_name == "email_sender":
            to_list = params.get('to', [])
            if isinstance(to_list, list):
                to_str = ", ".join(to_list)
            else:
                to_str = str(to_list)
            
            summary = f"I'm ready to send an email:\n"
            summary += f"• To: {to_str}\n"
            summary += f"• Subject: {params.get('subject', 'No subject')}\n"
            summary += f"• Content: {params.get('body', 'No content')[:50]}...\n\n"
            summary += "Should I send this email?"
        
        else:
            summary = f"Ready to execute {tool_name} with the provided parameters. Should I proceed?"
        
        return MCPContextualResponse(
            message=summary,
            needs_user_input=True,
            context_state=SessionState.AWAITING_CONFIRMATION,
            suggested_actions=["yes", "no", "modify"]
        )
    
    async def _execute_operation(self, conversation_id: str) -> MCPContextualResponse:
        context = self.active_contexts[conversation_id]
        
        tool_name = context["current_tool"]
        params = context["pending_parameters"]
        
        # Simulate operation execution
        await asyncio.sleep(0.5)  # Simulate processing time
        
        # Add to history
        context["context_history"].append({
            "timestamp": datetime.now().isoformat(),
            "tool": tool_name,
            "parameters": params.copy(),
            "success": True
        })
        
        # Reset context to idle
        context["session_state"] = SessionState.IDLE
        context["current_tool"] = None
        context["pending_parameters"] = {}
        context["required_parameters"] = []
        
        if tool_name == "document_generator":
            format_type = params.get('format', 'PDF')
            return MCPContextualResponse(
                message=f"✅ {format_type.upper()} document generated successfully! The document has been saved and is ready for use.",
                needs_user_input=False,
                context_state=SessionState.IDLE,
                suggested_actions=["generate another document", "send email", "help with something else"]
            )
        
        elif tool_name == "email_sender":
            to_count = len(params.get('to', []))
            return MCPContextualResponse(
                message=f"✅ Email sent successfully to {to_count} recipient(s)! Message ID: msg_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
                needs_user_input=False,
                context_state=SessionState.IDLE,
                suggested_actions=["send another email", "generate document", "help with something else"]
            )
        
        else:
            return MCPContextualResponse(
                message=f"✅ {tool_name} completed successfully!",
                needs_user_input=False,
                context_state=SessionState.IDLE,
                suggested_actions=["help with something else"]
            )


async def demonstrate_mcp_context():
    """Demonstrate the MCP context management system"""
    
    print("🚀 MCP Context Management System Demo")
    print("=" * 50)
    
    context_manager = MCPContextManager()
    conversation_id = "demo_conversation_001"
    
    # Demo 1: Document Generation
    print("\n📄 Demo 1: Multi-turn Document Generation")
    print("-" * 40)
    
    scenarios = [
        "Generate a document",
        "About quarterly sales results",
        "PDF format",
        "Yes, proceed"
    ]
    
    for i, command in enumerate(scenarios, 1):
        print(f"\nStep {i}:")
        response = await context_manager.process_voice_command_with_context(command, conversation_id)
        print(f"🤖 AI: {response.message}")
        print(f"📊 State: {response.context_state.value}, Needs Input: {response.needs_user_input}")
        if response.suggested_actions:
            print(f"💡 Suggestions: {', '.join(response.suggested_actions)}")
    
    # Demo 2: Email Composition
    print("\n\n📧 Demo 2: Multi-turn Email Composition")
    print("-" * 40)
    
    email_scenarios = [
        "Send an email",
        "john@example.com and sarah@company.com",
        "Meeting follow-up",
        "Thanks for attending today's meeting. Here are the action items we discussed.",
        "Yes, send it"
    ]
    
    conversation_id_2 = "demo_conversation_002"
    
    for i, command in enumerate(email_scenarios, 1):
        print(f"\nStep {i}:")
        response = await context_manager.process_voice_command_with_context(command, conversation_id_2)
        print(f"🤖 AI: {response.message}")
        print(f"📊 State: {response.context_state.value}, Needs Input: {response.needs_user_input}")
        if response.suggested_actions:
            print(f"💡 Suggestions: {', '.join(response.suggested_actions)}")
    
    # Demo 3: Error Recovery
    print("\n\n🔧 Demo 3: Error Recovery and Cancellation")
    print("-" * 45)
    
    error_scenarios = [
        "Generate a document",
        "Project status report",
        "cancel"  # User decides to cancel
    ]
    
    conversation_id_3 = "demo_conversation_003"
    
    for i, command in enumerate(error_scenarios, 1):
        print(f"\nStep {i}:")
        response = await context_manager.process_voice_command_with_context(command, conversation_id_3)
        print(f"🤖 AI: {response.message}")
        print(f"📊 State: {response.context_state.value}, Needs Input: {response.needs_user_input}")
        if response.suggested_actions:
            print(f"💡 Suggestions: {', '.join(response.suggested_actions)}")
    
    # Show context persistence
    print("\n\n📈 Context Analysis")
    print("-" * 20)
    print(f"Active contexts: {len(context_manager.active_contexts)}")
    for conv_id, context in context_manager.active_contexts.items():
        print(f"  {conv_id}: {len(context['context_history'])} operations completed")
    
    print("\n✅ Demo completed! This demonstrates how the iOS MCP context system maintains conversation state across multiple turns.")


if __name__ == "__main__":
    asyncio.run(demonstrate_mcp_context())
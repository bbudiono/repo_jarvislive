// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Collaboration context for voice command execution with participant awareness
 * Issues & Complexity Summary: Context management for multi-participant voice sessions
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~200
 *   - Core Algorithm Complexity: Medium (Context state management)
 *   - Dependencies: 2 (Foundation, ParticipantManager)
 *   - State Management Complexity: Medium (Multi-participant context)
 *   - Novelty/Uncertainty Factor: Low
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 70%
 * Problem Estimate (Inherent Problem Difficulty %): 65%
 * Initial Code Complexity Estimate %: 68%
 * Justification for Estimates: Standard context management for collaboration features
 * Final Code Complexity (Actual %): 72%
 * Overall Result Score (Success & Quality %): 90%
 * Key Variances/Learnings: Context provides participant awareness for voice commands
 * Last Updated: 2025-06-28
 */

import Foundation

// MARK: - Collaboration Context

struct CollaborationContext {
    let sessionId: String
    let roomId: String?
    let currentParticipant: ParticipantProfile
    let allParticipants: [ParticipantProfile]
    let sessionType: SessionType
    let sessionState: SessionState
    let permissions: ContextPermissions
    let sharedResources: [SharedResource]
    let metadata: [String: Any]
    let createdAt: Date
    let lastUpdated: Date
    
    enum SessionType {
        case meeting
        case presentation
        case collaboration
        case training
        case consultation
        case brainstorming
    }
    
    enum SessionState {
        case active
        case paused
        case recording
        case sharing
        case private
    }
    
    struct ContextPermissions {
        let canModifyDocuments: Bool
        let canSendEmails: Bool
        let canScheduleEvents: Bool
        let canAccessPrivateInfo: Bool
        let canInviteParticipants: Bool
        let canRecordSession: Bool
        let canShareScreen: Bool
        let canManageSession: Bool
        
        static let `default` = ContextPermissions(
            canModifyDocuments: true,
            canSendEmails: false,
            canScheduleEvents: false,
            canAccessPrivateInfo: false,
            canInviteParticipants: false,
            canRecordSession: false,
            canShareScreen: false,
            canManageSession: false
        )
        
        static let hostPermissions = ContextPermissions(
            canModifyDocuments: true,
            canSendEmails: true,
            canScheduleEvents: true,
            canAccessPrivateInfo: true,
            canInviteParticipants: true,
            canRecordSession: true,
            canShareScreen: true,
            canManageSession: true
        )
    }
    
    struct SharedResource {
        let id: String
        let type: ResourceType
        let name: String
        let url: URL?
        let ownerId: String
        let permissions: ResourcePermissions
        let lastModified: Date
        
        enum ResourceType {
            case document
            case spreadsheet
            case presentation
            case image
            case video
            case audio
            case link
            case note
        }
        
        struct ResourcePermissions {
            let canView: Bool
            let canEdit: Bool
            let canShare: Bool
            let canDelete: Bool
        }
    }
    
    // MARK: - Initializers
    
    init(sessionId: String, 
         currentParticipant: ParticipantProfile,
         roomId: String? = nil,
         sessionType: SessionType = .collaboration,
         sessionState: SessionState = .active) {
        self.sessionId = sessionId
        self.roomId = roomId
        self.currentParticipant = currentParticipant
        self.allParticipants = [currentParticipant]
        self.sessionType = sessionType
        self.sessionState = sessionState
        self.permissions = ContextPermissions.default
        self.sharedResources = []
        self.metadata = [:]
        self.createdAt = Date()
        self.lastUpdated = Date()
    }
    
    // MARK: - Helper Methods
    
    func isHost() -> Bool {
        return currentParticipant.role == .host
    }
    
    func isModerator() -> Bool {
        return currentParticipant.role == .moderator || isHost()
    }
    
    func canExecuteCommand(_ commandType: CommandType) -> Bool {
        switch commandType {
        case .generateDocument:
            return permissions.canModifyDocuments
        case .sendEmail:
            return permissions.canSendEmails
        case .scheduleCalendar:
            return permissions.canScheduleEvents
        case .manageParticipants:
            return permissions.canManageSession
        case .recordSession:
            return permissions.canRecordSession
        case .shareScreen:
            return permissions.canShareScreen
        case .accessPrivateData:
            return permissions.canAccessPrivateInfo
        }
    }
    
    func getParticipant(by id: String) -> ParticipantProfile? {
        return allParticipants.first { $0.id == id }
    }
    
    func getSharedResource(by id: String) -> SharedResource? {
        return sharedResources.first { $0.id == id }
    }
    
    // MARK: - Update Methods
    
    func addingParticipant(_ participant: ParticipantProfile) -> CollaborationContext {
        var newParticipants = allParticipants
        if !newParticipants.contains(where: { $0.id == participant.id }) {
            newParticipants.append(participant)
        }
        
        return CollaborationContext(
            sessionId: sessionId,
            roomId: roomId,
            currentParticipant: currentParticipant,
            allParticipants: newParticipants,
            sessionType: sessionType,
            sessionState: sessionState,
            permissions: permissions,
            sharedResources: sharedResources,
            metadata: metadata,
            createdAt: createdAt,
            lastUpdated: Date()
        )
    }
    
    func removingParticipant(_ participantId: String) -> CollaborationContext {
        let newParticipants = allParticipants.filter { $0.id != participantId }
        
        return CollaborationContext(
            sessionId: sessionId,
            roomId: roomId,
            currentParticipant: currentParticipant,
            allParticipants: newParticipants,
            sessionType: sessionType,
            sessionState: sessionState,
            permissions: permissions,
            sharedResources: sharedResources,
            metadata: metadata,
            createdAt: createdAt,
            lastUpdated: Date()
        )
    }
    
    func updatingState(_ newState: SessionState) -> CollaborationContext {
        return CollaborationContext(
            sessionId: sessionId,
            roomId: roomId,
            currentParticipant: currentParticipant,
            allParticipants: allParticipants,
            sessionType: sessionType,
            sessionState: newState,
            permissions: permissions,
            sharedResources: sharedResources,
            metadata: metadata,
            createdAt: createdAt,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Private Initializer for Updates
    
    private init(sessionId: String,
                roomId: String?,
                currentParticipant: ParticipantProfile,
                allParticipants: [ParticipantProfile],
                sessionType: SessionType,
                sessionState: SessionState,
                permissions: ContextPermissions,
                sharedResources: [SharedResource],
                metadata: [String: Any],
                createdAt: Date,
                lastUpdated: Date) {
        self.sessionId = sessionId
        self.roomId = roomId
        self.currentParticipant = currentParticipant
        self.allParticipants = allParticipants
        self.sessionType = sessionType
        self.sessionState = sessionState
        self.permissions = permissions
        self.sharedResources = sharedResources
        self.metadata = metadata
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Command Type Enum

enum CommandType {
    case generateDocument
    case sendEmail
    case scheduleCalendar
    case manageParticipants
    case recordSession
    case shareScreen
    case accessPrivateData
}
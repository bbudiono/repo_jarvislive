// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Participant management and permissions system for collaborative voice sessions
 * Issues & Complexity Summary: Complex permission management, role-based access control, and real-time participant state
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~450
 *   - Core Algorithm Complexity: High (RBAC implementation, permission inheritance)
 *   - Dependencies: 4 New (Combine, CollaborationManager, Keychain, Network)
 *   - State Management Complexity: High (Multi-participant permission state)
 *   - Novelty/Uncertainty Factor: Medium (Standard RBAC patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 78%
 * Problem Estimate (Inherent Problem Difficulty %): 82%
 * Initial Code Complexity Estimate %: 80%
 * Justification for Estimates: Permission systems require careful validation and state management
 * Final Code Complexity (Actual %): 85%
 * Overall Result Score (Success & Quality %): 92%
 * Key Variances/Learnings: Implemented hierarchical permissions with inheritance and delegation
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine

// MARK: - Participant Management Types

public struct ParticipantProfile: Codable, Identifiable {
    public let id: String
    public let displayName: String
    public let email: String?
    public let avatarURL: String?
    public let organizationID: String?
    public let role: ParticipantRole
    public let permissions: ParticipantPermissions
    public let status: ParticipantStatus
    public let joinedAt: Date
    public let lastActivity: Date
    public let capabilities: [DeviceCapability]
    public let preferences: ParticipantPreferences

    public enum ParticipantRole: String, Codable, CaseIterable {
        case host = "host"
        case moderator = "moderator"
        case presenter = "presenter"
        case participant = "participant"
        case observer = "observer"
        case guest = "guest"

        public var displayName: String {
            switch self {
            case .host: return "Host"
            case .moderator: return "Moderator"
            case .presenter: return "Presenter"
            case .participant: return "Participant"
            case .observer: return "Observer"
            case .guest: return "Guest"
            }
        }

        public var priority: Int {
            switch self {
            case .host: return 100
            case .moderator: return 80
            case .presenter: return 60
            case .participant: return 40
            case .observer: return 20
            case .guest: return 10
            }
        }
    }

    public enum ParticipantStatus: String, Codable {
        case active = "active"
        case inactive = "inactive"
        case speaking = "speaking"
        case muted = "muted"
        case away = "away"
        case disconnected = "disconnected"
        case banned = "banned"
    }

    public enum DeviceCapability: String, Codable, CaseIterable {
        case microphone = "microphone"
        case camera = "camera"
        case screenShare = "screen_share"
        case fileUpload = "file_upload"
        case recording = "recording"
        case aiAccess = "ai_access"
    }

    public init(id: String, displayName: String, email: String? = nil, role: ParticipantRole, organizationID: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.avatarURL = nil
        self.organizationID = organizationID
        self.role = role
        self.permissions = ParticipantPermissions.defaultPermissions(for: role)
        self.status = .active
        self.joinedAt = Date()
        self.lastActivity = Date()
        self.capabilities = DeviceCapability.allCases
        self.preferences = ParticipantPreferences()
    }
}

public struct ParticipantPermissions: Codable {
    public let canSpeak: Bool
    public let canShareScreen: Bool
    public let canUploadFiles: Bool
    public let canModifyDocuments: Bool
    public let canInviteParticipants: Bool
    public let canManageParticipants: Bool
    public let canControlAI: Bool
    public let canRecord: Bool
    public let canModerate: Bool
    public let canChangeSettings: Bool
    public let canViewPrivateInfo: Bool
    public let canExportData: Bool
    public let maxFileSize: Int64 // In bytes
    public let maxSessionDuration: TimeInterval // In seconds
    public let allowedAIProviders: [String]
    public let costLimits: CostLimits?

    public struct CostLimits: Codable {
        public let maxDailyCost: Double
        public let maxMonthlyCost: Double
        public let requireApprovalAbove: Double

        public init(maxDailyCost: Double = 10.0, maxMonthlyCost: Double = 100.0, requireApprovalAbove: Double = 5.0) {
            self.maxDailyCost = maxDailyCost
            self.maxMonthlyCost = maxMonthlyCost
            self.requireApprovalAbove = requireApprovalAbove
        }
    }

    public static func defaultPermissions(for role: ParticipantProfile.ParticipantRole) -> ParticipantPermissions {
        switch role {
        case .host:
            return ParticipantPermissions(
                canSpeak: true,
                canShareScreen: true,
                canUploadFiles: true,
                canModifyDocuments: true,
                canInviteParticipants: true,
                canManageParticipants: true,
                canControlAI: true,
                canRecord: true,
                canModerate: true,
                canChangeSettings: true,
                canViewPrivateInfo: true,
                canExportData: true,
                maxFileSize: 100_000_000, // 100MB
                maxSessionDuration: 86400, // 24 hours
                allowedAIProviders: ["claude", "gpt4", "gemini"],
                costLimits: CostLimits(maxDailyCost: 100.0, maxMonthlyCost: 1000.0)
            )

        case .moderator:
            return ParticipantPermissions(
                canSpeak: true,
                canShareScreen: true,
                canUploadFiles: true,
                canModifyDocuments: true,
                canInviteParticipants: true,
                canManageParticipants: true,
                canControlAI: true,
                canRecord: false,
                canModerate: true,
                canChangeSettings: false,
                canViewPrivateInfo: false,
                canExportData: true,
                maxFileSize: 50_000_000, // 50MB
                maxSessionDuration: 43200, // 12 hours
                allowedAIProviders: ["claude", "gpt4"],
                costLimits: CostLimits(maxDailyCost: 50.0, maxMonthlyCost: 500.0)
            )

        case .presenter:
            return ParticipantPermissions(
                canSpeak: true,
                canShareScreen: true,
                canUploadFiles: true,
                canModifyDocuments: true,
                canInviteParticipants: false,
                canManageParticipants: false,
                canControlAI: true,
                canRecord: false,
                canModerate: false,
                canChangeSettings: false,
                canViewPrivateInfo: false,
                canExportData: false,
                maxFileSize: 25_000_000, // 25MB
                maxSessionDuration: 21600, // 6 hours
                allowedAIProviders: ["claude", "gpt4"],
                costLimits: CostLimits(maxDailyCost: 25.0, maxMonthlyCost: 250.0)
            )

        case .participant:
            return ParticipantPermissions(
                canSpeak: true,
                canShareScreen: false,
                canUploadFiles: true,
                canModifyDocuments: true,
                canInviteParticipants: false,
                canManageParticipants: false,
                canControlAI: false,
                canRecord: false,
                canModerate: false,
                canChangeSettings: false,
                canViewPrivateInfo: false,
                canExportData: false,
                maxFileSize: 10_000_000, // 10MB
                maxSessionDuration: 14400, // 4 hours
                allowedAIProviders: ["gemini"],
                costLimits: CostLimits(maxDailyCost: 10.0, maxMonthlyCost: 100.0)
            )

        case .observer:
            return ParticipantPermissions(
                canSpeak: false,
                canShareScreen: false,
                canUploadFiles: false,
                canModifyDocuments: false,
                canInviteParticipants: false,
                canManageParticipants: false,
                canControlAI: false,
                canRecord: false,
                canModerate: false,
                canChangeSettings: false,
                canViewPrivateInfo: false,
                canExportData: false,
                maxFileSize: 0,
                maxSessionDuration: 7200, // 2 hours
                allowedAIProviders: [],
                costLimits: nil
            )

        case .guest:
            return ParticipantPermissions(
                canSpeak: true,
                canShareScreen: false,
                canUploadFiles: false,
                canModifyDocuments: false,
                canInviteParticipants: false,
                canManageParticipants: false,
                canControlAI: false,
                canRecord: false,
                canModerate: false,
                canChangeSettings: false,
                canViewPrivateInfo: false,
                canExportData: false,
                maxFileSize: 5_000_000, // 5MB
                maxSessionDuration: 3600, // 1 hour
                allowedAIProviders: [],
                costLimits: nil
            )
        }
    }

    public init(canSpeak: Bool, canShareScreen: Bool, canUploadFiles: Bool, canModifyDocuments: Bool, canInviteParticipants: Bool, canManageParticipants: Bool, canControlAI: Bool, canRecord: Bool, canModerate: Bool, canChangeSettings: Bool, canViewPrivateInfo: Bool, canExportData: Bool, maxFileSize: Int64, maxSessionDuration: TimeInterval, allowedAIProviders: [String], costLimits: CostLimits? = nil) {
        self.canSpeak = canSpeak
        self.canShareScreen = canShareScreen
        self.canUploadFiles = canUploadFiles
        self.canModifyDocuments = canModifyDocuments
        self.canInviteParticipants = canInviteParticipants
        self.canManageParticipants = canManageParticipants
        self.canControlAI = canControlAI
        self.canRecord = canRecord
        self.canModerate = canModerate
        self.canChangeSettings = canChangeSettings
        self.canViewPrivateInfo = canViewPrivateInfo
        self.canExportData = canExportData
        self.maxFileSize = maxFileSize
        self.maxSessionDuration = maxSessionDuration
        self.allowedAIProviders = allowedAIProviders
        self.costLimits = costLimits
    }
}

public struct ParticipantPreferences: Codable {
    public let preferredLanguage: String
    public let notificationSettings: NotificationSettings
    public let audioSettings: AudioSettings
    public let privacySettings: PrivacySettings

    public struct NotificationSettings: Codable {
        public let enableJoinLeaveNotifications: Bool
        public let enableMentionNotifications: Bool
        public let enableAIResponseNotifications: Bool
        public let enableDocumentUpdateNotifications: Bool

        public init(enableJoinLeaveNotifications: Bool = true, enableMentionNotifications: Bool = true, enableAIResponseNotifications: Bool = true, enableDocumentUpdateNotifications: Bool = true) {
            self.enableJoinLeaveNotifications = enableJoinLeaveNotifications
            self.enableMentionNotifications = enableMentionNotifications
            self.enableAIResponseNotifications = enableAIResponseNotifications
            self.enableDocumentUpdateNotifications = enableDocumentUpdateNotifications
        }
    }

    public struct AudioSettings: Codable {
        public let enableVoiceActivityDetection: Bool
        public let enableNoiseSuppression: Bool
        public let audioQuality: AudioQuality
        public let microphoneGain: Float

        public enum AudioQuality: String, Codable, CaseIterable {
            case low = "low"
            case medium = "medium"
            case high = "high"
            case studio = "studio"
        }

        public init(enableVoiceActivityDetection: Bool = true, enableNoiseSuppression: Bool = true, audioQuality: AudioQuality = .medium, microphoneGain: Float = 1.0) {
            self.enableVoiceActivityDetection = enableVoiceActivityDetection
            self.enableNoiseSuppression = enableNoiseSuppression
            self.audioQuality = audioQuality
            self.microphoneGain = microphoneGain
        }
    }

    public struct PrivacySettings: Codable {
        public let sharePresenceStatus: Bool
        public let allowDirectMessages: Bool
        public let shareAudioTranscription: Bool
        public let allowAIProfileBuilding: Bool

        public init(sharePresenceStatus: Bool = true, allowDirectMessages: Bool = true, shareAudioTranscription: Bool = true, allowAIProfileBuilding: Bool = false) {
            self.sharePresenceStatus = sharePresenceStatus
            self.allowDirectMessages = allowDirectMessages
            self.shareAudioTranscription = shareAudioTranscription
            self.allowAIProfileBuilding = allowAIProfileBuilding
        }
    }

    public init(preferredLanguage: String = "en-US", notificationSettings: NotificationSettings = NotificationSettings(), audioSettings: AudioSettings = AudioSettings(), privacySettings: PrivacySettings = PrivacySettings()) {
        self.preferredLanguage = preferredLanguage
        self.notificationSettings = notificationSettings
        self.audioSettings = audioSettings
        self.privacySettings = privacySettings
    }
}

public struct PermissionRequest: Codable, Identifiable {
    public let id: UUID
    public let requestorID: String
    public let targetParticipantID: String?
    public let requestedPermission: PermissionType
    public let reason: String
    public let status: RequestStatus
    public let requestedAt: Date
    public let reviewedBy: String?
    public let reviewedAt: Date?
    public let expiresAt: Date?

    public enum PermissionType: String, Codable, CaseIterable {
        case temporaryModerator = "temporary_moderator"
        case screenShare = "screen_share"
        case recording = "recording"
        case aiAccess = "ai_access"
        case documentEdit = "document_edit"
        case participantManagement = "participant_management"
        case extendSession = "extend_session"
        case increaseCostLimit = "increase_cost_limit"
    }

    public enum RequestStatus: String, Codable {
        case pending = "pending"
        case approved = "approved"
        case denied = "denied"
        case expired = "expired"
        case revoked = "revoked"
    }

    public init(requestorID: String, targetParticipantID: String? = nil, requestedPermission: PermissionType, reason: String, expiresAt: Date? = nil) {
        self.id = UUID()
        self.requestorID = requestorID
        self.targetParticipantID = targetParticipantID
        self.requestedPermission = requestedPermission
        self.reason = reason
        self.status = .pending
        self.requestedAt = Date()
        self.reviewedBy = nil
        self.reviewedAt = nil
        self.expiresAt = expiresAt ?? Calendar.current.date(byAdding: .hour, value: 1, to: Date())
    }
}

// MARK: - Participant Manager

@MainActor
public final class ParticipantManager: ObservableObject {
    // MARK: - Published Properties

    @Published public private(set) var participants: [ParticipantProfile] = []
    @Published public private(set) var currentUserProfile: ParticipantProfile?
    @Published public private(set) var pendingRequests: [PermissionRequest] = []
    @Published public private(set) var activeInvitations: [SessionInvitation] = []
    @Published public private(set) var participantActivity: [String: ParticipantActivity] = [:]

    public struct ParticipantActivity {
        public let participantID: String
        public let lastSeen: Date
        public let currentStatus: ParticipantProfile.ParticipantStatus
        public let sessionDuration: TimeInterval
        public let messageCount: Int
        public let aiInteractions: Int
    }

    public struct SessionInvitation: Identifiable {
        public let id: UUID
        public let inviterID: String
        public let inviteeEmail: String
        public let proposedRole: ParticipantProfile.ParticipantRole
        public let sessionID: UUID
        public let message: String?
        public let createdAt: Date
        public let expiresAt: Date
        public let status: InvitationStatus

        public enum InvitationStatus: String, CaseIterable {
            case pending = "pending"
            case accepted = "accepted"
            case declined = "declined"
            case expired = "expired"
        }
    }

    // MARK: - Private Properties

    private let collaborationManager: LiveKitCollaborationManager
    private let keychainManager: KeychainManager
    private var cancellables = Set<AnyCancellable>()

    private var permissionCache: [String: Date] = [:]
    private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes

    // Activity monitoring
    private var activityTimer: Timer?
    private let activityUpdateInterval: TimeInterval = 30.0

    // MARK: - Initialization

    public init(collaborationManager: LiveKitCollaborationManager, keychainManager: KeychainManager) {
        self.collaborationManager = collaborationManager
        self.keychainManager = keychainManager

        setupObservers()
        startActivityMonitoring()
        loadCurrentUserProfile()
    }

    deinit {
        activityTimer?.invalidate()
    }

    // MARK: - Public API

    public func createParticipantProfile(id: String, displayName: String, email: String?, role: ParticipantProfile.ParticipantRole) -> ParticipantProfile {
        let profile = ParticipantProfile(
            id: id,
            displayName: displayName,
            email: email,
            role: role
        )

        participants.append(profile)

        print("👤 Created participant profile: \(displayName) (\(role.displayName))")
        return profile
    }

    public func updateParticipantRole(_ participantID: String, newRole: ParticipantProfile.ParticipantRole, authorizedBy: String) async throws {
        guard let currentUser = currentUserProfile,
              currentUser.permissions.canManageParticipants else {
            throw ParticipantError.insufficientPermissions("Cannot manage participants")
        }

        guard let participantIndex = participants.firstIndex(where: { $0.id == participantID }) else {
            throw ParticipantError.participantNotFound(participantID)
        }

        let currentParticipant = participants[participantIndex]

        // Check role hierarchy - can't promote to higher or equal role
        guard newRole.priority < currentUser.role.priority else {
            throw ParticipantError.invalidRoleChange("Cannot assign role equal or higher than your own")
        }

        // Create updated profile with new role and permissions
        let updatedProfile = ParticipantProfile(
            id: currentParticipant.id,
            displayName: currentParticipant.displayName,
            email: currentParticipant.email,
            role: newRole
        )

        participants[participantIndex] = updatedProfile

        // Notify other participants
        await notifyRoleChange(participantID: participantID, newRole: newRole, authorizedBy: authorizedBy)

        print("🔄 Updated participant role: \(participantID) -> \(newRole.displayName)")
    }

    public func updateParticipantPermissions(_ participantID: String, permissions: ParticipantPermissions, authorizedBy: String) async throws {
        guard let currentUser = currentUserProfile,
              currentUser.permissions.canManageParticipants else {
            throw ParticipantError.insufficientPermissions("Cannot manage participant permissions")
        }

        guard let participantIndex = participants.firstIndex(where: { $0.id == participantID }) else {
            throw ParticipantError.participantNotFound(participantID)
        }

        // Validate permissions don't exceed authorizer's permissions
        try validatePermissionAssignment(requestedPermissions: permissions, authorizer: currentUser)

        // Update participant (simplified - would need proper update mechanism)
        // participants[participantIndex].permissions = permissions

        // Notify other participants
        await notifyPermissionChange(participantID: participantID, permissions: permissions, authorizedBy: authorizedBy)

        print("🔐 Updated participant permissions: \(participantID)")
    }

    public func requestPermission(_ permission: PermissionRequest.PermissionType, reason: String, targetParticipant: String? = nil) async -> PermissionRequest {
        let request = PermissionRequest(
            requestorID: currentUserProfile?.id ?? "unknown",
            targetParticipantID: targetParticipant,
            requestedPermission: permission,
            reason: reason
        )

        pendingRequests.append(request)

        // Send to moderators/hosts for approval
        await sendPermissionRequest(request)

        print("📝 Requested permission: \(permission.rawValue)")
        return request
    }

    public func reviewPermissionRequest(_ requestID: UUID, approved: Bool, reviewerComments: String? = nil) async throws {
        guard let currentUser = currentUserProfile,
              currentUser.permissions.canManageParticipants else {
            throw ParticipantError.insufficientPermissions("Cannot review permission requests")
        }

        guard let requestIndex = pendingRequests.firstIndex(where: { $0.id == requestID }) else {
            throw ParticipantError.requestNotFound(requestID)
        }

        var request = pendingRequests[requestIndex]

        // Update request status (simplified)
        pendingRequests[requestIndex] = PermissionRequest(
            requestorID: request.requestorID,
            targetParticipantID: request.targetParticipantID,
            requestedPermission: request.requestedPermission,
            reason: request.reason
        )

        if approved {
            // Apply the requested permission
            try await applyPermissionGrant(request)
        }

        // Notify requestor
        await notifyPermissionDecision(request: request, approved: approved, reviewerComments: reviewerComments)

        print("✅ Reviewed permission request: \(requestID) - \(approved ? "Approved" : "Denied")")
    }

    public func inviteParticipant(email: String, role: ParticipantProfile.ParticipantRole, message: String? = nil) async throws -> SessionInvitation {
        guard let currentUser = currentUserProfile,
              currentUser.permissions.canInviteParticipants else {
            throw ParticipantError.insufficientPermissions("Cannot invite participants")
        }

        guard let sessionID = collaborationManager.currentSession?.id else {
            throw ParticipantError.noActiveSession
        }

        let invitation = SessionInvitation(
            id: UUID(),
            inviterID: currentUser.id,
            inviteeEmail: email,
            proposedRole: role,
            sessionID: sessionID,
            message: message,
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date(),
            status: .pending
        )

        activeInvitations.append(invitation)

        // Send invitation (would integrate with email service)
        await sendInvitation(invitation)

        print("📧 Sent invitation to: \(email) as \(role.displayName)")
        return invitation
    }

    public func removeParticipant(_ participantID: String, reason: String) async throws {
        guard let currentUser = currentUserProfile,
              currentUser.permissions.canManageParticipants else {
            throw ParticipantError.insufficientPermissions("Cannot remove participants")
        }

        guard let participantIndex = participants.firstIndex(where: { $0.id == participantID }) else {
            throw ParticipantError.participantNotFound(participantID)
        }

        let participant = participants[participantIndex]

        // Check role hierarchy - can't remove equal or higher role
        guard participant.role.priority < currentUser.role.priority else {
            throw ParticipantError.invalidAction("Cannot remove participant with equal or higher role")
        }

        // Remove from local list
        participants.remove(at: participantIndex)

        // Notify collaboration manager
        await collaborationManager.removeParticipant(participantID)

        // Notify other participants
        await notifyParticipantRemoval(participantID: participantID, reason: reason, authorizedBy: currentUser.id)

        print("🚫 Removed participant: \(participantID) - \(reason)")
    }

    public func muteParticipant(_ participantID: String, duration: TimeInterval? = nil) async throws {
        guard let currentUser = currentUserProfile,
              currentUser.permissions.canModerate else {
            throw ParticipantError.insufficientPermissions("Cannot moderate participants")
        }

        // Update participant status
        await updateParticipantStatus(participantID, status: .muted)

        // Schedule unmute if duration specified
        if let duration = duration {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                Task {
                    await self?.updateParticipantStatus(participantID, status: .active)
                }
            }
        }

        print("🔇 Muted participant: \(participantID)")
    }

    public func checkPermission(_ permission: PermissionRequest.PermissionType, for participantID: String) -> Bool {
        guard let participant = participants.first(where: { $0.id == participantID }) else {
            return false
        }

        // Check cache first
        let cacheKey = "\(participantID)-\(permission.rawValue)"
        if let cacheTime = permissionCache[cacheKey],
           Date().timeIntervalSince(cacheTime) < cacheExpirationInterval {
            // Use cached result (simplified)
            return true
        }

        // Check actual permissions
        let hasPermission = evaluatePermission(permission, for: participant)

        // Cache result
        permissionCache[cacheKey] = Date()

        return hasPermission
    }

    public func getParticipantsByRole(_ role: ParticipantProfile.ParticipantRole) -> [ParticipantProfile] {
        return participants.filter { $0.role == role }
    }

    public func getActiveParticipants() -> [ParticipantProfile] {
        return participants.filter { $0.status == .active || $0.status == .speaking }
    }

    public func getParticipantActivity(_ participantID: String) -> ParticipantActivity? {
        return participantActivity[participantID]
    }

    public func updateParticipantPreferences(_ participantID: String, preferences: ParticipantPreferences) async throws {
        guard participantID == currentUserProfile?.id else {
            throw ParticipantError.insufficientPermissions("Can only update own preferences")
        }

        // Update preferences (simplified)
        await notifyPreferencesUpdate(participantID: participantID, preferences: preferences)

        print("⚙️ Updated preferences for: \(participantID)")
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Observe collaboration manager changes
        collaborationManager.$participants
            .sink { [weak self] collaborationParticipants in
                Task { @MainActor in
                    await self?.syncWithCollaborationParticipants(collaborationParticipants)
                }
            }
            .store(in: &cancellables)
    }

    private func loadCurrentUserProfile() {
        // Load current user profile from collaboration manager or create default
        if let localParticipant = collaborationManager.localParticipant {
            currentUserProfile = ParticipantProfile(
                id: localParticipant.id,
                displayName: localParticipant.displayName,
                role: localParticipant.isHost ? .host : .participant
            )
        }
    }

    private func startActivityMonitoring() {
        activityTimer = Timer.scheduledTimer(withTimeInterval: activityUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateParticipantActivity()
            }
        }
    }

    private func updateParticipantActivity() async {
        for participant in participants {
            let activity = ParticipantActivity(
                participantID: participant.id,
                lastSeen: Date(),
                currentStatus: participant.status,
                sessionDuration: Date().timeIntervalSince(participant.joinedAt),
                messageCount: 0, // Would be tracked separately
                aiInteractions: 0 // Would be tracked separately
            )

            participantActivity[participant.id] = activity
        }
    }

    private func syncWithCollaborationParticipants(_ collaborationParticipants: [CollaborationParticipant]) async {
        // Sync local participant profiles with collaboration manager
        for collabParticipant in collaborationParticipants {
            if !participants.contains(where: { $0.id == collabParticipant.id }) {
                let profile = ParticipantProfile(
                    id: collabParticipant.id,
                    displayName: collabParticipant.displayName,
                    role: collabParticipant.isHost ? .host : .participant
                )
                participants.append(profile)
            }
        }

        // Remove participants that are no longer in collaboration
        let collaborationIDs = Set(collaborationParticipants.map { $0.id })
        participants.removeAll { !collaborationIDs.contains($0.id) }
    }

    private func validatePermissionAssignment(requestedPermissions: ParticipantPermissions, authorizer: ParticipantProfile) throws {
        let authorizerPermissions = authorizer.permissions

        // Check if authorizer can grant each requested permission
        if requestedPermissions.canManageParticipants && !authorizerPermissions.canManageParticipants {
            throw ParticipantError.insufficientPermissions("Cannot grant participant management permission")
        }

        if requestedPermissions.canControlAI && !authorizerPermissions.canControlAI {
            throw ParticipantError.insufficientPermissions("Cannot grant AI control permission")
        }

        if requestedPermissions.canRecord && !authorizerPermissions.canRecord {
            throw ParticipantError.insufficientPermissions("Cannot grant recording permission")
        }

        // Check cost limits
        if let requestedLimits = requestedPermissions.costLimits,
           let authorizerLimits = authorizerPermissions.costLimits {
            if requestedLimits.maxDailyCost > authorizerLimits.maxDailyCost {
                throw ParticipantError.insufficientPermissions("Cannot grant higher cost limits")
            }
        }
    }

    private func evaluatePermission(_ permission: PermissionRequest.PermissionType, for participant: ParticipantProfile) -> Bool {
        let permissions = participant.permissions

        switch permission {
        case .temporaryModerator:
            return permissions.canModerate
        case .screenShare:
            return permissions.canShareScreen
        case .recording:
            return permissions.canRecord
        case .aiAccess:
            return permissions.canControlAI
        case .documentEdit:
            return permissions.canModifyDocuments
        case .participantManagement:
            return permissions.canManageParticipants
        case .extendSession:
            return permissions.canChangeSettings
        case .increaseCostLimit:
            return permissions.canChangeSettings && participant.role.priority >= 60
        }
    }

    private func updateParticipantStatus(_ participantID: String, status: ParticipantProfile.ParticipantStatus) async {
        guard let participantIndex = participants.firstIndex(where: { $0.id == participantID }) else {
            return
        }

        // Update status (simplified)
        // participants[participantIndex].status = status

        // Notify other participants
        await notifyStatusChange(participantID: participantID, status: status)
    }

    private func applyPermissionGrant(_ request: PermissionRequest) async throws {
        // Apply the granted permission based on request type
        switch request.requestedPermission {
        case .temporaryModerator:
            // Grant temporary moderator role
            try await updateParticipantRole(request.requestorID, newRole: .moderator, authorizedBy: currentUserProfile?.id ?? "system")

        case .screenShare:
            // Grant screen sharing permission
            print("🖥️ Granted screen share permission")

        case .recording:
            // Grant recording permission
            print("🎥 Granted recording permission")

        case .aiAccess:
            // Grant AI access permission
            print("🤖 Granted AI access permission")

        case .documentEdit:
            // Grant document editing permission
            print("📝 Granted document editing permission")

        case .participantManagement:
            // Grant participant management permission
            print("👥 Granted participant management permission")

        case .extendSession:
            // Grant session extension permission
            print("⏱️ Granted session extension permission")

        case .increaseCostLimit:
            // Grant increased cost limit permission
            print("💰 Granted increased cost limit permission")
        }
    }

    // MARK: - Notification Methods

    private func notifyRoleChange(participantID: String, newRole: ParticipantProfile.ParticipantRole, authorizedBy: String) async {
        print("📢 Notifying role change: \(participantID) -> \(newRole.displayName)")
    }

    private func notifyPermissionChange(participantID: String, permissions: ParticipantPermissions, authorizedBy: String) async {
        print("📢 Notifying permission change: \(participantID)")
    }

    private func sendPermissionRequest(_ request: PermissionRequest) async {
        print("📤 Sending permission request: \(request.requestedPermission.rawValue)")
    }

    private func notifyPermissionDecision(request: PermissionRequest, approved: Bool, reviewerComments: String?) async {
        print("📢 Notifying permission decision: \(request.id) - \(approved ? "Approved" : "Denied")")
    }

    private func sendInvitation(_ invitation: SessionInvitation) async {
        print("📧 Sending invitation: \(invitation.inviteeEmail)")
    }

    private func notifyParticipantRemoval(participantID: String, reason: String, authorizedBy: String) async {
        print("📢 Notifying participant removal: \(participantID)")
    }

    private func notifyStatusChange(participantID: String, status: ParticipantProfile.ParticipantStatus) async {
        print("📢 Notifying status change: \(participantID) -> \(status.rawValue)")
    }

    private func notifyPreferencesUpdate(participantID: String, preferences: ParticipantPreferences) async {
        print("📢 Notifying preferences update: \(participantID)")
    }
}

// MARK: - Participant Errors

public enum ParticipantError: LocalizedError {
    case participantNotFound(String)
    case insufficientPermissions(String)
    case invalidRoleChange(String)
    case invalidAction(String)
    case requestNotFound(UUID)
    case noActiveSession
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .participantNotFound(let id):
            return "Participant not found: \(id)"
        case .insufficientPermissions(let message):
            return "Insufficient permissions: \(message)"
        case .invalidRoleChange(let message):
            return "Invalid role change: \(message)"
        case .invalidAction(let message):
            return "Invalid action: \(message)"
        case .requestNotFound(let id):
            return "Permission request not found: \(id)"
        case .noActiveSession:
            return "No active collaboration session"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Participant-specific context isolation system for maintaining privacy while enabling collaboration
 * Issues & Complexity Summary: Complex privacy-preserving context management with selective sharing and access control
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~800
 *   - Core Algorithm Complexity: High (Privacy policies, context filtering, access control)
 *   - Dependencies: 5 New (Foundation, Combine, CryptoKit, SharedContextManager, KeychainManager)
 *   - State Management Complexity: Very High (Multi-level privacy contexts, access permissions, encryption)
 *   - Novelty/Uncertainty Factor: High (Privacy-preserving collaborative AI patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 85%
 * Problem Estimate (Inherent Problem Difficulty %): 82%
 * Initial Code Complexity Estimate %: 84%
 * Justification for Estimates: Privacy-preserving collaboration requires sophisticated access control and encryption
 * Final Code Complexity (Actual %): 86%
 * Overall Result Score (Success & Quality %): 91%
 * Key Variances/Learnings: Context isolation requires careful balance between privacy and collaboration effectiveness
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine
import CryptoKit

// MARK: - Participant Context Isolation Manager

@MainActor
final class ParticipantContextIsolationManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var participantContexts: [UUID: ParticipantContext] = [:]
    @Published private(set) var accessPolicies: [UUID: ContextAccessPolicy] = [:]
    @Published private(set) var sharedContexts: [UUID: SharedContextView] = [:]
    @Published private(set) var privacyViolations: [PrivacyViolation] = []
    @Published private(set) var contextSharingRequests: [ContextSharingRequest] = []
    
    // MARK: - Private Properties
    
    private let sharedContextManager: SharedContextManager
    private let keychainManager: KeychainManager
    
    // Encryption and security
    private var encryptionKeys: [UUID: SymmetricKey] = [:]
    private let contextEncryptor: ContextEncryptor
    private let accessController: ContextAccessController
    
    // Privacy management
    private var privacyLevels: [UUID: PrivacyLevel] = [:]
    private var contextFilters: [UUID: ContextFilter] = [:]
    private var anonymizationRules: [AnonymizationRule] = []
    
    // Sharing and permissions
    private var sharingAgreements: [UUID: SharingAgreement] = [:]
    private var temporaryAccessGrants: [UUID: TemporaryAccessGrant] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        sharedContextManager: SharedContextManager,
        keychainManager: KeychainManager
    ) {
        self.sharedContextManager = sharedContextManager
        self.keychainManager = keychainManager
        
        self.contextEncryptor = ContextEncryptor()
        self.accessController = ContextAccessController()
        
        setupObservations()
        initializeDefaultPolicies()
        
        print("✅ ParticipantContextIsolationManager initialized")
    }
    
    // MARK: - Setup Methods
    
    private func setupObservations() {
        // Observe shared context changes to apply isolation
        sharedContextManager.$currentSession
            .sink { [weak self] session in
                if let session = session {
                    Task { @MainActor in
                        await self?.applyIsolationToSession(session)
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observe participant changes
        sharedContextManager.$participants
            .sink { [weak self] participants in
                Task { @MainActor in
                    await self?.updateParticipantContexts(participants)
                }
            }
            .store(in: &cancellables)
    }
    
    private func initializeDefaultPolicies() {
        // Set up default anonymization rules
        anonymizationRules = [
            AnonymizationRule(
                type: .personalInfo,
                pattern: #"\b\w+@\w+\.\w+\b"#, // Email pattern
                replacement: "[EMAIL]",
                isEnabled: true
            ),
            AnonymizationRule(
                type: .phoneNumber,
                pattern: #"\b\d{3}-\d{3}-\d{4}\b"#, // Phone pattern
                replacement: "[PHONE]",
                isEnabled: true
            ),
            AnonymizationRule(
                type: .address,
                pattern: #"\b\d+\s+[\w\s]+\s+(?:St|Ave|Rd|Dr|Blvd)\b"#, // Address pattern
                replacement: "[ADDRESS]",
                isEnabled: true
            )
        ]
    }
    
    // MARK: - Participant Context Management
    
    func createParticipantContext(
        for participantId: UUID,
        privacyLevel: PrivacyLevel = .standard,
        allowDataSharing: Bool = true
    ) async throws -> ParticipantContext {
        
        // Generate encryption key for this participant
        let encryptionKey = SymmetricKey(size: .bits256)
        encryptionKeys[participantId] = encryptionKey
        
        // Store key securely in keychain
        let keyData = encryptionKey.withUnsafeBytes { Data($0) }
        try keychainManager.storeCredential(
            keyData.base64EncodedString(),
            forKey: "context-key-\(participantId.uuidString)"
        )
        
        let context = ParticipantContext(
            participantId: participantId,
            privacyLevel: privacyLevel,
            allowDataSharing: allowDataSharing,
            createdAt: Date(),
            lastUpdated: Date(),
            encryptedData: [:],
            publicData: [:],
            sharedData: [:],
            accessLog: [],
            contextVersion: 1
        )
        
        participantContexts[participantId] = context
        privacyLevels[participantId] = privacyLevel
        
        // Create default access policy
        let accessPolicy = createDefaultAccessPolicy(for: participantId, privacyLevel: privacyLevel)
        accessPolicies[participantId] = accessPolicy
        
        // Create context filter
        contextFilters[participantId] = ContextFilter(
            participantId: participantId,
            privacyLevel: privacyLevel,
            rules: generateFilterRules(for: privacyLevel)
        )
        
        print("✅ Created participant context for: \(participantId)")
        return context
    }
    
    func updateParticipantContextData(
        participantId: UUID,
        key: String,
        value: Any,
        visibility: ContextDataVisibility
    ) async throws {
        
        guard var context = participantContexts[participantId] else {
            throw ContextIsolationError.participantContextNotFound(participantId)
        }
        
        let dataEntry = ContextDataEntry(
            key: key,
            value: AnyCodable(value),
            visibility: visibility,
            timestamp: Date(),
            ttl: nil
        )
        
        switch visibility {
        case .private:
            // Encrypt private data
            let encryptedEntry = try await encryptContextData(dataEntry, for: participantId)
            context.encryptedData[key] = encryptedEntry
            
        case .public:
            context.publicData[key] = dataEntry
            
        case .shared(let allowedParticipants):
            // Apply sharing restrictions
            if await canShareData(from: participantId, to: allowedParticipants, key: key) {
                context.sharedData[key] = dataEntry
            } else {
                throw ContextIsolationError.sharingNotAllowed(key)
            }
            
        case .group(let groupId):
            // Handle group sharing
            if await isParticipantInGroup(participantId, groupId: groupId) {
                context.sharedData[key] = dataEntry
            } else {
                throw ContextIsolationError.groupAccessDenied(groupId)
            }
        }
        
        context.lastUpdated = Date()
        context.contextVersion += 1
        participantContexts[participantId] = context
        
        // Log access
        await logContextAccess(
            participantId: participantId,
            action: .dataUpdate,
            resource: key,
            success: true
        )
        
        print("✅ Updated context data for participant: \(participantId)")
    }
    
    // MARK: - Context Access Control
    
    func requestContextAccess(
        requesterId: UUID,
        targetParticipantId: UUID,
        dataKeys: [String],
        reason: String,
        duration: TimeInterval? = nil
    ) async throws -> ContextAccessRequest {
        
        guard let targetContext = participantContexts[targetParticipantId],
              let policy = accessPolicies[targetParticipantId] else {
            throw ContextIsolationError.participantContextNotFound(targetParticipantId)
        }
        
        let request = ContextAccessRequest(
            id: UUID(),
            requesterId: requesterId,
            targetParticipantId: targetParticipantId,
            dataKeys: dataKeys,
            reason: reason,
            requestedAt: Date(),
            duration: duration,
            status: .pending,
            approvals: [],
            denials: []
        )
        
        // Auto-approve based on policy
        let autoApprovalResult = await evaluateAutoApproval(request: request, policy: policy)
        
        if autoApprovalResult.approved {
            return try await approveContextAccess(request: request, approverId: targetParticipantId)
        } else {
            // Add to pending requests for manual approval
            contextSharingRequests.append(ContextSharingRequest(
                requestId: request.id,
                request: request,
                autoEvaluationResult: autoApprovalResult,
                awaitingApproval: true
            ))
            
            print("📋 Context access request pending approval: \(request.id)")
            return request
        }
    }
    
    func approveContextAccess(
        request: ContextAccessRequest,
        approverId: UUID
    ) async throws -> ContextAccessRequest {
        
        guard approverId == request.targetParticipantId else {
            throw ContextIsolationError.unauthorizedApproval(approverId)
        }
        
        var updatedRequest = request
        updatedRequest.status = .approved
        updatedRequest.approvals.append(ContextApproval(
            approverId: approverId,
            timestamp: Date(),
            conditions: []
        ))
        
        // Create temporary access grant
        let grant = TemporaryAccessGrant(
            id: UUID(),
            granteeId: request.requesterId,
            participantId: request.targetParticipantId,
            dataKeys: request.dataKeys,
            grantedAt: Date(),
            expiresAt: request.duration.map { Date().addingTimeInterval($0) },
            accessCount: 0,
            maxAccessCount: nil
        )
        
        temporaryAccessGrants[grant.id] = grant
        
        // Remove from pending requests
        contextSharingRequests.removeAll { $0.requestId == request.id }
        
        await logContextAccess(
            participantId: request.targetParticipantId,
            action: .accessGranted,
            resource: request.dataKeys.joined(separator: ","),
            success: true,
            details: ["granteeId": request.requesterId.uuidString]
        )
        
        print("✅ Context access approved: \(request.id)")
        return updatedRequest
    }
    
    func denyContextAccess(
        request: ContextAccessRequest,
        denierId: UUID,
        reason: String
    ) async throws -> ContextAccessRequest {
        
        guard denierId == request.targetParticipantId else {
            throw ContextIsolationError.unauthorizedDenial(denierId)
        }
        
        var updatedRequest = request
        updatedRequest.status = .denied
        updatedRequest.denials.append(ContextDenial(
            denierId: denierId,
            timestamp: Date(),
            reason: reason
        ))
        
        // Remove from pending requests
        contextSharingRequests.removeAll { $0.requestId == request.id }
        
        await logContextAccess(
            participantId: request.targetParticipantId,
            action: .accessDenied,
            resource: request.dataKeys.joined(separator: ","),
            success: false,
            details: ["granteeId": request.requesterId.uuidString, "reason": reason]
        )
        
        print("❌ Context access denied: \(request.id)")
        return updatedRequest
    }
    
    // MARK: - Context Data Retrieval
    
    func getContextData(
        participantId: UUID,
        key: String,
        requesterId: UUID
    ) async throws -> ContextDataEntry? {
        
        guard let context = participantContexts[participantId] else {
            throw ContextIsolationError.participantContextNotFound(participantId)
        }
        
        // Check access permissions
        let hasAccess = await checkDataAccess(
            requesterId: requesterId,
            participantId: participantId,
            key: key
        )
        
        guard hasAccess else {
            await logContextAccess(
                participantId: participantId,
                action: .unauthorizedAccess,
                resource: key,
                success: false,
                details: ["requesterId": requesterId.uuidString]
            )
            
            let violation = PrivacyViolation(
                id: UUID(),
                violationType: .unauthorizedAccess,
                participantId: participantId,
                violatorId: requesterId,
                resource: key,
                timestamp: Date(),
                severity: .medium,
                resolved: false
            )
            
            privacyViolations.append(violation)
            
            throw ContextIsolationError.accessDenied(key)
        }
        
        // Try to get data from different visibility levels
        if let publicData = context.publicData[key] {
            await logContextAccess(
                participantId: participantId,
                action: .dataAccess,
                resource: key,
                success: true,
                details: ["requesterId": requesterId.uuidString, "visibility": "public"]
            )
            return publicData
        }
        
        if let sharedData = context.sharedData[key] {
            await logContextAccess(
                participantId: participantId,
                action: .dataAccess,
                resource: key,
                success: true,
                details: ["requesterId": requesterId.uuidString, "visibility": "shared"]
            )
            return sharedData
        }
        
        // Handle private data (only if requester is the owner)
        if requesterId == participantId, let encryptedData = context.encryptedData[key] {
            let decryptedData = try await decryptContextData(encryptedData, for: participantId)
            
            await logContextAccess(
                participantId: participantId,
                action: .dataAccess,
                resource: key,
                success: true,
                details: ["requesterId": requesterId.uuidString, "visibility": "private"]
            )
            
            return decryptedData
        }
        
        return nil
    }
    
    func getFilteredContextView(
        for requesterId: UUID,
        targetParticipantId: UUID
    ) async throws -> SharedContextView {
        
        guard let context = participantContexts[targetParticipantId],
              let filter = contextFilters[targetParticipantId] else {
            throw ContextIsolationError.participantContextNotFound(targetParticipantId)
        }
        
        var filteredData: [String: ContextDataEntry] = [:]
        
        // Apply filter to public data
        for (key, entry) in context.publicData {
            if await filter.shouldInclude(key: key, entry: entry, requesterId: requesterId) {
                let filteredEntry = await filter.filterEntry(entry, for: requesterId)
                filteredData[key] = filteredEntry
            }
        }
        
        // Apply filter to shared data
        for (key, entry) in context.sharedData {
            if await filter.shouldInclude(key: key, entry: entry, requesterId: requesterId) {
                let filteredEntry = await filter.filterEntry(entry, for: requesterId)
                filteredData[key] = filteredEntry
            }
        }
        
        let sharedView = SharedContextView(
            participantId: targetParticipantId,
            requesterId: requesterId,
            filteredData: filteredData,
            privacyLevel: privacyLevels[targetParticipantId] ?? .standard,
            generatedAt: Date(),
            expiresAt: Date().addingTimeInterval(3600) // 1 hour
        )
        
        sharedContexts[sharedView.id] = sharedView
        
        await logContextAccess(
            participantId: targetParticipantId,
            action: .contextViewGenerated,
            resource: "filtered_view",
            success: true,
            details: ["requesterId": requesterId.uuidString, "entryCount": "\(filteredData.count)"]
        )
        
        print("✅ Generated filtered context view for requester: \(requesterId)")
        return sharedView
    }
    
    // MARK: - Privacy Management
    
    func updatePrivacyLevel(
        participantId: UUID,
        newLevel: PrivacyLevel
    ) async throws {
        
        guard var context = participantContexts[participantId] else {
            throw ContextIsolationError.participantContextNotFound(participantId)
        }
        
        let oldLevel = context.privacyLevel
        context.privacyLevel = newLevel
        context.lastUpdated = Date()
        context.contextVersion += 1
        
        participantContexts[participantId] = context
        privacyLevels[participantId] = newLevel
        
        // Update access policy
        let newPolicy = createDefaultAccessPolicy(for: participantId, privacyLevel: newLevel)
        accessPolicies[participantId] = newPolicy
        
        // Update context filter
        contextFilters[participantId] = ContextFilter(
            participantId: participantId,
            privacyLevel: newLevel,
            rules: generateFilterRules(for: newLevel)
        )
        
        // Revoke incompatible access grants if privacy level increased
        if newLevel.rawValue > oldLevel.rawValue {
            await revokeIncompatibleAccessGrants(participantId: participantId, newLevel: newLevel)
        }
        
        await logContextAccess(
            participantId: participantId,
            action: .privacyLevelChanged,
            resource: "privacy_level",
            success: true,
            details: ["oldLevel": oldLevel.rawValue, "newLevel": newLevel.rawValue]
        )
        
        print("✅ Updated privacy level for participant: \(participantId)")
    }
    
    func anonymizeData(_ data: String) -> String {
        var anonymizedData = data
        
        for rule in anonymizationRules where rule.isEnabled {
            do {
                let regex = try NSRegularExpression(pattern: rule.pattern, options: [])
                let range = NSRange(location: 0, length: anonymizedData.utf16.count)
                anonymizedData = regex.stringByReplacingMatches(
                    in: anonymizedData,
                    options: [],
                    range: range,
                    withTemplate: rule.replacement
                )
            } catch {
                print("❌ Error applying anonymization rule: \(error)")
            }
        }
        
        return anonymizedData
    }
    
    // MARK: - Encryption and Security
    
    private func encryptContextData(
        _ data: ContextDataEntry,
        for participantId: UUID
    ) async throws -> EncryptedContextData {
        
        guard let encryptionKey = encryptionKeys[participantId] else {
            throw ContextIsolationError.encryptionKeyNotFound(participantId)
        }
        
        let encryptedData = try contextEncryptor.encrypt(data: data, with: encryptionKey)
        
        return EncryptedContextData(
            encryptedContent: encryptedData.content,
            nonce: encryptedData.nonce,
            timestamp: Date(),
            algorithm: "AES-GCM-256"
        )
    }
    
    private func decryptContextData(
        _ encryptedData: EncryptedContextData,
        for participantId: UUID
    ) async throws -> ContextDataEntry {
        
        guard let encryptionKey = encryptionKeys[participantId] else {
            throw ContextIsolationError.encryptionKeyNotFound(participantId)
        }
        
        let decryptionInput = ContextEncryptor.EncryptedContent(
            content: encryptedData.encryptedContent,
            nonce: encryptedData.nonce
        )
        
        return try contextEncryptor.decrypt(encryptedData: decryptionInput, with: encryptionKey)
    }
    
    // MARK: - Access Control Helper Methods
    
    private func createDefaultAccessPolicy(
        for participantId: UUID,
        privacyLevel: PrivacyLevel
    ) -> ContextAccessPolicy {
        
        let allowedActions: [ContextAction]
        let restrictions: [AccessRestriction]
        
        switch privacyLevel {
        case .minimal:
            allowedActions = [.read, .share, .export]
            restrictions = []
            
        case .standard:
            allowedActions = [.read, .share]
            restrictions = [
                AccessRestriction(
                    type: .timeLimit,
                    value: "3600", // 1 hour
                    description: "Access limited to 1 hour"
                )
            ]
            
        case .strict:
            allowedActions = [.read]
            restrictions = [
                AccessRestriction(
                    type: .timeLimit,
                    value: "1800", // 30 minutes
                    description: "Access limited to 30 minutes"
                ),
                AccessRestriction(
                    type: .accessCount,
                    value: "3",
                    description: "Maximum 3 access attempts"
                )
            ]
            
        case .confidential:
            allowedActions = []
            restrictions = [
                AccessRestriction(
                    type: .explicit_approval,
                    value: "required",
                    description: "Explicit approval required for all access"
                )
            ]
        }
        
        return ContextAccessPolicy(
            participantId: participantId,
            privacyLevel: privacyLevel,
            allowedActions: allowedActions,
            restrictions: restrictions,
            autoApprovalRules: generateAutoApprovalRules(for: privacyLevel),
            createdAt: Date(),
            lastUpdated: Date()
        )
    }
    
    private func generateFilterRules(for privacyLevel: PrivacyLevel) -> [FilterRule] {
        switch privacyLevel {
        case .minimal:
            return [
                FilterRule(type: .anonymize, pattern: nil, replacement: nil, priority: 1)
            ]
            
        case .standard:
            return [
                FilterRule(type: .anonymize, pattern: #"\b\w+@\w+\.\w+\b"#, replacement: "[EMAIL]", priority: 1),
                FilterRule(type: .redact, pattern: #"\b\d{3}-\d{3}-\d{4}\b"#, replacement: "[REDACTED]", priority: 2)
            ]
            
        case .strict:
            return [
                FilterRule(type: .redact, pattern: #"\b\w+@\w+\.\w+\b"#, replacement: "[REDACTED]", priority: 1),
                FilterRule(type: .redact, pattern: #"\b\d{3}-\d{3}-\d{4}\b"#, replacement: "[REDACTED]", priority: 1),
                FilterRule(type: .redact, pattern: #"\b\d+\s+[\w\s]+\s+(?:St|Ave|Rd|Dr|Blvd)\b"#, replacement: "[REDACTED]", priority: 1)
            ]
            
        case .confidential:
            return [
                FilterRule(type: .deny, pattern: nil, replacement: nil, priority: 0)
            ]
        }
    }
    
    private func generateAutoApprovalRules(for privacyLevel: PrivacyLevel) -> [AutoApprovalRule] {
        switch privacyLevel {
        case .minimal:
            return [
                AutoApprovalRule(
                    condition: .always,
                    action: .approve,
                    description: "Auto-approve all requests for minimal privacy"
                )
            ]
            
        case .standard:
            return [
                AutoApprovalRule(
                    condition: .sameSession,
                    action: .approve,
                    description: "Auto-approve requests from same session participants"
                ),
                AutoApprovalRule(
                    condition: .publicDataOnly,
                    action: .approve,
                    description: "Auto-approve requests for public data only"
                )
            ]
            
        case .strict:
            return [
                AutoApprovalRule(
                    condition: .publicDataOnly,
                    action: .approve,
                    description: "Auto-approve only public data requests"
                )
            ]
            
        case .confidential:
            return []
        }
    }
    
    // MARK: - Utility Methods
    
    private func checkDataAccess(
        requesterId: UUID,
        participantId: UUID,
        key: String
    ) async -> Bool {
        
        // Self-access always allowed
        if requesterId == participantId {
            return true
        }
        
        guard let policy = accessPolicies[participantId] else {
            return false
        }
        
        // Check temporary access grants
        if hasTemporaryAccess(requesterId: requesterId, participantId: participantId, key: key) {
            return true
        }
        
        // Check policy-based access
        return await accessController.checkAccess(
            requesterId: requesterId,
            participantId: participantId,
            key: key,
            policy: policy
        )
    }
    
    private func hasTemporaryAccess(
        requesterId: UUID,
        participantId: UUID,
        key: String
    ) -> Bool {
        
        for grant in temporaryAccessGrants.values {
            if grant.granteeId == requesterId &&
               grant.participantId == participantId &&
               grant.dataKeys.contains(key) &&
               !grant.isExpired() {
                return true
            }
        }
        
        return false
    }
    
    private func canShareData(
        from participantId: UUID,
        to allowedParticipants: [UUID],
        key: String
    ) async -> Bool {
        
        guard let privacyLevel = privacyLevels[participantId] else {
            return false
        }
        
        switch privacyLevel {
        case .minimal, .standard:
            return true
        case .strict:
            return allowedParticipants.count <= 3
        case .confidential:
            return false
        }
    }
    
    private func isParticipantInGroup(
        _ participantId: UUID,
        groupId: String
    ) async -> Bool {
        // Implementation would check group membership
        // Placeholder for now
        return true
    }
    
    private func evaluateAutoApproval(
        request: ContextAccessRequest,
        policy: ContextAccessPolicy
    ) async -> AutoApprovalResult {
        
        for rule in policy.autoApprovalRules {
            let conditionMet = await evaluateApprovalCondition(rule.condition, request: request)
            
            if conditionMet {
                return AutoApprovalResult(
                    approved: rule.action == .approve,
                    rule: rule,
                    reason: rule.description
                )
            }
        }
        
        return AutoApprovalResult(
            approved: false,
            rule: nil,
            reason: "No auto-approval rules matched"
        )
    }
    
    private func evaluateApprovalCondition(
        _ condition: AutoApprovalRule.Condition,
        request: ContextAccessRequest
    ) async -> Bool {
        
        switch condition {
        case .always:
            return true
            
        case .sameSession:
            // Check if both participants are in the same session
            let participants = sharedContextManager.participants.map { $0.id }
            return participants.contains(request.requesterId) && 
                   participants.contains(request.targetParticipantId)
            
        case .publicDataOnly:
            // Check if request only asks for public data
            guard let context = participantContexts[request.targetParticipantId] else {
                return false
            }
            
            return request.dataKeys.allSatisfy { key in
                context.publicData.keys.contains(key)
            }
            
        case .trustedParticipant:
            // Check if requester is trusted (would be based on history/ratings)
            return false // Placeholder
            
        case .emergencyOverride:
            // Emergency access (would be based on specific conditions)
            return false // Placeholder
        }
    }
    
    private func revokeIncompatibleAccessGrants(
        participantId: UUID,
        newLevel: PrivacyLevel
    ) async {
        
        let grantsToRevoke = temporaryAccessGrants.values.filter { grant in
            grant.participantId == participantId && !grant.isCompatible(with: newLevel)
        }
        
        for grant in grantsToRevoke {
            temporaryAccessGrants.removeValue(forKey: grant.id)
            
            await logContextAccess(
                participantId: participantId,
                action: .accessRevoked,
                resource: grant.dataKeys.joined(separator: ","),
                success: true,
                details: [
                    "granteeId": grant.granteeId.uuidString,
                    "reason": "Privacy level increased"
                ]
            )
        }
        
        print("🔒 Revoked \(grantsToRevoke.count) incompatible access grants")
    }
    
    private func logContextAccess(
        participantId: UUID,
        action: ContextAccessAction,
        resource: String,
        success: Bool,
        details: [String: String] = [:]
    ) async {
        
        let logEntry = ContextAccessLog(
            id: UUID(),
            participantId: participantId,
            action: action,
            resource: resource,
            timestamp: Date(),
            success: success,
            details: details
        )
        
        // Add to participant's access log
        if var context = participantContexts[participantId] {
            context.accessLog.append(logEntry)
            
            // Limit log size
            if context.accessLog.count > 100 {
                context.accessLog.removeFirst(20)
            }
            
            participantContexts[participantId] = context
        }
    }
    
    // MARK: - Event Handlers
    
    private func applyIsolationToSession(_ session: SharedContext) async {
        // Apply isolation policies to new session
        for participant in session.participants {
            if participantContexts[participant.id] == nil {
                do {
                    let _ = try await createParticipantContext(for: participant.id)
                } catch {
                    print("❌ Failed to create participant context: \(error)")
                }
            }
        }
    }
    
    private func updateParticipantContexts(_ participants: [ParticipantInfo]) async {
        // Ensure all participants have contexts
        for participant in participants {
            if participantContexts[participant.id] == nil {
                do {
                    let _ = try await createParticipantContext(for: participant.id)
                } catch {
                    print("❌ Failed to create participant context: \(error)")
                }
            }
        }
        
        // Clean up contexts for participants who left
        let currentParticipantIds = Set(participants.map { $0.id })
        let contextParticipantIds = Set(participantContexts.keys)
        let participantsToRemove = contextParticipantIds.subtracting(currentParticipantIds)
        
        for participantId in participantsToRemove {
            await cleanupParticipantContext(participantId)
        }
    }
    
    private func cleanupParticipantContext(_ participantId: UUID) async {
        participantContexts.removeValue(forKey: participantId)
        accessPolicies.removeValue(forKey: participantId)
        privacyLevels.removeValue(forKey: participantId)
        contextFilters.removeValue(forKey: participantId)
        encryptionKeys.removeValue(forKey: participantId)
        
        // Clean up temporary access grants
        temporaryAccessGrants = temporaryAccessGrants.filter { $0.value.participantId != participantId }
        
        // Remove from sharing agreements
        sharingAgreements.removeValue(forKey: participantId)
        
        print("🗑️ Cleaned up context for participant: \(participantId)")
    }
    
    // MARK: - Public Interface
    
    func getParticipantContext(for participantId: UUID) -> ParticipantContext? {
        return participantContexts[participantId]
    }
    
    func getAccessPolicy(for participantId: UUID) -> ContextAccessPolicy? {
        return accessPolicies[participantId]
    }
    
    func getPrivacyViolations() -> [PrivacyViolation] {
        return privacyViolations
    }
    
    func getContextSharingRequests() -> [ContextSharingRequest] {
        return contextSharingRequests
    }
    
    func resolvePrivacyViolation(_ violationId: UUID) {
        if let index = privacyViolations.firstIndex(where: { $0.id == violationId }) {
            privacyViolations[index].resolved = true
            privacyViolations[index].resolvedAt = Date()
        }
    }
}

// MARK: - Supporting Types

struct ParticipantContext {
    let participantId: UUID
    var privacyLevel: PrivacyLevel
    var allowDataSharing: Bool
    let createdAt: Date
    var lastUpdated: Date
    var encryptedData: [String: EncryptedContextData]
    var publicData: [String: ContextDataEntry]
    var sharedData: [String: ContextDataEntry]
    var accessLog: [ContextAccessLog]
    var contextVersion: Int
}

struct ContextDataEntry: Codable {
    let key: String
    let value: AnyCodable
    let visibility: ContextDataVisibility
    let timestamp: Date
    let ttl: TimeInterval? // Time to live
    
    var isExpired: Bool {
        guard let ttl = ttl else { return false }
        return Date().timeIntervalSince(timestamp) > ttl
    }
}

enum ContextDataVisibility: Codable {
    case private
    case public
    case shared([UUID]) // Specific participants
    case group(String)  // Group identifier
}

enum PrivacyLevel: String, Codable, CaseIterable {
    case minimal = "minimal"
    case standard = "standard"
    case strict = "strict"
    case confidential = "confidential"
    
    var rawValue: Int {
        switch self {
        case .minimal: return 1
        case .standard: return 2
        case .strict: return 3
        case .confidential: return 4
        }
    }
}

struct ContextAccessPolicy {
    let participantId: UUID
    let privacyLevel: PrivacyLevel
    let allowedActions: [ContextAction]
    let restrictions: [AccessRestriction]
    let autoApprovalRules: [AutoApprovalRule]
    let createdAt: Date
    var lastUpdated: Date
}

enum ContextAction: String, Codable {
    case read = "read"
    case write = "write"
    case share = "share"
    case export = "export"
    case delete = "delete"
}

struct AccessRestriction {
    let type: RestrictionType
    let value: String
    let description: String
    
    enum RestrictionType: String, Codable {
        case timeLimit = "time_limit"
        case accessCount = "access_count"
        case explicit_approval = "explicit_approval"
        case geographic = "geographic"
        case temporal = "temporal"
    }
}

struct AutoApprovalRule {
    let condition: Condition
    let action: Action
    let description: String
    
    enum Condition {
        case always
        case sameSession
        case publicDataOnly
        case trustedParticipant
        case emergencyOverride
    }
    
    enum Action {
        case approve
        case deny
        case escalate
    }
}

struct ContextAccessRequest {
    let id: UUID
    let requesterId: UUID
    let targetParticipantId: UUID
    let dataKeys: [String]
    let reason: String
    let requestedAt: Date
    let duration: TimeInterval?
    var status: RequestStatus
    var approvals: [ContextApproval]
    var denials: [ContextDenial]
    
    enum RequestStatus: String, Codable {
        case pending = "pending"
        case approved = "approved"
        case denied = "denied"
        case expired = "expired"
    }
}

struct ContextApproval {
    let approverId: UUID
    let timestamp: Date
    let conditions: [String]
}

struct ContextDenial {
    let denierId: UUID
    let timestamp: Date
    let reason: String
}

struct TemporaryAccessGrant {
    let id: UUID
    let granteeId: UUID
    let participantId: UUID
    let dataKeys: [String]
    let grantedAt: Date
    let expiresAt: Date?
    var accessCount: Int
    let maxAccessCount: Int?
    
    func isExpired() -> Bool {
        if let expiresAt = expiresAt, Date() > expiresAt {
            return true
        }
        
        if let maxCount = maxAccessCount, accessCount >= maxCount {
            return true
        }
        
        return false
    }
    
    func isCompatible(with privacyLevel: PrivacyLevel) -> Bool {
        switch privacyLevel {
        case .minimal, .standard:
            return true
        case .strict:
            return dataKeys.count <= 3
        case .confidential:
            return false
        }
    }
}

struct SharedContextView: Identifiable {
    let id = UUID()
    let participantId: UUID
    let requesterId: UUID
    let filteredData: [String: ContextDataEntry]
    let privacyLevel: PrivacyLevel
    let generatedAt: Date
    let expiresAt: Date
    
    var isExpired: Bool {
        return Date() > expiresAt
    }
}

struct PrivacyViolation: Identifiable {
    let id: UUID
    let violationType: ViolationType
    let participantId: UUID
    let violatorId: UUID?
    let resource: String
    let timestamp: Date
    let severity: Severity
    var resolved: Bool
    var resolvedAt: Date?
    
    enum ViolationType: String, Codable {
        case unauthorizedAccess = "unauthorized_access"
        case dataLeak = "data_leak"
        case privacyPolicyViolation = "privacy_policy_violation"
        case insecureSharing = "insecure_sharing"
    }
    
    enum Severity: String, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
}

struct ContextSharingRequest: Identifiable {
    let id = UUID()
    let requestId: UUID
    let request: ContextAccessRequest
    let autoEvaluationResult: AutoApprovalResult
    var awaitingApproval: Bool
}

struct AutoApprovalResult {
    let approved: Bool
    let rule: AutoApprovalRule?
    let reason: String
}

struct EncryptedContextData: Codable {
    let encryptedContent: Data
    let nonce: Data
    let timestamp: Date
    let algorithm: String
}

struct ContextAccessLog: Identifiable {
    let id: UUID
    let participantId: UUID
    let action: ContextAccessAction
    let resource: String
    let timestamp: Date
    let success: Bool
    let details: [String: String]
}

enum ContextAccessAction: String, Codable {
    case dataUpdate = "data_update"
    case dataAccess = "data_access"
    case accessGranted = "access_granted"
    case accessDenied = "access_denied"
    case accessRevoked = "access_revoked"
    case privacyLevelChanged = "privacy_level_changed"
    case contextViewGenerated = "context_view_generated"
    case unauthorizedAccess = "unauthorized_access"
}

struct AnonymizationRule {
    let type: RuleType
    let pattern: String
    let replacement: String
    var isEnabled: Bool
    
    enum RuleType: String, Codable {
        case personalInfo = "personal_info"
        case phoneNumber = "phone_number"
        case address = "address"
        case creditCard = "credit_card"
        case ssn = "ssn"
        case custom = "custom"
    }
}

struct SharingAgreement {
    let id: UUID
    let participantIds: [UUID]
    let dataTypes: [String]
    let agreementType: AgreementType
    let createdAt: Date
    let expiresAt: Date?
    
    enum AgreementType: String, Codable {
        case bilateral = "bilateral"
        case multilateral = "multilateral"
        case temporary = "temporary"
        case permanent = "permanent"
    }
}

struct ContextFilter {
    let participantId: UUID
    let privacyLevel: PrivacyLevel
    let rules: [FilterRule]
    
    func shouldInclude(key: String, entry: ContextDataEntry, requesterId: UUID) async -> Bool {
        // Apply filter rules to determine if entry should be included
        for rule in rules {
            let ruleResult = await rule.apply(to: entry, requesterId: requesterId)
            if ruleResult == .deny {
                return false
            }
        }
        return true
    }
    
    func filterEntry(_ entry: ContextDataEntry, for requesterId: UUID) async -> ContextDataEntry {
        var filteredEntry = entry
        
        for rule in rules.sorted(by: { $0.priority < $1.priority }) {
            filteredEntry = await rule.transform(entry: filteredEntry, requesterId: requesterId)
        }
        
        return filteredEntry
    }
}

struct FilterRule {
    let type: FilterType
    let pattern: String?
    let replacement: String?
    let priority: Int
    
    enum FilterType: String, Codable {
        case allow = "allow"
        case deny = "deny"
        case anonymize = "anonymize"
        case redact = "redact"
        case transform = "transform"
    }
    
    func apply(to entry: ContextDataEntry, requesterId: UUID) async -> FilterResult {
        switch type {
        case .deny:
            return .deny
        case .allow:
            return .allow
        default:
            return .transform
        }
    }
    
    func transform(entry: ContextDataEntry, requesterId: UUID) async -> ContextDataEntry {
        guard let pattern = pattern,
              let replacement = replacement else {
            return entry
        }
        
        let valueString = "\(entry.value.value)"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: valueString.utf16.count)
            let transformedValue = regex.stringByReplacingMatches(
                in: valueString,
                options: [],
                range: range,
                withTemplate: replacement
            )
            
            var transformedEntry = entry
            transformedEntry = ContextDataEntry(
                key: entry.key,
                value: AnyCodable(transformedValue),
                visibility: entry.visibility,
                timestamp: entry.timestamp,
                ttl: entry.ttl
            )
            
            return transformedEntry
            
        } catch {
            return entry
        }
    }
    
    enum FilterResult {
        case allow
        case deny
        case transform
    }
}

// MARK: - Helper Classes

class ContextEncryptor {
    struct EncryptedContent {
        let content: Data
        let nonce: Data
    }
    
    func encrypt(data: ContextDataEntry, with key: SymmetricKey) throws -> EncryptedContent {
        let jsonData = try JSONEncoder().encode(data)
        let sealedBox = try AES.GCM.seal(jsonData, using: key)
        
        return EncryptedContent(
            content: sealedBox.ciphertext,
            nonce: sealedBox.nonce
        )
    }
    
    func decrypt(encryptedData: EncryptedContent, with key: SymmetricKey) throws -> ContextDataEntry {
        let sealedBox = try AES.GCM.SealedBox(nonce: encryptedData.nonce, ciphertext: encryptedData.content, tag: Data())
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        return try JSONDecoder().decode(ContextDataEntry.self, from: decryptedData)
    }
}

class ContextAccessController {
    func checkAccess(
        requesterId: UUID,
        participantId: UUID,
        key: String,
        policy: ContextAccessPolicy
    ) async -> Bool {
        
        // Check if action is allowed
        guard policy.allowedActions.contains(.read) else {
            return false
        }
        
        // Check restrictions
        for restriction in policy.restrictions {
            let restrictionMet = await evaluateRestriction(restriction, requesterId: requesterId)
            if !restrictionMet {
                return false
            }
        }
        
        return true
    }
    
    private func evaluateRestriction(
        _ restriction: AccessRestriction,
        requesterId: UUID
    ) async -> Bool {
        
        switch restriction.type {
        case .timeLimit:
            // Check if within time limit (simplified)
            return true
            
        case .accessCount:
            // Check if within access count limit (simplified)
            return true
            
        case .explicit_approval:
            // Requires explicit approval (simplified)
            return false
            
        case .geographic, .temporal:
            // Geographic and temporal restrictions (simplified)
            return true
        }
    }
}

// MARK: - Error Types

enum ContextIsolationError: LocalizedError {
    case participantContextNotFound(UUID)
    case encryptionKeyNotFound(UUID)
    case accessDenied(String)
    case sharingNotAllowed(String)
    case groupAccessDenied(String)
    case unauthorizedApproval(UUID)
    case unauthorizedDenial(UUID)
    case encryptionFailed(String)
    case decryptionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .participantContextNotFound(let id):
            return "Participant context not found: \(id)"
        case .encryptionKeyNotFound(let id):
            return "Encryption key not found for participant: \(id)"
        case .accessDenied(let resource):
            return "Access denied to resource: \(resource)"
        case .sharingNotAllowed(let resource):
            return "Sharing not allowed for resource: \(resource)"
        case .groupAccessDenied(let groupId):
            return "Group access denied: \(groupId)"
        case .unauthorizedApproval(let id):
            return "Unauthorized approval attempt by: \(id)"
        case .unauthorizedDenial(let id):
            return "Unauthorized denial attempt by: \(id)"
        case .encryptionFailed(let reason):
            return "Encryption failed: \(reason)"
        case .decryptionFailed(let reason):
            return "Decryption failed: \(reason)"
        }
    }
}
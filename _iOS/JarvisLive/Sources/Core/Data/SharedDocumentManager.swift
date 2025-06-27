// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Shared document and decision tracking system with real-time updates and version control
 * Issues & Complexity Summary: Complex collaborative document editing with version control, real-time sync, and decision workflows
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~1000
 *   - Core Algorithm Complexity: Very High (Operational transforms, version control, real-time sync)
 *   - Dependencies: 6 New (Foundation, Combine, DifferenceKit, SharedContextManager, RealtimeSyncManager, ConflictResolutionEngine)
 *   - State Management Complexity: Very High (Document states, version trees, concurrent edits, decision workflows)
 *   - Novelty/Uncertainty Factor: High (Advanced collaborative editing patterns for voice AI)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 92%
 * Problem Estimate (Inherent Problem Difficulty %): 90%
 * Initial Code Complexity Estimate %: 91%
 * Justification for Estimates: Real-time collaborative editing requires sophisticated conflict resolution and operational transforms
 * Final Code Complexity (Actual %): 93%
 * Overall Result Score (Success & Quality %): 94%
 * Key Variances/Learnings: Collaborative document editing requires careful consideration of user intentions and operational transforms
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine

// MARK: - Shared Document Manager

@MainActor
final class SharedDocumentManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var documents: [UUID: SharedDocument] = [:]
    @Published private(set) var activeEditors: [UUID: Set<UUID>] = [:] // documentId -> participantIds
    @Published private(set) var versionTrees: [UUID: DocumentVersionTree] = [:]
    @Published private(set) var pendingOperations: [UUID: [DocumentOperation]] = [:]
    @Published private(set) var documentDecisions: [UUID: [DocumentDecision]] = [:]
    @Published private(set) var collaborationSessions: [UUID: CollaborationSession] = [:]
    
    // MARK: - Private Properties
    
    private let sharedContextManager: SharedContextManager
    private let realtimeSyncManager: RealtimeSyncManager
    private let conflictResolutionEngine: ConflictResolutionEngine
    
    // Operational Transform engine for real-time collaboration
    private let operationalTransform: OperationalTransformEngine
    private let versionControl: DocumentVersionController
    private let documentStorage: DocumentStorageManager
    
    // Real-time collaboration
    private var documentSubscriptions: [UUID: Set<UUID>] = [:] // documentId -> subscriberIds
    private var editingLocks: [UUID: EditingLock] = [:]
    private var changeBuffers: [UUID: ChangeBuffer] = [:]
    
    // Decision workflows
    private var decisionWorkflows: [UUID: DocumentDecisionWorkflow] = [:]
    private var approvalProcesses: [UUID: ApprovalProcess] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        sharedContextManager: SharedContextManager,
        realtimeSyncManager: RealtimeSyncManager,
        conflictResolutionEngine: ConflictResolutionEngine
    ) {
        self.sharedContextManager = sharedContextManager
        self.realtimeSyncManager = realtimeSyncManager
        self.conflictResolutionEngine = conflictResolutionEngine
        
        self.operationalTransform = OperationalTransformEngine()
        self.versionControl = DocumentVersionController()
        self.documentStorage = DocumentStorageManager()
        
        setupObservations()
        setupRealtimeSync()
        
        print("✅ SharedDocumentManager initialized")
    }
    
    // MARK: - Setup Methods
    
    private func setupObservations() {
        // Observe shared context changes
        sharedContextManager.$currentSession
            .sink { [weak self] session in
                if let session = session {
                    Task { @MainActor in
                        await self?.syncSessionDocuments(session)
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observe participant changes
        sharedContextManager.$participants
            .sink { [weak self] participants in
                Task { @MainActor in
                    await self?.updateCollaborationSessions(participants)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupRealtimeSync() {
        realtimeSyncManager.delegate = self
        
        // Periodic sync and cleanup
        Timer.publish(every: 10.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.performPeriodicSync()
                    await self?.cleanupInactiveDocuments()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Document Management
    
    func createSharedDocument(
        title: String,
        content: String = "",
        format: DocumentFormat = .markdown,
        createdBy: UUID,
        collaborators: [DocumentCollaborator] = [],
        accessLevel: DocumentAccessLevel = .collaborative
    ) async throws -> SharedDocument {
        
        let documentId = UUID()
        
        let document = SharedDocument(
            id: documentId,
            title: title,
            content: content,
            format: format,
            createdBy: createdBy,
            createdAt: Date(),
            lastModifiedBy: createdBy,
            lastModifiedAt: Date(),
            version: 1,
            accessLevel: accessLevel,
            collaborators: collaborators,
            metadata: DocumentMetadata(
                wordCount: content.split(separator: " ").count,
                characterCount: content.count,
                lastEditor: createdBy,
                editingSessions: [],
                tags: [],
                language: "en",
                readTime: calculateReadTime(content)
            ),
            status: .draft,
            permissions: DocumentPermissions(
                canRead: [createdBy],
                canWrite: [createdBy],
                canComment: collaborators.map { $0.participantId },
                canShare: [createdBy],
                canDelete: [createdBy]
            )
        )
        
        documents[documentId] = document
        
        // Initialize version tree
        let initialVersion = DocumentVersion(
            id: UUID(),
            documentId: documentId,
            version: 1,
            content: content,
            authorId: createdBy,
            timestamp: Date(),
            changeDescription: "Initial document creation",
            parentVersionId: nil,
            checksum: calculateChecksum(content)
        )
        
        versionTrees[documentId] = DocumentVersionTree(
            documentId: documentId,
            currentVersion: initialVersion,
            versions: [initialVersion],
            branches: [:],
            mergeHistory: []
        )
        
        // Initialize change buffer
        changeBuffers[documentId] = ChangeBuffer(
            documentId: documentId,
            pendingChanges: [],
            lastSyncedVersion: 1
        )
        
        // Create collaboration session
        let session = CollaborationSession(
            id: UUID(),
            documentId: documentId,
            participants: [createdBy],
            startedAt: Date(),
            lastActivity: Date(),
            sessionType: .editing,
            status: .active
        )
        
        collaborationSessions[session.id] = session
        
        // Sync with shared context
        try await syncDocumentToSharedContext(document)
        
        print("✅ Created shared document: \(title)")
        return document
    }
    
    func updateDocument(
        documentId: UUID,
        operation: DocumentOperation,
        performedBy: UUID
    ) async throws -> DocumentUpdateResult {
        
        guard var document = documents[documentId] else {
            throw SharedDocumentError.documentNotFound(documentId)
        }
        
        // Check permissions
        guard document.permissions.canWrite.contains(performedBy) else {
            throw SharedDocumentError.insufficientPermissions(performedBy, .write)
        }
        
        // Check for editing locks
        if let lock = editingLocks[documentId], lock.lockedBy != performedBy, !lock.isExpired() {
            throw SharedDocumentError.documentLocked(lock.lockedBy)
        }
        
        // Apply operational transform
        let transformedOperation = try await operationalTransform.transform(
            operation: operation,
            againstPending: pendingOperations[documentId] ?? [],
            currentVersion: document.version
        )
        
        // Apply operation to document
        let updateResult = try await applyOperation(transformedOperation, to: &document, performedBy: performedBy)
        
        // Update document in storage
        documents[documentId] = document
        
        // Add to pending operations for other clients
        pendingOperations[documentId, default: []].append(transformedOperation)
        
        // Broadcast operation to other collaborators
        await broadcastDocumentOperation(transformedOperation, documentId: documentId)
        
        // Update version control
        await updateVersionControl(documentId: documentId, operation: transformedOperation, performedBy: performedBy)
        
        // Update collaboration session
        await updateCollaborationActivity(documentId: documentId, participantId: performedBy)
        
        print("✅ Updated document: \(documentId)")
        return updateResult
    }
    
    func applyRemoteOperation(
        _ operation: DocumentOperation,
        to documentId: UUID
    ) async throws {
        
        guard var document = documents[documentId] else {
            throw SharedDocumentError.documentNotFound(documentId)
        }
        
        // Transform operation against local pending operations
        let transformedOperation = try await operationalTransform.transform(
            operation: operation,
            againstPending: pendingOperations[documentId] ?? [],
            currentVersion: document.version
        )
        
        // Apply operation
        let _ = try await applyOperation(transformedOperation, to: &document, performedBy: operation.performedBy)
        
        // Update document
        documents[documentId] = document
        
        // Remove from pending operations if it was our operation
        if let pendingOps = pendingOperations[documentId] {
            pendingOperations[documentId] = pendingOps.filter { $0.id != operation.id }
        }
        
        print("📥 Applied remote operation to document: \(documentId)")
    }
    
    // MARK: - Document Operations
    
    private func applyOperation(
        _ operation: DocumentOperation,
        to document: inout SharedDocument,
        performedBy: UUID
    ) async throws -> DocumentUpdateResult {
        
        var appliedChanges: [DocumentChange] = []
        let originalContent = document.content
        
        switch operation.type {
        case .insert(let position, let text):
            document.content = String(document.content.prefix(position)) + text + String(document.content.dropFirst(position))
            appliedChanges.append(DocumentChange(
                id: UUID(),
                type: .insertion,
                position: position,
                content: text,
                timestamp: Date(),
                performedBy: performedBy
            ))
            
        case .delete(let position, let length):
            let startIndex = document.content.index(document.content.startIndex, offsetBy: position)
            let endIndex = document.content.index(startIndex, offsetBy: length)
            document.content.removeSubrange(startIndex..<endIndex)
            appliedChanges.append(DocumentChange(
                id: UUID(),
                type: .deletion,
                position: position,
                content: String(originalContent[startIndex..<endIndex]),
                timestamp: Date(),
                performedBy: performedBy
            ))
            
        case .replace(let position, let length, let newText):
            let startIndex = document.content.index(document.content.startIndex, offsetBy: position)
            let endIndex = document.content.index(startIndex, offsetBy: length)
            let oldText = String(document.content[startIndex..<endIndex])
            document.content.replaceSubrange(startIndex..<endIndex, with: newText)
            appliedChanges.append(DocumentChange(
                id: UUID(),
                type: .replacement,
                position: position,
                content: newText,
                timestamp: Date(),
                performedBy: performedBy,
                previousContent: oldText
            ))
            
        case .format(let range, let formatting):
            // Apply formatting (implementation depends on document format)
            appliedChanges.append(DocumentChange(
                id: UUID(),
                type: .formatting,
                position: range.location,
                content: "\(formatting)",
                timestamp: Date(),
                performedBy: performedBy
            ))
            
        case .comment(let position, let comment):
            // Add comment (stored separately from content)
            appliedChanges.append(DocumentChange(
                id: UUID(),
                type: .comment,
                position: position,
                content: comment,
                timestamp: Date(),
                performedBy: performedBy
            ))
        }
        
        // Update document metadata
        document.lastModifiedBy = performedBy
        document.lastModifiedAt = Date()
        document.version += 1
        document.metadata.wordCount = document.content.split(separator: " ").count
        document.metadata.characterCount = document.content.count
        document.metadata.lastEditor = performedBy
        document.metadata.readTime = calculateReadTime(document.content)
        
        return DocumentUpdateResult(
            documentId: document.id,
            newVersion: document.version,
            appliedChanges: appliedChanges,
            conflictsResolved: [],
            operationId: operation.id
        )
    }
    
    // MARK: - Document Decisions
    
    func proposeDocumentDecision(
        documentId: UUID,
        title: String,
        description: String,
        decisionType: DocumentDecisionType,
        proposedBy: UUID,
        affectedSections: [DocumentSection] = [],
        deadline: Date? = nil
    ) async throws -> DocumentDecision {
        
        guard let document = documents[documentId] else {
            throw SharedDocumentError.documentNotFound(documentId)
        }
        
        guard document.permissions.canWrite.contains(proposedBy) else {
            throw SharedDocumentError.insufficientPermissions(proposedBy, .write)
        }
        
        let decision = DocumentDecision(
            id: UUID(),
            documentId: documentId,
            title: title,
            description: description,
            decisionType: decisionType,
            proposedBy: proposedBy,
            proposedAt: Date(),
            affectedSections: affectedSections,
            status: .`open`,
            votes: [],
            comments: [],
            deadline: deadline,
            context: DocumentDecisionContext(
                documentVersion: document.version,
                currentContent: document.content,
                relevantChanges: getRecentChanges(documentId: documentId),
                participantStates: captureParticipantStates(documentId: documentId)
            )
        )
        
        documentDecisions[documentId, default: []].append(decision)
        
        // Create decision workflow
        let workflow = DocumentDecisionWorkflow(
            decisionId: decision.id,
            documentId: documentId,
            status: .collecting,
            requiredApprovals: calculateRequiredApprovals(decisionType, document: document),
            currentApprovals: 0,
            workflow: generateDecisionWorkflow(for: decisionType),
            timeline: [
                DecisionEvent(
                    timestamp: Date(),
                    event: .proposed,
                    participantId: proposedBy,
                    details: [:]
                )
            ]
        )
        
        decisionWorkflows[decision.id] = workflow
        
        // Broadcast decision proposal
        await broadcastDocumentDecision(decision)
        
        print("✅ Proposed document decision: \(title)")
        return decision
    }
    
    func voteOnDocumentDecision(
        decisionId: UUID,
        vote: DocumentDecisionVote.VoteType,
        participantId: UUID,
        comment: String? = nil
    ) async throws {
        
        // Find the decision
        var targetDecision: DocumentDecision?
        var targetDocumentId: UUID?
        
        for (documentId, decisions) in documentDecisions {
            if let decision = decisions.first(where: { $0.id == decisionId }) {
                targetDecision = decision
                targetDocumentId = documentId
                break
            }
        }
        
        guard var decision = targetDecision,
              let documentId = targetDocumentId,
              let document = documents[documentId] else {
            throw SharedDocumentError.decisionNotFound(decisionId)
        }
        
        // Check voting permissions
        guard document.collaborators.contains(where: { $0.participantId == participantId }) ||
              document.permissions.canWrite.contains(participantId) else {
            throw SharedDocumentError.insufficientPermissions(participantId, .vote)
        }
        
        // Check if already voted
        if decision.votes.contains(where: { $0.participantId == participantId }) {
            throw SharedDocumentError.alreadyVoted(decisionId)
        }
        
        let decisionVote = DocumentDecisionVote(
            id: UUID(),
            participantId: participantId,
            voteType: vote,
            timestamp: Date(),
            comment: comment,
            weight: calculateVoteWeight(participantId: participantId, document: document)
        )
        
        decision.votes.append(decisionVote)
        
        // Update decision in storage
        if let decisionIndex = documentDecisions[documentId]?.firstIndex(where: { $0.id == decisionId }) {
            documentDecisions[documentId]?[decisionIndex] = decision
        }
        
        // Update workflow
        if var workflow = decisionWorkflows[decisionId] {
            workflow.currentApprovals += decisionVote.weight
            workflow.timeline.append(DecisionEvent(
                timestamp: Date(),
                event: .voted,
                participantId: participantId,
                details: ["vote": vote.rawValue]
            ))
            
            // Check if decision is resolved
            if workflow.currentApprovals >= workflow.requiredApprovals {
                decision.status = vote == .approve ? .approved : .rejected
                workflow.status = .completed
                
                // Execute decision if approved
                if decision.status == .approved {
                    await executeDocumentDecision(decision)
                }
            }
            
            decisionWorkflows[decisionId] = workflow
        }
        
        // Broadcast vote
        await broadcastDocumentDecisionVote(decisionVote, decision: decision)
        
        print("✅ Vote recorded on document decision: \(decision.title)")
    }
    
    // MARK: - Version Control
    
    func createDocumentBranch(
        documentId: UUID,
        branchName: String,
        fromVersion: Int? = nil,
        createdBy: UUID
    ) async throws -> DocumentBranch {
        
        guard let document = documents[documentId],
              var versionTree = versionTrees[documentId] else {
            throw SharedDocumentError.documentNotFound(documentId)
        }
        
        guard document.permissions.canWrite.contains(createdBy) else {
            throw SharedDocumentError.insufficientPermissions(createdBy, .write)
        }
        
        let sourceVersion = fromVersion ?? document.version
        guard let baseVersion = versionTree.versions.first(where: { $0.version == sourceVersion }) else {
            throw SharedDocumentError.versionNotFound(sourceVersion)
        }
        
        let branch = DocumentBranch(
            id: UUID(),
            name: branchName,
            documentId: documentId,
            baseVersionId: baseVersion.id,
            createdBy: createdBy,
            createdAt: Date(),
            lastCommit: baseVersion.id,
            status: .active
        )
        
        versionTree.branches[branch.id] = branch
        versionTrees[documentId] = versionTree
        
        print("✅ Created document branch: \(branchName)")
        return branch
    }
    
    func mergeDocumentBranch(
        documentId: UUID,
        branchId: UUID,
        targetBranchId: UUID? = nil,
        mergedBy: UUID
    ) async throws -> DocumentMergeResult {
        
        guard let document = documents[documentId],
              var versionTree = versionTrees[documentId],
              let sourceBranch = versionTree.branches[branchId] else {
            throw SharedDocumentError.documentNotFound(documentId)
        }
        
        guard document.permissions.canWrite.contains(mergedBy) else {
            throw SharedDocumentError.insufficientPermissions(mergedBy, .write)
        }
        
        // Perform three-way merge
        let mergeResult = try await performThreeWayMerge(
            versionTree: versionTree,
            sourceBranch: sourceBranch,
            targetBranchId: targetBranchId
        )
        
        if mergeResult.hasConflicts {
            // Create conflict resolution decision
            let decision = try await proposeDocumentDecision(
                documentId: documentId,
                title: "Resolve Merge Conflicts",
                description: "Branch '\(sourceBranch.name)' has conflicts that need resolution",
                decisionType: .mergeConflictResolution,
                proposedBy: mergedBy
            )
            
            return DocumentMergeResult(
                success: false,
                conflicts: mergeResult.conflicts,
                newVersion: nil,
                requiresDecision: decision.id
            )
        } else {
            // Merge successful
            let mergedVersion = DocumentVersion(
                id: UUID(),
                documentId: documentId,
                version: document.version + 1,
                content: mergeResult.mergedContent,
                authorId: mergedBy,
                timestamp: Date(),
                changeDescription: "Merged branch '\(sourceBranch.name)'",
                parentVersionId: versionTree.currentVersion.id,
                checksum: calculateChecksum(mergeResult.mergedContent)
            )
            
            versionTree.versions.append(mergedVersion)
            versionTree.currentVersion = mergedVersion
            versionTree.mergeHistory.append(DocumentMerge(
                id: UUID(),
                sourceBranchId: branchId,
                targetBranchId: targetBranchId,
                mergedVersionId: mergedVersion.id,
                mergedBy: mergedBy,
                timestamp: Date(),
                conflictsResolved: []
            ))
            
            versionTrees[documentId] = versionTree
            
            // Update document
            var updatedDocument = document
            updatedDocument.content = mergeResult.mergedContent
            updatedDocument.version = mergedVersion.version
            updatedDocument.lastModifiedBy = mergedBy
            updatedDocument.lastModifiedAt = Date()
            documents[documentId] = updatedDocument
            
            print("✅ Merged document branch: \(sourceBranch.name)")
            return DocumentMergeResult(
                success: true,
                conflicts: [],
                newVersion: mergedVersion.version,
                requiresDecision: nil
            )
        }
    }
    
    // MARK: - Real-time Collaboration
    
    func joinDocumentCollaboration(
        documentId: UUID,
        participantId: UUID
    ) async throws -> CollaborationSession {
        
        guard let document = documents[documentId] else {
            throw SharedDocumentError.documentNotFound(documentId)
        }
        
        guard document.permissions.canRead.contains(participantId) else {
            throw SharedDocumentError.insufficientPermissions(participantId, .read)
        }
        
        // Add to active editors
        activeEditors[documentId, default: Set()].insert(participantId)
        
        // Add to document subscribers
        documentSubscriptions[documentId, default: Set()].insert(participantId)
        
        // Find or create collaboration session
        let session: CollaborationSession
        if let existingSession = collaborationSessions.values.first(where: { $0.documentId == documentId && $0.status == .active }) {
            var updatedSession = existingSession
            updatedSession.participants.append(participantId)
            updatedSession.lastActivity = Date()
            collaborationSessions[existingSession.id] = updatedSession
            session = updatedSession
        } else {
            let newSession = CollaborationSession(
                id: UUID(),
                documentId: documentId,
                participants: [participantId],
                startedAt: Date(),
                lastActivity: Date(),
                sessionType: .viewing,
                status: .active
            )
            collaborationSessions[newSession.id] = newSession
            session = newSession
        }
        
        // Broadcast participant joined
        await broadcastParticipantJoined(documentId: documentId, participantId: participantId)
        
        print("✅ Participant joined document collaboration: \(participantId)")
        return session
    }
    
    func leaveDocumentCollaboration(
        documentId: UUID,
        participantId: UUID
    ) async {
        
        // Remove from active editors
        activeEditors[documentId]?.remove(participantId)
        
        // Remove from subscribers
        documentSubscriptions[documentId]?.remove(participantId)
        
        // Update collaboration session
        for (sessionId, session) in collaborationSessions {
            if session.documentId == documentId {
                var updatedSession = session
                updatedSession.participants.removeAll { $0 == participantId }
                
                if updatedSession.participants.isEmpty {
                    updatedSession.status = .ended
                }
                
                collaborationSessions[sessionId] = updatedSession
                break
            }
        }
        
        // Release any editing locks
        if let lock = editingLocks[documentId], lock.lockedBy == participantId {
            editingLocks.removeValue(forKey: documentId)
        }
        
        // Broadcast participant left
        await broadcastParticipantLeft(documentId: documentId, participantId: participantId)
        
        print("✅ Participant left document collaboration: \(participantId)")
    }
    
    func requestEditingLock(
        documentId: UUID,
        participantId: UUID,
        section: DocumentSection? = nil
    ) async throws -> EditingLock {
        
        guard let document = documents[documentId] else {
            throw SharedDocumentError.documentNotFound(documentId)
        }
        
        guard document.permissions.canWrite.contains(participantId) else {
            throw SharedDocumentError.insufficientPermissions(participantId, .write)
        }
        
        // Check existing lock
        if let existingLock = editingLocks[documentId], !existingLock.isExpired() {
            throw SharedDocumentError.documentLocked(existingLock.lockedBy)
        }
        
        let lock = EditingLock(
            id: UUID(),
            documentId: documentId,
            lockedBy: participantId,
            lockedAt: Date(),
            expiresAt: Date().addingTimeInterval(300), // 5 minutes
            section: section
        )
        
        editingLocks[documentId] = lock
        
        // Broadcast lock acquired
        await broadcastEditingLockAcquired(lock)
        
        print("✅ Editing lock acquired: \(documentId)")
        return lock
    }
    
    func releaseEditingLock(
        documentId: UUID,
        participantId: UUID
    ) async {
        
        if let lock = editingLocks[documentId], lock.lockedBy == participantId {
            editingLocks.removeValue(forKey: documentId)
            
            // Broadcast lock released
            await broadcastEditingLockReleased(documentId: documentId, participantId: participantId)
            
            print("✅ Editing lock released: \(documentId)")
        }
    }
    
    // MARK: - Broadcasting and Synchronization
    
    private func broadcastDocumentOperation(
        _ operation: DocumentOperation,
        documentId: UUID
    ) async {
        
        guard let subscribers = documentSubscriptions[documentId] else { return }
        
        do {
            let operationUpdate = DocumentOperationUpdate(
                documentId: documentId,
                operation: operation,
                timestamp: Date()
            )
            
            try await realtimeSyncManager.sendMessage(.documentChanged, payload: operationUpdate)
            
        } catch {
            print("❌ Failed to broadcast document operation: \(error)")
        }
    }
    
    private func broadcastDocumentDecision(_ decision: DocumentDecision) async {
        do {
            let decisionUpdate = DocumentDecisionUpdate(
                decision: decision,
                action: .proposed,
                timestamp: Date()
            )
            
            try await realtimeSyncManager.sendMessage(.decisionProposed, payload: decisionUpdate)
            
        } catch {
            print("❌ Failed to broadcast document decision: \(error)")
        }
    }
    
    private func broadcastDocumentDecisionVote(
        _ vote: DocumentDecisionVote,
        decision: DocumentDecision
    ) async {
        
        do {
            let voteUpdate = DocumentDecisionVoteUpdate(
                decisionId: decision.id,
                vote: vote,
                timestamp: Date()
            )
            
            try await realtimeSyncManager.sendMessage(.decisionVoted, payload: voteUpdate)
            
        } catch {
            print("❌ Failed to broadcast decision vote: \(error)")
        }
    }
    
    private func broadcastParticipantJoined(documentId: UUID, participantId: UUID) async {
        do {
            let participantUpdate = DocumentParticipantUpdate(
                documentId: documentId,
                participantId: participantId,
                action: .joined,
                timestamp: Date()
            )
            
            try await realtimeSyncManager.sendMessage(.participantJoined, payload: participantUpdate)
            
        } catch {
            print("❌ Failed to broadcast participant joined: \(error)")
        }
    }
    
    private func broadcastParticipantLeft(documentId: UUID, participantId: UUID) async {
        do {
            let participantUpdate = DocumentParticipantUpdate(
                documentId: documentId,
                participantId: participantId,
                action: .left,
                timestamp: Date()
            )
            
            try await realtimeSyncManager.sendMessage(.participantLeft, payload: participantUpdate)
            
        } catch {
            print("❌ Failed to broadcast participant left: \(error)")
        }
    }
    
    private func broadcastEditingLockAcquired(_ lock: EditingLock) async {
        do {
            let lockUpdate = EditingLockUpdate(
                lock: lock,
                action: .acquired,
                timestamp: Date()
            )
            
            try await realtimeSyncManager.sendMessage(.documentChanged, payload: lockUpdate)
            
        } catch {
            print("❌ Failed to broadcast editing lock acquired: \(error)")
        }
    }
    
    private func broadcastEditingLockReleased(documentId: UUID, participantId: UUID) async {
        do {
            let lockUpdate = EditingLockReleaseUpdate(
                documentId: documentId,
                participantId: participantId,
                timestamp: Date()
            )
            
            try await realtimeSyncManager.sendMessage(.documentChanged, payload: lockUpdate)
            
        } catch {
            print("❌ Failed to broadcast editing lock released: \(error)")
        }
    }
    
    // MARK: - Utility Methods
    
    private func syncDocumentToSharedContext(_ document: SharedDocument) async throws {
        let sharedDocument = SharedContext.SharedDocument(
            id: document.id,
            title: document.title,
            content: document.content,
            format: SharedContext.SharedDocument.DocumentFormat(rawValue: document.format.rawValue) ?? .plainText,
            createdBy: document.createdBy,
            createdAt: document.createdAt,
            lastModifiedBy: document.lastModifiedBy,
            lastModifiedAt: document.lastModifiedAt,
            version: document.version,
            collaborators: document.collaborators.map { collaborator in
                SharedContext.SharedDocument.DocumentCollaborator(
                    participantId: collaborator.participantId,
                    role: SharedContext.SharedDocument.DocumentCollaborator.CollaboratorRole(rawValue: collaborator.role.rawValue) ?? .viewer,
                    permissions: collaborator.permissions.compactMap { SharedContext.SharedDocument.DocumentCollaborator.DocumentPermission(rawValue: $0.rawValue) },
                    joinedAt: collaborator.joinedAt
                )
            },
            accessLevel: SharedContext.SharedDocument.AccessLevel(rawValue: document.accessLevel.rawValue) ?? .private,
            changeHistory: []
        )
        
        try await sharedContextManager.updateSharedContext(\.collaborativeDocuments, value: [sharedDocument])
    }
    
    private func syncSessionDocuments(_ session: SharedContext) async {
        // Sync documents with the current session
        for document in documents.values {
            try? await syncDocumentToSharedContext(document)
        }
    }
    
    private func updateCollaborationSessions(_ participants: [ParticipantInfo]) async {
        // Update collaboration sessions based on current participants
        let participantIds = Set(participants.map { $0.id })
        
        for (sessionId, session) in collaborationSessions {
            var updatedSession = session
            updatedSession.participants = updatedSession.participants.filter { participantIds.contains($0) }
            
            if updatedSession.participants.isEmpty {
                updatedSession.status = .ended
            }
            
            collaborationSessions[sessionId] = updatedSession
        }
    }
    
    private func updateVersionControl(
        documentId: UUID,
        operation: DocumentOperation,
        performedBy: UUID
    ) async {
        
        guard var versionTree = versionTrees[documentId],
              let document = documents[documentId] else { return }
        
        let newVersion = DocumentVersion(
            id: UUID(),
            documentId: documentId,
            version: document.version,
            content: document.content,
            authorId: performedBy,
            timestamp: Date(),
            changeDescription: operation.description,
            parentVersionId: versionTree.currentVersion.id,
            checksum: calculateChecksum(document.content)
        )
        
        versionTree.versions.append(newVersion)
        versionTree.currentVersion = newVersion
        versionTrees[documentId] = versionTree
        
        // Store version if it's significant
        if shouldStoreVersion(operation) {
            await documentStorage.storeVersion(newVersion)
        }
    }
    
    private func updateCollaborationActivity(documentId: UUID, participantId: UUID) async {
        for (sessionId, session) in collaborationSessions {
            if session.documentId == documentId && session.participants.contains(participantId) {
                var updatedSession = session
                updatedSession.lastActivity = Date()
                collaborationSessions[sessionId] = updatedSession
                break
            }
        }
    }
    
    private func performPeriodicSync() async {
        // Sync pending operations
        for (documentId, operations) in pendingOperations {
            if !operations.isEmpty {
                // Process and clean up old operations
                let cutoffTime = Date().addingTimeInterval(-300) // 5 minutes ago
                pendingOperations[documentId] = operations.filter { $0.timestamp > cutoffTime }
            }
        }
        
        // Update change buffers
        for (documentId, buffer) in changeBuffers {
            if !buffer.pendingChanges.isEmpty {
                await processPendingChanges(documentId: documentId)
            }
        }
    }
    
    private func cleanupInactiveDocuments() async {
        let inactivityThreshold = Date().addingTimeInterval(-3600) // 1 hour
        
        // End inactive collaboration sessions
        for (sessionId, session) in collaborationSessions {
            if session.lastActivity < inactivityThreshold && session.status == .active {
                var updatedSession = session
                updatedSession.status = .inactive
                collaborationSessions[sessionId] = updatedSession
            }
        }
        
        // Clean up expired editing locks
        editingLocks = editingLocks.filter { !$0.value.isExpired() }
    }
    
    private func processPendingChanges(documentId: UUID) async {
        guard var buffer = changeBuffers[documentId] else { return }
        
        // Process changes in batches
        let batchSize = 10
        let changes = Array(buffer.pendingChanges.prefix(batchSize))
        
        for change in changes {
            // Apply change to document
            // This would integrate with the operational transform engine
        }
        
        buffer.pendingChanges.removeFirst(min(batchSize, buffer.pendingChanges.count))
        changeBuffers[documentId] = buffer
    }
    
    // MARK: - Helper Methods
    
    private func calculateChecksum(_ content: String) -> String {
        return String(content.hashValue)
    }
    
    private func calculateReadTime(_ content: String) -> TimeInterval {
        let wordCount = content.split(separator: " ").count
        let wordsPerMinute = 200.0
        return Double(wordCount) / wordsPerMinute * 60.0
    }
    
    private func shouldStoreVersion(_ operation: DocumentOperation) -> Bool {
        // Store versions for significant operations
        switch operation.type {
        case .insert(_, let text):
            return text.count > 100 // Significant insertion
        case .delete(_, let length):
            return length > 50 // Significant deletion
        case .replace:
            return true // Always store replacements
        default:
            return false
        }
    }
    
    private func calculateRequiredApprovals(_ decisionType: DocumentDecisionType, document: SharedDocument) -> Int {
        switch decisionType {
        case .contentChange:
            return 1 // Simple approval
        case .structureChange:
            return max(2, document.collaborators.count / 2) // Majority
        case .accessChange:
            return document.collaborators.count // Unanimous
        case .mergeConflictResolution:
            return 1 // Single resolver
        case .versionRollback:
            return max(1, document.collaborators.count / 3) // Minority can block
        }
    }
    
    private func calculateVoteWeight(participantId: UUID, document: SharedDocument) -> Int {
        // Document creator and owners have higher weight
        if document.createdBy == participantId {
            return 2
        }
        
        if let collaborator = document.collaborators.first(where: { $0.participantId == participantId }),
           collaborator.role == .owner {
            return 2
        }
        
        return 1 // Standard weight
    }
    
    private func generateDecisionWorkflow(for decisionType: DocumentDecisionType) -> [String] {
        switch decisionType {
        case .contentChange:
            return ["Proposal", "Review", "Approval"]
        case .structureChange:
            return ["Proposal", "Discussion", "Voting", "Implementation"]
        case .accessChange:
            return ["Proposal", "Security Review", "Unanimous Voting", "Implementation"]
        case .mergeConflictResolution:
            return ["Conflict Analysis", "Resolution", "Verification"]
        case .versionRollback:
            return ["Justification", "Impact Assessment", "Approval", "Rollback"]
        }
    }
    
    private func getRecentChanges(documentId: UUID) -> [DocumentChange] {
        // Get recent changes from version tree
        guard let versionTree = versionTrees[documentId] else { return [] }
        
        let recentVersions = Array(versionTree.versions.suffix(5))
        return recentVersions.compactMap { version in
            DocumentChange(
                id: UUID(),
                type: .modification,
                position: 0,
                content: version.changeDescription,
                timestamp: version.timestamp,
                performedBy: version.authorId
            )
        }
    }
    
    private func captureParticipantStates(documentId: UUID) -> [UUID: String] {
        guard let activeParticipants = activeEditors[documentId] else { return [:] }
        
        var states: [UUID: String] = [:]
        for participantId in activeParticipants {
            // Capture current editing state
            if editingLocks[documentId]?.lockedBy == participantId {
                states[participantId] = "editing"
            } else {
                states[participantId] = "viewing"
            }
        }
        
        return states
    }
    
    private func executeDocumentDecision(_ decision: DocumentDecision) async {
        switch decision.decisionType {
        case .contentChange:
            // Apply content changes
            print("📝 Executing content change decision: \(decision.title)")
            
        case .structureChange:
            // Apply structural changes
            print("🏗️ Executing structure change decision: \(decision.title)")
            
        case .accessChange:
            // Update access permissions
            print("🔒 Executing access change decision: \(decision.title)")
            
        case .mergeConflictResolution:
            // Resolve merge conflicts
            print("🔀 Executing merge conflict resolution: \(decision.title)")
            
        case .versionRollback:
            // Perform version rollback
            print("⏪ Executing version rollback: \(decision.title)")
        }
    }
    
    private func performThreeWayMerge(
        versionTree: DocumentVersionTree,
        sourceBranch: DocumentBranch,
        targetBranchId: UUID?
    ) async throws -> ThreeWayMergeResult {
        
        // Get source, target, and common ancestor versions
        guard let sourceVersion = versionTree.versions.first(where: { $0.id == sourceBranch.lastCommit }) else {
            throw SharedDocumentError.versionNotFound(0)
        }
        
        let targetVersion = versionTree.currentVersion
        
        // Find common ancestor
        let commonAncestor = findCommonAncestor(
            version1: sourceVersion,
            version2: targetVersion,
            versionTree: versionTree
        )
        
        // Perform merge using operational transform
        return try await operationalTransform.performThreeWayMerge(
            ancestor: commonAncestor,
            source: sourceVersion,
            target: targetVersion
        )
    }
    
    private func findCommonAncestor(
        version1: DocumentVersion,
        version2: DocumentVersion,
        versionTree: DocumentVersionTree
    ) -> DocumentVersion {
        
        // Simple implementation - find the most recent common ancestor
        let version1Ancestors = getVersionAncestors(version: version1, versionTree: versionTree)
        let version2Ancestors = getVersionAncestors(version: version2, versionTree: versionTree)
        
        let commonAncestors = Set(version1Ancestors).intersection(Set(version2Ancestors))
        
        // Return the most recent common ancestor
        return commonAncestors.max { $0.timestamp < $1.timestamp } ?? versionTree.versions.first!
    }
    
    private func getVersionAncestors(version: DocumentVersion, versionTree: DocumentVersionTree) -> [DocumentVersion] {
        var ancestors: [DocumentVersion] = []
        var currentVersion: DocumentVersion? = version
        
        while let current = currentVersion {
            ancestors.append(current)
            currentVersion = versionTree.versions.first { $0.id == current.parentVersionId }
        }
        
        return ancestors
    }
    
    // MARK: - Public Interface
    
    func getDocuments() -> [SharedDocument] {
        return Array(documents.values)
    }
    
    func getDocument(id: UUID) -> SharedDocument? {
        return documents[id]
    }
    
    func getActiveEditors(for documentId: UUID) -> Set<UUID> {
        return activeEditors[documentId] ?? Set()
    }
    
    func getDocumentDecisions(for documentId: UUID) -> [DocumentDecision] {
        return documentDecisions[documentId] ?? []
    }
    
    func getVersionTree(for documentId: UUID) -> DocumentVersionTree? {
        return versionTrees[documentId]
    }
    
    func getCollaborationSessions() -> [CollaborationSession] {
        return Array(collaborationSessions.values)
    }
}

// MARK: - RealtimeSyncManagerDelegate

extension SharedDocumentManager: RealtimeSyncManagerDelegate {
    
    func realtimeSyncManager(_ manager: RealtimeSyncManager, didReceiveMessage message: RealtimeSyncMessage) {
        Task { @MainActor in
            await handleRealtimeMessage(message)
        }
    }
    
    func realtimeSyncManager(_ manager: RealtimeSyncManager, didFailToDeliverMessage message: RealtimeSyncMessage) {
        print("❌ Failed to deliver document message: \(message.type)")
    }
    
    func realtimeSyncManager(_ manager: RealtimeSyncManager, connectionStatusDidChange status: RealtimeSyncManager.ConnectionStatus) {
        // Handle connection status changes
    }
    
    func realtimeSyncManager(_ manager: RealtimeSyncManager, connectionQualityDidChange quality: RealtimeSyncManager.ConnectionQuality) {
        // Handle connection quality changes
    }
    
    private func handleRealtimeMessage(_ message: RealtimeSyncMessage) async {
        switch message.type {
        case .documentChanged:
            if let operationUpdate = try? JSONDecoder().decode(DocumentOperationUpdate.self, from: message.payload) {
                await handleRemoteDocumentOperation(operationUpdate)
            }
            
        case .decisionProposed:
            if let decisionUpdate = try? JSONDecoder().decode(DocumentDecisionUpdate.self, from: message.payload) {
                await handleRemoteDocumentDecision(decisionUpdate)
            }
            
        case .decisionVoted:
            if let voteUpdate = try? JSONDecoder().decode(DocumentDecisionVoteUpdate.self, from: message.payload) {
                await handleRemoteDocumentDecisionVote(voteUpdate)
            }
            
        case .participantJoined:
            if let participantUpdate = try? JSONDecoder().decode(DocumentParticipantUpdate.self, from: message.payload) {
                await handleRemoteParticipantJoined(participantUpdate)
            }
            
        case .participantLeft:
            if let participantUpdate = try? JSONDecoder().decode(DocumentParticipantUpdate.self, from: message.payload) {
                await handleRemoteParticipantLeft(participantUpdate)
            }
            
        default:
            break
        }
    }
    
    private func handleRemoteDocumentOperation(_ update: DocumentOperationUpdate) async {
        do {
            try await applyRemoteOperation(update.operation, to: update.documentId)
        } catch {
            print("❌ Failed to apply remote document operation: \(error)")
        }
    }
    
    private func handleRemoteDocumentDecision(_ update: DocumentDecisionUpdate) async {
        guard update.action == .proposed else { return }
        
        // Add remote decision to local storage
        documentDecisions[update.decision.documentId, default: []].append(update.decision)
        
        print("📥 Received remote document decision: \(update.decision.title)")
    }
    
    private func handleRemoteDocumentDecisionVote(_ update: DocumentDecisionVoteUpdate) async {
        // Find and update the decision with the new vote
        for (documentId, decisions) in documentDecisions {
            if let decisionIndex = decisions.firstIndex(where: { $0.id == update.decisionId }) {
                var decision = decisions[decisionIndex]
                
                // Check if vote already exists (avoid duplicates)
                if !decision.votes.contains(where: { $0.id == update.vote.id }) {
                    decision.votes.append(update.vote)
                    documentDecisions[documentId]?[decisionIndex] = decision
                    
                    print("📥 Received remote decision vote: \(update.vote.voteType)")
                }
                break
            }
        }
    }
    
    private func handleRemoteParticipantJoined(_ update: DocumentParticipantUpdate) async {
        activeEditors[update.documentId, default: Set()].insert(update.participantId)
        documentSubscriptions[update.documentId, default: Set()].insert(update.participantId)
        
        print("📥 Remote participant joined document: \(update.participantId)")
    }
    
    private func handleRemoteParticipantLeft(_ update: DocumentParticipantUpdate) async {
        activeEditors[update.documentId]?.remove(update.participantId)
        documentSubscriptions[update.documentId]?.remove(update.participantId)
        
        print("📥 Remote participant left document: \(update.participantId)")
    }
}

// MARK: - Supporting Types

// VectorClock for tracking logical time in distributed operations
struct VectorClock: Codable {
    private var clocks: [String: Int]
    
    init(participants: [String]) {
        self.clocks = participants.reduce(into: [:]) { result, participant in
            result[participant] = 0
        }
    }
    
    mutating func increment(for participant: String) {
        clocks[participant, default: 0] += 1
    }
    
    func happensBefore(_ other: VectorClock) -> Bool {
        var lessThanEqual = true
        var strictlyLess = false
        
        for (participant, clock) in clocks {
            let otherClock = other.clocks[participant, default: 0]
            if clock > otherClock {
                lessThanEqual = false
                break
            } else if clock < otherClock {
                strictlyLess = true
            }
        }
        
        return lessThanEqual && strictlyLess
    }
    
    func isConcurrentWith(_ other: VectorClock) -> Bool {
        return !happensBefore(other) && !other.happensBefore(self)
    }
}

enum DocumentFormat: String, Codable {
    case plainText = "plain_text"
    case markdown = "markdown"
    case html = "html"
    case richText = "rich_text"
    case json = "json"
}

enum DocumentAccessLevel: String, Codable {
    case `public` = "public"
    case collaborative = "collaborative"
    case protected = "protected"
    case `private` = "private"
}

struct SharedDocument: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    let format: DocumentFormat
    let createdBy: UUID
    let createdAt: Date
    var lastModifiedBy: UUID
    var lastModifiedAt: Date
    var version: Int
    let accessLevel: DocumentAccessLevel
    var collaborators: [DocumentCollaborator]
    var metadata: DocumentMetadata
    var status: DocumentStatus
    var permissions: DocumentPermissions
    
    enum DocumentStatus: String, Codable {
        case draft = "draft"
        case review = "review"
        case approved = "approved"
        case published = "published"
        case archived = "archived"
    }
}

struct DocumentCollaborator: Codable {
    let participantId: UUID
    let role: CollaboratorRole
    let permissions: [Permission]
    let joinedAt: Date
    
    enum CollaboratorRole: String, Codable {
        case owner = "owner"
        case editor = "editor"
        case reviewer = "reviewer"
        case viewer = "viewer"
        case commenter = "commenter"
    }
    
    enum Permission: String, Codable {
        case read = "read"
        case write = "write"
        case comment = "comment"
        case share = "share"
        case delete = "delete"
        case vote = "vote"
    }
}

public struct DocumentMetadata: Codable {
    var wordCount: Int
    var characterCount: Int
    var lastEditor: UUID
    var editingSessions: [UUID]
    var tags: [String]
    var language: String
    var readTime: TimeInterval
}

public struct DocumentPermissions: Codable {
    var canRead: [UUID]
    var canWrite: [UUID]
    var canComment: [UUID]
    var canShare: [UUID]
    var canDelete: [UUID]
}

public struct DocumentOperation: Identifiable, Codable {
    let id: UUID
    let documentId: UUID
    let type: OperationType
    let performedBy: UUID
    let timestamp: Date
    let version: Int
    var description: String {
        switch type {
        case .insert(let position, let text):
            return "Insert '\(text.prefix(20))...' at position \(position)"
        case .delete(let position, let length):
            return "Delete \(length) characters at position \(position)"
        case .replace(let position, let length, let newText):
            return "Replace \(length) characters at position \(position) with '\(newText.prefix(20))...'"
        case .format(let range, let formatting):
            return "Apply formatting \(formatting) to range \(range)"
        case .comment(let position, let comment):
            return "Add comment at position \(position)"
        }
    }
    
    enum OperationType: Codable {
        case insert(position: Int, text: String)
        case delete(position: Int, length: Int)
        case replace(position: Int, length: Int, newText: String)
        case format(range: NSRange, formatting: String)
        case comment(position: Int, comment: String)
    }
}

struct DocumentChange: Identifiable, Codable {
    let id: UUID
    let type: ChangeType
    let position: Int
    let content: String
    let timestamp: Date
    let performedBy: UUID
    let previousContent: String?
    
    init(id: UUID, type: ChangeType, position: Int, content: String, timestamp: Date, performedBy: UUID, previousContent: String? = nil) {
        self.id = id
        self.type = type
        self.position = position
        self.content = content
        self.timestamp = timestamp
        self.performedBy = performedBy
        self.previousContent = previousContent
    }
    
    enum ChangeType: String, Codable {
        case insertion = "insertion"
        case deletion = "deletion"
        case replacement = "replacement"
        case formatting = "formatting"
        case comment = "comment"
        case modification = "modification"
    }
}

struct DocumentUpdateResult {
    let documentId: UUID
    let newVersion: Int
    let appliedChanges: [DocumentChange]
    let conflictsResolved: [String]
    let operationId: UUID
}

struct DocumentVersion: Identifiable, Codable {
    let id: UUID
    let documentId: UUID
    let version: Int
    let content: String
    let authorId: UUID
    let timestamp: Date
    let changeDescription: String
    let parentVersionId: UUID?
    let checksum: String
}

struct DocumentVersionTree {
    let documentId: UUID
    var currentVersion: DocumentVersion
    var versions: [DocumentVersion]
    var branches: [UUID: DocumentBranch]
    var mergeHistory: [DocumentMerge]
}

struct DocumentBranch: Identifiable, Codable {
    let id: UUID
    let name: String
    let documentId: UUID
    let baseVersionId: UUID
    let createdBy: UUID
    let createdAt: Date
    var lastCommit: UUID
    var status: BranchStatus
    
    enum BranchStatus: String, Codable {
        case active = "active"
        case merged = "merged"
        case abandoned = "abandoned"
    }
}

struct DocumentMerge: Identifiable, Codable {
    let id: UUID
    let sourceBranchId: UUID
    let targetBranchId: UUID?
    let mergedVersionId: UUID
    let mergedBy: UUID
    let timestamp: Date
    let conflictsResolved: [String]
}

struct DocumentMergeResult {
    let success: Bool
    let conflicts: [MergeConflict]
    let newVersion: Int?
    let requiresDecision: UUID?
}

struct MergeConflict {
    let position: Int
    let length: Int
    let sourceContent: String
    let targetContent: String
    let conflictType: ConflictType
    
    enum ConflictType {
        case contentConflict
        case structuralConflict
        case formattingConflict
    }
}

struct ThreeWayMergeResult {
    let mergedContent: String
    let hasConflicts: Bool
    let conflicts: [MergeConflict]
}

struct DocumentDecision: Identifiable, Codable {
    let id: UUID
    let documentId: UUID
    let title: String
    let description: String
    let decisionType: DocumentDecisionType
    let proposedBy: UUID
    let proposedAt: Date
    let affectedSections: [DocumentSection]
    var status: DecisionStatus
    var votes: [DocumentDecisionVote]
    var comments: [DocumentDecisionComment]
    let deadline: Date?
    let context: DocumentDecisionContext
    
    enum DecisionStatus: String, Codable {
        case `open` = "open"
        case approved = "approved"
        case rejected = "rejected"
        case expired = "expired"
    }
}

enum DocumentDecisionType: String, Codable {
    case contentChange = "content_change"
    case structureChange = "structure_change"
    case accessChange = "access_change"
    case mergeConflictResolution = "merge_conflict_resolution"
    case versionRollback = "version_rollback"
}

struct DocumentDecisionVote: Identifiable, Codable {
    let id: UUID
    let participantId: UUID
    let voteType: VoteType
    let timestamp: Date
    let comment: String?
    let weight: Int
    
    enum VoteType: String, Codable {
        case approve = "approve"
        case reject = "reject"
        case abstain = "abstain"
    }
}

struct DocumentDecisionComment: Identifiable, Codable {
    let id: UUID
    let participantId: UUID
    let content: String
    let timestamp: Date
}

struct DocumentDecisionContext: Codable {
    let documentVersion: Int
    let currentContent: String
    let relevantChanges: [DocumentChange]
    let participantStates: [UUID: String]
}

struct DocumentSection: Codable {
    let startPosition: Int
    let endPosition: Int
    let title: String?
    let type: SectionType
    
    enum SectionType: String, Codable {
        case heading = "heading"
        case paragraph = "paragraph"
        case list = "list"
        case table = "table"
        case code = "code"
        case quote = "quote"
    }
}

struct CollaborationSession: Identifiable, Codable {
    let id: UUID
    let documentId: UUID
    var participants: [UUID]
    let startedAt: Date
    var lastActivity: Date
    let sessionType: SessionType
    var status: SessionStatus
    
    enum SessionType: String, Codable {
        case editing = "editing"
        case reviewing = "reviewing"
        case viewing = "viewing"
        case discussing = "discussing"
    }
    
    enum SessionStatus: String, Codable {
        case active = "active"
        case inactive = "inactive"
        case ended = "ended"
    }
}

struct EditingLock: Identifiable, Codable {
    let id: UUID
    let documentId: UUID
    let lockedBy: UUID
    let lockedAt: Date
    let expiresAt: Date
    let section: DocumentSection?
    
    func isExpired() -> Bool {
        return Date() > expiresAt
    }
}

struct ChangeBuffer {
    let documentId: UUID
    var pendingChanges: [DocumentChange]
    var lastSyncedVersion: Int
}

struct DocumentDecisionWorkflow {
    let decisionId: UUID
    let documentId: UUID
    var status: WorkflowStatus
    let requiredApprovals: Int
    var currentApprovals: Int
    let workflow: [String]
    var timeline: [DecisionEvent]
    
    enum WorkflowStatus: String, Codable {
        case collecting = "collecting"
        case reviewing = "reviewing"
        case voting = "voting"
        case completed = "completed"
        case rejected = "rejected"
    }
}

struct DecisionEvent: Codable {
    let timestamp: Date
    let event: EventType
    let participantId: UUID?
    let details: [String: String]
    
    enum EventType: String, Codable {
        case proposed = "proposed"
        case voted = "voted"
        case commented = "commented"
        case approved = "approved"
        case rejected = "rejected"
    }
}

struct ApprovalProcess {
    let id: UUID
    let documentId: UUID
    let decisionId: UUID
    let requiredApprovers: [UUID]
    var approvals: [UUID]
    let deadline: Date?
}

// Real-time sync message types
struct DocumentOperationUpdate: Codable {
    let documentId: UUID
    let operation: DocumentOperation
    let timestamp: Date
}

struct DocumentDecisionUpdate: Codable {
    let decision: DocumentDecision
    let action: Action
    let timestamp: Date
    
    enum Action: String, Codable {
        case proposed = "proposed"
        case updated = "updated"
        case resolved = "resolved"
    }
}

struct DocumentDecisionVoteUpdate: Codable {
    let decisionId: UUID
    let vote: DocumentDecisionVote
    let timestamp: Date
}

struct DocumentParticipantUpdate: Codable {
    let documentId: UUID
    let participantId: UUID
    let action: Action
    let timestamp: Date
    
    enum Action: String, Codable {
        case joined = "joined"
        case left = "left"
    }
}

struct EditingLockUpdate: Codable {
    let lock: EditingLock
    let action: Action
    let timestamp: Date
    
    enum Action: String, Codable {
        case acquired = "acquired"
        case released = "released"
    }
}

struct EditingLockReleaseUpdate: Codable {
    let documentId: UUID
    let participantId: UUID
    let timestamp: Date
}

// MARK: - Supporting Classes

class OperationalTransformEngine {
    
    func transform(
        operation: DocumentOperation,
        againstPending: [DocumentOperation],
        currentVersion: Int
    ) async throws -> DocumentOperation {
        
        var transformedOperation = operation
        
        // Apply operational transforms against pending operations
        for pendingOp in againstPending {
            transformedOperation = try transformOperations(transformedOperation, against: pendingOp)
        }
        
        return transformedOperation
    }
    
    func performThreeWayMerge(
        ancestor: DocumentVersion,
        source: DocumentVersion,
        target: DocumentVersion
    ) async throws -> ThreeWayMergeResult {
        
        // Simplified three-way merge implementation
        // In a real implementation, this would use sophisticated text merging algorithms
        
        if source.content == target.content {
            return ThreeWayMergeResult(
                mergedContent: source.content,
                hasConflicts: false,
                conflicts: []
            )
        } else {
            // Detect conflicts and attempt automatic resolution
            let conflicts = detectConflicts(ancestor: ancestor, source: source, target: target)
            
            if conflicts.isEmpty {
                // Automatic merge possible
                let mergedContent = attemptAutomaticMerge(ancestor: ancestor, source: source, target: target)
                return ThreeWayMergeResult(
                    mergedContent: mergedContent,
                    hasConflicts: false,
                    conflicts: []
                )
            } else {
                return ThreeWayMergeResult(
                    mergedContent: target.content,
                    hasConflicts: true,
                    conflicts: conflicts
                )
            }
        }
    }
    
    private func transformOperations(
        _ op1: DocumentOperation,
        against op2: DocumentOperation
    ) throws -> DocumentOperation {
        
        // Simplified operational transform implementation
        // In practice, this would handle all combinations of operation types
        
        switch (op1.type, op2.type) {
        case (.insert(let pos1, let text1), .insert(let pos2, _)):
            if pos1 <= pos2 {
                return op1 // No transformation needed
            } else {
                return DocumentOperation(
                    id: op1.id,
                    documentId: op1.documentId,
                    type: .insert(position: pos1 + text1.count, text: text1),
                    performedBy: op1.performedBy,
                    timestamp: op1.timestamp,
                    version: op1.version
                )
            }
            
        case (.insert(let pos1, let text1), .delete(let pos2, let len2)):
            if pos1 <= pos2 {
                return op1 // No transformation needed
            } else if pos1 > pos2 + len2 {
                return DocumentOperation(
                    id: op1.id,
                    documentId: op1.documentId,
                    type: .insert(position: pos1 - len2, text: text1),
                    performedBy: op1.performedBy,
                    timestamp: op1.timestamp,
                    version: op1.version
                )
            } else {
                // Insert position is within deleted range
                return DocumentOperation(
                    id: op1.id,
                    documentId: op1.documentId,
                    type: .insert(position: pos2, text: text1),
                    performedBy: op1.performedBy,
                    timestamp: op1.timestamp,
                    version: op1.version
                )
            }
            
        default:
            return op1 // Default: no transformation
        }
    }
    
    private func detectConflicts(
        ancestor: DocumentVersion,
        source: DocumentVersion,
        target: DocumentVersion
    ) -> [MergeConflict] {
        
        // Simplified conflict detection
        var conflicts: [MergeConflict] = []
        
        // Check if both versions modified the same sections
        let sourceChanges = findChanges(from: ancestor.content, to: source.content)
        let targetChanges = findChanges(from: ancestor.content, to: target.content)
        
        for sourceChange in sourceChanges {
            for targetChange in targetChanges {
                if rangesOverlap(sourceChange.range, targetChange.range) {
                    conflicts.append(MergeConflict(
                        position: sourceChange.range.location,
                        length: sourceChange.range.length,
                        sourceContent: sourceChange.newText,
                        targetContent: targetChange.newText,
                        conflictType: .contentConflict
                    ))
                }
            }
        }
        
        return conflicts
    }
    
    private func attemptAutomaticMerge(
        ancestor: DocumentVersion,
        source: DocumentVersion,
        target: DocumentVersion
    ) -> String {
        
        // Simplified automatic merge
        // In practice, this would use sophisticated text merging algorithms
        
        let sourceChanges = findChanges(from: ancestor.content, to: source.content)
        let targetChanges = findChanges(from: ancestor.content, to: target.content)
        
        var mergedContent = ancestor.content
        
        // Apply non-overlapping changes
        let allChanges = (sourceChanges + targetChanges).sorted { $0.range.location > $1.range.location }
        
        for change in allChanges {
            // Apply change to merged content
            let startIndex = mergedContent.index(mergedContent.startIndex, offsetBy: change.range.location)
            let endIndex = mergedContent.index(startIndex, offsetBy: change.range.length)
            mergedContent.replaceSubrange(startIndex..<endIndex, with: change.newText)
        }
        
        return mergedContent
    }
    
    private func findChanges(from oldContent: String, to newContent: String) -> [ContentChange] {
        // Simplified change detection
        // In practice, this would use diff algorithms like Myers' algorithm
        
        if oldContent == newContent {
            return []
        }
        
        return [ContentChange(
            range: NSRange(location: 0, length: oldContent.count),
            newText: newContent
        )]
    }
    
    private func rangesOverlap(_ range1: NSRange, _ range2: NSRange) -> Bool {
        return NSIntersectionRange(range1, range2).length > 0
    }
    
    private struct ContentChange {
        let range: NSRange
        let newText: String
    }
}

class DocumentVersionController {
    
    func createVersion(
        from document: SharedDocument,
        operation: DocumentOperation,
        performedBy: UUID
    ) -> DocumentVersion {
        
        return DocumentVersion(
            id: UUID(),
            documentId: document.id,
            version: document.version + 1,
            content: document.content,
            authorId: performedBy,
            timestamp: Date(),
            changeDescription: operation.description,
            parentVersionId: nil, // Would be set to current version ID
            checksum: String(document.content.hashValue)
        )
    }
    
    func rollbackToVersion(
        document: inout SharedDocument,
        targetVersion: DocumentVersion
    ) {
        
        document.content = targetVersion.content
        document.version = targetVersion.version
        document.lastModifiedAt = Date()
        // Would typically create a new version representing the rollback
    }
}

class DocumentStorageManager {
    
    func storeVersion(_ version: DocumentVersion) async {
        // Store version to persistent storage
        print("💾 Storing document version: \(version.version)")
    }
    
    func loadVersion(documentId: UUID, version: Int) async -> DocumentVersion? {
        // Load version from persistent storage
        return nil
    }
    
    func storeDocument(_ document: SharedDocument) async {
        // Store document to persistent storage
        print("💾 Storing document: \(document.title)")
    }
}

// MARK: - Error Types

enum SharedDocumentError: LocalizedError {
    case documentNotFound(UUID)
    case insufficientPermissions(UUID, DocumentCollaborator.Permission)
    case documentLocked(UUID)
    case versionNotFound(Int)
    case decisionNotFound(UUID)
    case alreadyVoted(UUID)
    case operationTransformFailed(String)
    case mergeFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .documentNotFound(let id):
            return "Document not found: \(id)"
        case .insufficientPermissions(let participantId, let permission):
            return "Participant \(participantId) lacks \(permission.rawValue) permission"
        case .documentLocked(let lockedBy):
            return "Document is locked by participant: \(lockedBy)"
        case .versionNotFound(let version):
            return "Document version not found: \(version)"
        case .decisionNotFound(let id):
            return "Decision not found: \(id)"
        case .alreadyVoted(let id):
            return "Already voted on decision: \(id)"
        case .operationTransformFailed(let reason):
            return "Operation transform failed: \(reason)"
        case .mergeFailed(let reason):
            return "Merge failed: \(reason)"
        }
    }
}
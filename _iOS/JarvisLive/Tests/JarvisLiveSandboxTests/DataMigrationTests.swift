/*
* Purpose: Data migration safety tests for Core Data conversation persistence and schema evolution
* Issues & Complexity Summary: Critical data integrity validation for conversation, message, and memory migration
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~300
  - Core Algorithm Complexity: High (data migration scenarios, schema validation)
  - Dependencies: 3 New (Core Data, XCTest, MockData)
  - State Management Complexity: High (multi-entity relationships, migration paths)
  - Novelty/Uncertainty Factor: Medium (Core Data migration edge cases)
* AI Pre-Task Self-Assessment: 75%
* Problem Estimate: 80%
* Initial Code Complexity Estimate: 85%
* Final Code Complexity: 87%
* Overall Result Score: 90%
* Key Variances/Learnings: Core Data relationship integrity requires careful cascade testing
* Last Updated: 2025-06-29
*/

import XCTest
import CoreData
@testable import JarvisLive_Sandbox

final class DataMigrationTests: XCTestCase {
    var persistentContainer: NSPersistentContainer!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        setupInMemoryCoreDataStack()
    }
    
    override func tearDown() {
        context = nil
        persistentContainer = nil
        super.tearDown()
    }
    
    // MARK: - Core Data Stack Setup
    
    private func setupInMemoryCoreDataStack() {
        guard let modelURL = Bundle(for: DataMigrationTests.self)
            .url(forResource: "ConversationDataModel", withExtension: "momd") else {
            XCTFail("Failed to find Core Data model")
            return
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            XCTFail("Failed to create managed object model")
            return
        }
        
        persistentContainer = NSPersistentContainer(name: "ConversationDataModel", managedObjectModel: managedObjectModel)
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                XCTFail("Failed to load store: \(error)")
            }
        }
        
        context = persistentContainer.viewContext
    }
    
    // MARK: - Conversation Entity Migration Tests
    
    func testConversationEntityCreationAndRetrieval() {
        // Test conversation creation with all required fields
        let conversation = NSEntityDescription.insertNewObject(forEntityName: "Conversation", into: context)
        let conversationId = UUID()
        let now = Date()
        
        conversation.setValue(conversationId, forKey: "id")
        conversation.setValue("Test Conversation", forKey: "title")
        conversation.setValue(now, forKey: "createdAt")
        conversation.setValue(now, forKey: "updatedAt")
        conversation.setValue(now, forKey: "lastActiveAt")
        conversation.setValue(false, forKey: "isArchived")
        conversation.setValue(0, forKey: "totalMessages")
        conversation.setValue(0.0, forKey: "contextWeight")
        
        XCTAssertNoThrow(try context.save())
        
        // Test retrieval
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Conversation")
        fetchRequest.predicate = NSPredicate(format: "id == %@", conversationId as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            XCTAssertEqual(results.count, 1)
            
            let retrievedConversation = results.first!
            XCTAssertEqual(retrievedConversation.value(forKey: "id") as? UUID, conversationId)
            XCTAssertEqual(retrievedConversation.value(forKey: "title") as? String, "Test Conversation")
            XCTAssertEqual(retrievedConversation.value(forKey: "isArchived") as? Bool, false)
            XCTAssertEqual(retrievedConversation.value(forKey: "totalMessages") as? Int32, 0)
        } catch {
            XCTFail("Failed to fetch conversation: \(error)")
        }
    }
    
    func testConversationMessageRelationship() {
        // Create conversation
        let conversation = NSEntityDescription.insertNewObject(forEntityName: "Conversation", into: context)
        let conversationId = UUID()
        let now = Date()
        
        conversation.setValue(conversationId, forKey: "id")
        conversation.setValue("Test Conversation", forKey: "title")
        conversation.setValue(now, forKey: "createdAt")
        conversation.setValue(now, forKey: "updatedAt")
        conversation.setValue(now, forKey: "lastActiveAt")
        conversation.setValue(false, forKey: "isArchived")
        conversation.setValue(1, forKey: "totalMessages")
        conversation.setValue(0.0, forKey: "contextWeight")
        
        // Create message
        let message = NSEntityDescription.insertNewObject(forEntityName: "ConversationMessage", into: context)
        let messageId = UUID()
        
        message.setValue(messageId, forKey: "id")
        message.setValue("Test message content", forKey: "content")
        message.setValue("user", forKey: "role")
        message.setValue(now, forKey: "timestamp")
        message.setValue(0.0, forKey: "processingTime")
        message.setValue("claude-3-5-sonnet", forKey: "aiProvider")
        message.setValue("document_generation", forKey: "voiceCommandCategory")
        message.setValue("positive", forKey: "sentiment")
        message.setValue(conversation, forKey: "conversation")
        
        XCTAssertNoThrow(try context.save())
        
        // Test relationship integrity
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Conversation")
        fetchRequest.predicate = NSPredicate(format: "id == %@", conversationId as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            let retrievedConversation = results.first!
            let messages = retrievedConversation.value(forKey: "messages") as? Set<NSManagedObject>
            
            XCTAssertEqual(messages?.count, 1)
            let retrievedMessage = messages?.first!
            XCTAssertEqual(retrievedMessage?.value(forKey: "id") as? UUID, messageId)
            XCTAssertEqual(retrievedMessage?.value(forKey: "content") as? String, "Test message content")
            XCTAssertEqual(retrievedMessage?.value(forKey: "role") as? String, "user")
            XCTAssertEqual(retrievedMessage?.value(forKey: "aiProvider") as? String, "claude-3-5-sonnet")
        } catch {
            XCTFail("Failed to validate conversation-message relationship: \(error)")
        }
    }
    
    // MARK: - Message Entity Migration Tests
    
    func testConversationMessageEntityCompleteFields() {
        let message = NSEntityDescription.insertNewObject(forEntityName: "ConversationMessage", into: context)
        let messageId = UUID()
        let timestamp = Date()
        
        // Test all ConversationMessage fields
        message.setValue(messageId, forKey: "id")
        message.setValue("Complete test message with all fields", forKey: "content")
        message.setValue("assistant", forKey: "role")
        message.setValue(timestamp, forKey: "timestamp")
        message.setValue(0.15, forKey: "processingTime")
        message.setValue("gpt-4o", forKey: "aiProvider")
        message.setValue("email_management", forKey: "voiceCommandCategory")
        message.setValue("neutral", forKey: "sentiment")
        message.setValue("Voice transcription: Create email to team", forKey: "audioTranscription")
        message.setValue("[0.1, 0.2, 0.3, 0.4, 0.5]", forKey: "contextEmbedding")
        
        XCTAssertNoThrow(try context.save())
        
        // Verify all fields persisted correctly
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ConversationMessage")
        fetchRequest.predicate = NSPredicate(format: "id == %@", messageId as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            XCTAssertEqual(results.count, 1)
            
            let retrievedMessage = results.first!
            XCTAssertEqual(retrievedMessage.value(forKey: "id") as? UUID, messageId)
            XCTAssertEqual(retrievedMessage.value(forKey: "content") as? String, "Complete test message with all fields")
            XCTAssertEqual(retrievedMessage.value(forKey: "role") as? String, "assistant")
            XCTAssertEqual(retrievedMessage.value(forKey: "processingTime") as? Double, 0.15)
            XCTAssertEqual(retrievedMessage.value(forKey: "aiProvider") as? String, "gpt-4o")
            XCTAssertEqual(retrievedMessage.value(forKey: "voiceCommandCategory") as? String, "email_management")
            XCTAssertEqual(retrievedMessage.value(forKey: "sentiment") as? String, "neutral")
            XCTAssertEqual(retrievedMessage.value(forKey: "audioTranscription") as? String, "Voice transcription: Create email to team")
            XCTAssertEqual(retrievedMessage.value(forKey: "contextEmbedding") as? String, "[0.1, 0.2, 0.3, 0.4, 0.5]")
        } catch {
            XCTFail("Failed to validate complete message fields: \(error)")
        }
    }
    
    // MARK: - Memory Entity Migration Tests
    
    func testConversationMemoryEntityCreation() {
        let memory = NSEntityDescription.insertNewObject(forEntityName: "ConversationMemory", into: context)
        let memoryId = UUID()
        let now = Date()
        
        memory.setValue(memoryId, forKey: "id")
        memory.setValue("User prefers PDF documents for quarterly reports", forKey: "summary")
        memory.setValue("preference", forKey: "memoryType")
        memory.setValue(0.85, forKey: "confidence")
        memory.setValue(0.75, forKey: "relevanceScore")
        memory.setValue(now, forKey: "createdAt")
        memory.setValue(now, forKey: "updatedAt")
        memory.setValue("quarterly, reports, PDF, documents", forKey: "keywords")
        memory.setValue("document_generation_context", forKey: "context")
        memory.setValue("[0.2, 0.4, 0.6, 0.8, 0.9]", forKey: "embedding")
        
        XCTAssertNoThrow(try context.save())
        
        // Verify memory entity creation
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ConversationMemory")
        fetchRequest.predicate = NSPredicate(format: "id == %@", memoryId as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            XCTAssertEqual(results.count, 1)
            
            let retrievedMemory = results.first!
            XCTAssertEqual(retrievedMemory.value(forKey: "memoryType") as? String, "preference")
            XCTAssertEqual(retrievedMemory.value(forKey: "confidence") as? Double, 0.85)
            XCTAssertEqual(retrievedMemory.value(forKey: "relevanceScore") as? Double, 0.75)
            XCTAssertEqual(retrievedMemory.value(forKey: "keywords") as? String, "quarterly, reports, PDF, documents")
        } catch {
            XCTFail("Failed to validate memory entity: \(error)")
        }
    }
    
    // MARK: - Cascade Deletion Tests
    
    func testConversationDeletionCascadesMessages() {
        // Create conversation with messages
        let conversation = createTestConversation()
        let message1 = createTestMessage(forConversation: conversation, content: "First message")
        let message2 = createTestMessage(forConversation: conversation, content: "Second message")
        
        XCTAssertNoThrow(try context.save())
        
        // Verify messages exist
        let messageFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ConversationMessage")
        var messageResults = try! context.fetch(messageFetchRequest)
        XCTAssertEqual(messageResults.count, 2)
        
        // Delete conversation
        context.delete(conversation)
        XCTAssertNoThrow(try context.save())
        
        // Verify messages were cascaded
        messageResults = try! context.fetch(messageFetchRequest)
        XCTAssertEqual(messageResults.count, 0, "Messages should be cascade deleted with conversation")
    }
    
    func testConversationDeletionCascadesMemories() {
        // Create conversation with memories
        let conversation = createTestConversation()
        let memory = createTestMemory(forConversation: conversation)
        
        XCTAssertNoThrow(try context.save())
        
        // Verify memory exists
        let memoryFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ConversationMemory")
        var memoryResults = try! context.fetch(memoryFetchRequest)
        XCTAssertEqual(memoryResults.count, 1)
        
        // Delete conversation
        context.delete(conversation)
        XCTAssertNoThrow(try context.save())
        
        // Verify memory was cascaded
        memoryResults = try! context.fetch(memoryFetchRequest)
        XCTAssertEqual(memoryResults.count, 0, "Memories should be cascade deleted with conversation")
    }
    
    // MARK: - Data Integrity Tests
    
    func testUUIDUniquenessAcrossEntities() {
        let uuid = UUID()
        
        // Create entities with same UUID
        let conversation = createTestConversation(id: uuid)
        let message = createTestMessage(forConversation: conversation, id: uuid)
        
        XCTAssertNoThrow(try context.save())
        
        // Verify both entities can coexist with same UUID (different entity types)
        let conversationFetch = NSFetchRequest<NSManagedObject>(entityName: "Conversation")
        conversationFetch.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        
        let messageFetch = NSFetchRequest<NSManagedObject>(entityName: "ConversationMessage")
        messageFetch.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        
        do {
            let conversationResults = try context.fetch(conversationFetch)
            let messageResults = try context.fetch(messageFetch)
            
            XCTAssertEqual(conversationResults.count, 1)
            XCTAssertEqual(messageResults.count, 1)
        } catch {
            XCTFail("Failed UUID uniqueness test: \(error)")
        }
    }
    
    func testDateFieldConsistency() {
        let baseDate = Date()
        let conversation = createTestConversation()
        
        conversation.setValue(baseDate, forKey: "createdAt")
        conversation.setValue(baseDate.addingTimeInterval(3600), forKey: "updatedAt")
        conversation.setValue(baseDate.addingTimeInterval(7200), forKey: "lastActiveAt")
        
        XCTAssertNoThrow(try context.save())
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Conversation")
        do {
            let results = try context.fetch(fetchRequest)
            let retrievedConversation = results.first!
            
            let createdAt = retrievedConversation.value(forKey: "createdAt") as! Date
            let updatedAt = retrievedConversation.value(forKey: "updatedAt") as! Date
            let lastActiveAt = retrievedConversation.value(forKey: "lastActiveAt") as! Date
            
            XCTAssertTrue(createdAt <= updatedAt, "CreatedAt should be <= updatedAt")
            XCTAssertTrue(updatedAt <= lastActiveAt, "UpdatedAt should be <= lastActiveAt")
        } catch {
            XCTFail("Failed date consistency test: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestConversation(id: UUID = UUID()) -> NSManagedObject {
        let conversation = NSEntityDescription.insertNewObject(forEntityName: "Conversation", into: context)
        let now = Date()
        
        conversation.setValue(id, forKey: "id")
        conversation.setValue("Test Conversation", forKey: "title")
        conversation.setValue(now, forKey: "createdAt")
        conversation.setValue(now, forKey: "updatedAt")
        conversation.setValue(now, forKey: "lastActiveAt")
        conversation.setValue(false, forKey: "isArchived")
        conversation.setValue(0, forKey: "totalMessages")
        conversation.setValue(0.0, forKey: "contextWeight")
        
        return conversation
    }
    
    private func createTestMessage(forConversation conversation: NSManagedObject, content: String = "Test message", id: UUID = UUID()) -> NSManagedObject {
        let message = NSEntityDescription.insertNewObject(forEntityName: "ConversationMessage", into: context)
        
        message.setValue(id, forKey: "id")
        message.setValue(content, forKey: "content")
        message.setValue("user", forKey: "role")
        message.setValue(Date(), forKey: "timestamp")
        message.setValue(0.0, forKey: "processingTime")
        message.setValue(conversation, forKey: "conversation")
        
        return message
    }
    
    private func createTestMemory(forConversation conversation: NSManagedObject, id: UUID = UUID()) -> NSManagedObject {
        let memory = NSEntityDescription.insertNewObject(forEntityName: "ConversationMemory", into: context)
        let now = Date()
        
        memory.setValue(id, forKey: "id")
        memory.setValue("Test memory summary", forKey: "summary")
        memory.setValue("preference", forKey: "memoryType")
        memory.setValue(0.8, forKey: "confidence")
        memory.setValue(0.7, forKey: "relevanceScore")
        memory.setValue(now, forKey: "createdAt")
        memory.setValue(now, forKey: "updatedAt")
        memory.setValue(conversation, forKey: "conversation")
        
        return memory
    }
}
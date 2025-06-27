//
//  VoiceClassificationManagerTests.swift
//  JarvisLiveSandboxTests
//
//  Created by Cursor on 2025-06-27.
//

import XCTest
@testable import JarvisLiveSandbox

// MARK: - Mock Network Layer
protocol NetworkSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSession {}

struct MockNetworkSession: NetworkSession {
    var data: Data?
    var response: URLResponse?
    var error: Error?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }
        guard let data = data, let response = response else {
            throw URLError(.badServerResponse)
        }
        return (data, response)
    }
}

final class VoiceClassificationManagerTests: XCTestCase {
    var manager: VoiceClassificationManager!
    var mockSession: MockNetworkSession!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockSession = MockNetworkSession()
        manager = VoiceClassificationManager(session: mockSession)
    }

    override func tearDownWithError() throws {
        manager = nil
        mockSession = nil
        try super.tearDownWithError()
    }

    func testInitialization() {
        XCTAssertNotNil(manager, "The VoiceClassificationManager should not be nil after initialization.")
    }

    func testClassifyVoiceCommand_Success() async throws {
        // 1. Prepare mock data and response
        let responseJSON = """
        {
            "category": "document_generation",
            "intent": "document_generation_intent",
            "confidence": 0.85,
            "parameters": {
                "content_topic": "machine learning",
                "format": "pdf"
            },
            "suggestions": [],
            "raw_text": "create a document about machine learning",
            "normalized_text": "create document about machine learning",
            "confidence_level": "high",
            "context_used": true,
            "preprocessing_time": 0.002,
            "classification_time": 0.015,
            "requires_confirmation": false
        }
        """
        let responseData = responseJSON.data(using: .utf8)
        let httpResponse = HTTPURLResponse(url: URL(string: "http://localhost:8000/voice/classify")!, statusCode: 200, httpVersion: nil, headerFields: nil)

        mockSession.data = responseData
        mockSession.response = httpResponse

        // 2. Perform the classification
        let expectation = XCTestExpectation(description: "Classification finishes")

        Task {
            let result = try await manager.classifyVoiceCommand("test", userId: "testUser", sessionId: "testSession")

            // 3. Assertions
            XCTAssertEqual(result.category, "document_generation")
            XCTAssertEqual(result.confidence, 0.85)
            XCTAssertEqual(result.rawText, "create a document about machine learning")
            XCTAssertEqual(manager.isProcessing, false)
            XCTAssertNotNil(manager.lastClassification)
            XCTAssertEqual(manager.lastClassification?.intent, "document_generation_intent")

            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testClassifyVoiceCommand_Failure_BadResponse() async {
        // 1. Prepare mock response
        let httpResponse = HTTPURLResponse(url: URL(string: "http://localhost:8000/voice/classify")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        mockSession.data = Data() // Empty data
        mockSession.response = httpResponse

        // 2. Perform the classification and expect an error
        do {
            _ = try await manager.classifyVoiceCommand("test", userId: "testUser", sessionId: "testSession")
            XCTFail("Should have thrown an error for bad server response")
        } catch {
            // 3. Assertions
            XCTAssertEqual((error as? URLError)?.code, .badServerResponse)
            XCTAssertEqual(manager.isProcessing, false)
        }
    }

    func testClassifyVoiceCommand_Failure_NetworkError() async {
        // 1. Prepare mock error
        mockSession.error = URLError(.notConnectedToInternet)

        // 2. Perform the classification and expect an error
        do {
            _ = try await manager.classifyVoiceCommand("test", userId: "testUser", sessionId: "testSession")
            XCTFail("Should have thrown a network error")
        } catch {
            // 3. Assertions
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
            XCTAssertEqual(manager.isProcessing, false)
        }
    }
}

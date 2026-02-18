//
//  VoiceStreamSDKTests.swift
//  VoiceStreamSDKTests
//
//  Tests for VoiceStreamSDK
//

import XCTest
@testable import VoiceStreamSDK

final class VoiceStreamSDKTests: XCTestCase {

    func testConfigurationDefaults() {
        let config = VoiceStreamConfig(
            tenantId: "test-tenant",
            tenantName: "Test Tenant"
        )

        XCTAssertEqual(config.tenantId, "test-tenant")
        XCTAssertEqual(config.tenantName, "Test Tenant")
        XCTAssertEqual(config.serverUrl, "wss://streaming-poc.smartserve.ai/ws")
        XCTAssertEqual(config.audioInputSampleRate, 16000.0)
        XCTAssertEqual(config.audioOutputSampleRate, 24000.0)
        XCTAssertEqual(config.audioChannels, 1)
        XCTAssertEqual(config.audioBitDepth, 16)
        XCTAssertEqual(config.autoReconnect, true)
        XCTAssertEqual(config.maxReconnectAttempts, 5)
    }

    func testConnectionStateDescription() {
        XCTAssertEqual(ConnectionState.disconnected.description, "Disconnected")
        XCTAssertEqual(ConnectionState.connecting.description, "Connecting")
        XCTAssertEqual(ConnectionState.connected.description, "Connected")
        XCTAssertEqual(ConnectionState.reconnecting.description, "Reconnecting")
    }

    func testErrorDescriptions() {
        let connectionError = VoiceStreamError.connectionFailed("Test error")
        XCTAssertTrue(connectionError.localizedDescription.contains("Connection failed"))

        let authError = VoiceStreamError.authenticationFailed("Auth error")
        XCTAssertTrue(authError.localizedDescription.contains("Authentication failed"))

        let audioError = VoiceStreamError.audioCaptureFailed("Capture error")
        XCTAssertTrue(audioError.localizedDescription.contains("Audio capture failed"))
    }

    func testSDKInitialization() {
        let config = VoiceStreamConfig(
            tenantId: "test",
            tenantName: "Test"
        )

        let sdk = VoiceStreamSDK.initialize(config: config)
        XCTAssertNotNil(sdk)

        // Get instance
        do {
            let instance = try VoiceStreamSDK.getInstance()
            XCTAssertNotNil(instance)
        } catch {
            XCTFail("Should be able to get instance after initialization")
        }

        // Reset for other tests
        VoiceStreamSDK.reset()
    }

    func testSDKNotInitializedError() {
        VoiceStreamSDK.reset()

        do {
            _ = try VoiceStreamSDK.getInstance()
            XCTFail("Should throw error when not initialized")
        } catch {
            XCTAssertTrue(error is VoiceStreamError)
        }
    }
}

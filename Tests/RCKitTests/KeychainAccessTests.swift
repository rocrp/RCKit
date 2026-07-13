import Foundation
import Security
import Testing

import RCKit

@Suite("KeychainAccess")
struct KeychainAccessTests {
    private struct TestUser: Codable, Equatable {
        let id: String
        let name: String
        let isActive: Bool
    }

    private let service = "com.rocry.KeychainAccessTests"

    @Test func stringRoundTripCanBeUpdatedAndDeleted() throws {
        let (keychain, _) = makeKeychain()

        #expect(!keychain.exists(for: "string"))
        try keychain.set("Hello, Keychain!", for: "string").get()
        #expect(keychain.exists(for: "string"))
        #expect(try keychain.getString(for: "string").get() == "Hello, Keychain!")

        try keychain.set("Updated String", for: "string").get()
        #expect(try keychain.getString(for: "string").get() == "Updated String")

        try keychain.delete(for: "string").get()
        #expect(!keychain.exists(for: "string"))
    }

    @Test func booleanRoundTripCanBeUpdated() throws {
        let (keychain, _) = makeKeychain()

        try keychain.set(true, for: "bool").get()
        #expect(try keychain.getBool(for: "bool").get())

        try keychain.set(false, for: "bool").get()
        #expect(try !keychain.getBool(for: "bool").get())
    }

    @Test func dataRoundTrips() throws {
        let (keychain, _) = makeKeychain()
        let data = Data("Test Data".utf8)

        try keychain.set(data, for: "data").get()

        #expect(try keychain.getData(for: "data").get() == data)
    }

    @Test func codableRoundTrips() throws {
        let (keychain, _) = makeKeychain()
        let user = TestUser(id: "123", name: "Test User", isActive: true)

        try keychain.set(user, for: "object").get()

        #expect(try keychain.getCodable(for: "object", as: TestUser.self).get() == user)
    }

    @Test func missingItemReturnsNotFound() {
        let (keychain, _) = makeKeychain()

        #expect(keychain.getData(for: "missing") == .failure(.itemNotFound))
    }

    @Test func inMemoryBackendReturnsNotFoundThenDuplicateStatuses() {
        let (_, backend) = makeKeychain()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "duplicate",
        ]
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: Data("updated".utf8)
        ]
        var attributes = query
        attributes[kSecValueData as String] = Data("first".utf8)

        #expect(backend.update(query, attributes: attributesToUpdate) == errSecItemNotFound)
        #expect(backend.add(attributes) == errSecSuccess)
        #expect(backend.add(attributes) == errSecDuplicateItem)
    }

    private func makeKeychain() -> (KeychainAccess, InMemoryKeychainBackend) {
        let backend = InMemoryKeychainBackend()
        return (KeychainAccess(service: service, backend: backend), backend)
    }
}

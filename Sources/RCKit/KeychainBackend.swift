import Foundation
import Security
import Synchronization

/// Performs keychain item operations for ``KeychainAccess``.
public protocol KeychainBackend: AnyObject {
    func add(_ attributes: [String: Any]) -> OSStatus

    func update(_ query: [String: Any], attributes: [String: Any]) -> OSStatus

    func copyMatching(_ query: [String: Any]) -> (status: OSStatus, item: Any?)

    func delete(_ query: [String: Any]) -> OSStatus
}

/// Maps ``KeychainBackend`` operations directly to the Security framework.
public final class SecItemKeychainBackend: KeychainBackend {
    public init() {}

    public func add(_ attributes: [String: Any]) -> OSStatus {
        SecItemAdd(attributes as CFDictionary, nil)
    }

    public func update(_ query: [String: Any], attributes: [String: Any]) -> OSStatus {
        SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    }

    public func copyMatching(_ query: [String: Any]) -> (status: OSStatus, item: Any?) {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        return (status, item)
    }

    public func delete(_ query: [String: Any]) -> OSStatus {
        SecItemDelete(query as CFDictionary)
    }
}

/// An isolated in-memory keychain implementation for deterministic tests.
public final class InMemoryKeychainBackend: KeychainBackend {
    private struct ItemIdentifier: Hashable {
        let itemClass: String
        let service: String
        let account: String
        let accessGroup: String?

        init?(query: [String: Any]) {
            guard
                let itemClass = query[kSecClass as String] as? String,
                let service = query[kSecAttrService as String] as? String,
                let account = query[kSecAttrAccount as String] as? String
            else {
                return nil
            }

            self.itemClass = itemClass
            self.service = service
            self.account = account
            self.accessGroup = query[kSecAttrAccessGroup as String] as? String
        }
    }

    private let items = Mutex<[ItemIdentifier: Data]>([:])

    public init() {}

    public func add(_ attributes: [String: Any]) -> OSStatus {
        guard
            let identifier = ItemIdentifier(query: attributes),
            let data = attributes[kSecValueData as String] as? Data
        else {
            return errSecParam
        }

        return items.withLock { items in
            guard items[identifier] == nil else {
                return errSecDuplicateItem
            }

            items[identifier] = data
            return errSecSuccess
        }
    }

    public func update(_ query: [String: Any], attributes: [String: Any]) -> OSStatus {
        guard
            let identifier = ItemIdentifier(query: query),
            let data = attributes[kSecValueData as String] as? Data
        else {
            return errSecParam
        }

        return items.withLock { items in
            guard items[identifier] != nil else {
                return errSecItemNotFound
            }

            items[identifier] = data
            return errSecSuccess
        }
    }

    public func copyMatching(_ query: [String: Any]) -> (status: OSStatus, item: Any?) {
        guard let identifier = ItemIdentifier(query: query) else {
            return (errSecParam, nil)
        }

        return items.withLock { items in
            guard let data = items[identifier] else {
                return (errSecItemNotFound, nil)
            }

            let returnsData = query[kSecReturnData as String] as? Bool == true
            return (errSecSuccess, returnsData ? data : nil)
        }
    }

    public func delete(_ query: [String: Any]) -> OSStatus {
        guard let identifier = ItemIdentifier(query: query) else {
            return errSecParam
        }

        return items.withLock { items in
            guard items.removeValue(forKey: identifier) != nil else {
                return errSecItemNotFound
            }

            return errSecSuccess
        }
    }
}

//
//  String+Crypto.swift
//
//  Created by RoCry on 2024/2/8.
//

import CommonCrypto
import Foundation

// MARK: - String Crypto Extensions
extension String {
    /// Generate SHA-256 hash of the string (recommended for most use cases)
    public var sha256: String {
        Data(utf8).digest(using: .sha256)
    }

    /// Generate SHA-512 hash of the string (maximum security)
    public var sha512: String {
        Data(utf8).digest(using: .sha512)
    }

    /// Base64 encode the string
    public var base64Encoded: String {
        Data(utf8).base64EncodedString()
    }

    /// Base64 decode the string
    public var base64Decoded: String {
        guard let data = Data(base64Encoded: self) else {
            preconditionFailure("Invalid Base64 string: \(self)")
        }
        guard let decoded = String(data: data, encoding: .utf8) else {
            preconditionFailure("Invalid UTF-8 after Base64 decode: \(self)")
        }
        return decoded
    }
}

// MARK: - Data Hashing
extension Data {
    /// Available hash algorithms
    public enum HashAlgorithm {
        case sha256
        case sha512

        var digestLength: Int {
            switch self {
            case .sha256: return Int(CC_SHA256_DIGEST_LENGTH)
            case .sha512: return Int(CC_SHA512_DIGEST_LENGTH)
            }
        }
    }

    /// Generate hash digest using specified algorithm
    public func digest(using algorithm: HashAlgorithm) -> String {
        let digestLength = algorithm.digestLength
        var hashValue = [UInt8](repeating: 0, count: digestLength)

        switch algorithm {
        case .sha256:
            _ = self.withUnsafeBytes { bytes in
                CC_SHA256(bytes.baseAddress, CC_LONG(self.count), &hashValue)
            }
        case .sha512:
            _ = self.withUnsafeBytes { bytes in
                CC_SHA512(bytes.baseAddress, CC_LONG(self.count), &hashValue)
            }
        }

        return hashValue.map { String(format: "%02x", $0) }.joined()
    }
}

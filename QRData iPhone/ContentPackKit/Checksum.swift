//
//  Checksum.swift
//  QRData iPhone
//
//  Created by Kaushik Manian on 15/9/25.
//



import Foundation
import CryptoKit

public enum Checksum {
    public static func sha256Hex(of url: URL) throws -> String {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

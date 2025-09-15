//
//  ContentPackKit.swift
//  QRData iPhone
//
//  Created by Kaushik Manian on 15/9/25.
//

import Foundation

public struct PackManifest: Codable {
    public let version: Int
    public let assets: [Asset]

    public struct Asset: Codable {
        public let key: String
        public let filename: String
        public let sha256: String
        public init(key: String, filename: String, sha256: String) {
            self.key = key
            self.filename = filename
            self.sha256 = sha256
        }
    }

    public init(version: Int, assets: [Asset]) {
        self.version = version
        self.assets = assets
    }
}

public enum PackErrors: Error {
    case checksumMismatch(path: String)
    case assetNotFound(key: String)
}

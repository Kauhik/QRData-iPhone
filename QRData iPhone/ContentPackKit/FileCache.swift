//
//  FileCache.swift
//  QRData iPhone
//
//  Created by Kaushik Manian on 15/9/25.
//

import Foundation

public final class FileCache {
    private let base: URL
    public init(folderName: String) throws {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        base = support.appendingPathComponent(folderName, isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    }

    public func url(for filename: String) -> URL { base.appendingPathComponent(filename) }

    public func write(_ data: Data, filename: String) throws {
        try data.write(to: url(for: filename), options: .atomic)
    }

    public func removeAll() throws {
        if FileManager.default.fileExists(atPath: base.path) {
            try FileManager.default.removeItem(at: base)
        }
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    }
}

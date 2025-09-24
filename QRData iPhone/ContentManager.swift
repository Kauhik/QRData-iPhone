//
//  ContentManager.swift
//  QRData iPhone
//
//  Created by Kaushik Manian on 15/9/25.
//

import Foundation
import CloudKit

final class ContentManager {
    private let container: CKContainer
    private var publicDB: CKDatabase { container.publicCloudDatabase }
    private let cache: FileCache
    private let defaultsKey = "LockerQYes_ContentVersion"
    private let defaultsURLsKey = "LockerQYes_CustomURLs"

    private(set) var currentVersion: Int {
        get { UserDefaults.standard.integer(forKey: defaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: defaultsKey) }
    }

    // Latest custom URLs from the fetched ContentPack (0...5)
    private(set) var latestCustomURLs: [URL] = []

    init(containerID: String) throws {
        self.container = CKContainer(identifier: containerID)
        self.cache = try FileCache(folderName: "LockerQYesAssets")
    }

    // Returns true when an update was applied
    @discardableResult
    func syncUsingBootstrap(recordName: String) async throws -> Bool {
        // 1) Get Bootstrap
        let bootstrapID = CKRecord.ID(recordName: recordName)
        let bootstrap = try await publicDB.record(for: bootstrapID)

        guard let latestRef = bootstrap["latestPack"] as? CKRecord.Reference,
              let cloudVersion = bootstrap["version"] as? Int else {
            throw NSError(domain: "Content", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid bootstrap record"])
        }

        // 2) Fetch ContentPack (always fetch to read customURLs; we may still skip asset downloads)
        let pack = try await publicDB.record(for: latestRef.recordID)

        // Read optional array of custom URLs from "customURLs" (JSON string),
        // with backward-compat for a single "customURL" string.
        var urlStrings: [String] = []
        if let jsonString = pack["customURLs"] as? String,
           let data = jsonString.data(using: .utf8),
           let arr = try? JSONDecoder().decode([String].self, from: data) {
            urlStrings = arr
        } else if let single = pack["customURL"] as? String { // backward compatibility
            urlStrings = [single]
        }

        latestCustomURLs = urlStrings
            .compactMap { URL(string: $0) }
            .prefix(5)
            .map { $0 }

        // Persist to UserDefaults for display without re-sync
        UserDefaults.standard.set(latestCustomURLs.map { $0.absoluteString }, forKey: defaultsURLsKey)

        // If assets already up-to-date, skip downloads but keep latestCustomURLs updated
        if cloudVersion <= currentVersion {
            return false
        }

        guard let manifestAsset = pack["manifest"] as? CKAsset,
              let manifestURL = manifestAsset.fileURL,
              let data = try? Data(contentsOf: manifestURL),
              let manifest = try? JSONDecoder().decode(PackManifest.self, from: data),
              let cloudPackVersion = pack["version"] as? Int
        else { throw NSError(domain: "Content", code: 2, userInfo: [NSLocalizedDescriptionKey: "Malformed pack"]) }

        // 3) Download assets with checksum verification
        try await withThrowingTaskGroup(of: Void.self) { group in
            for item in manifest.assets {
                group.addTask {
                    guard let ckAsset = pack[item.key] as? CKAsset,
                          let tmpURL = ckAsset.fileURL else {
                        throw PackErrors.assetNotFound(key: item.key)
                    }
                    let hex = try Checksum.sha256Hex(of: tmpURL)
                    guard hex == item.sha256 else {
                        throw PackErrors.checksumMismatch(path: tmpURL.path)
                    }
                    let bytes = try Data(contentsOf: tmpURL, options: .mappedIfSafe)
                    try self.cache.write(bytes, filename: item.filename)
                }
            }
            try await group.waitForAll()
        }

        // 4) Atomically update version
        currentVersion = cloudPackVersion
        return true
    }

    // Convenience to read the last stored custom URLs without syncing
    static func storedCustomURLs() -> [URL] {
        guard let arr = UserDefaults.standard.array(forKey: "LockerQYes_CustomURLs") as? [String] else { return [] }
        return arr.compactMap { URL(string: $0) }.prefix(5).map { $0 }
    }
}

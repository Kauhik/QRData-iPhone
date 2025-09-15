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

    private(set) var currentVersion: Int {
        get { UserDefaults.standard.integer(forKey: defaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: defaultsKey) }
    }

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

        if cloudVersion <= currentVersion {
            return false
        }

        // 2) Fetch ContentPack
        let pack = try await publicDB.record(for: latestRef.recordID)
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
}

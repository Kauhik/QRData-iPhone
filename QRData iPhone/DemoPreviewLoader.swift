//
//  DemoPreviewLoader.swift
//  QRData iPhone
//
//  Created by Kaushik Manian on 15/9/25.
//

import Foundation
import UIKit

enum DemoPreviewLoader {
    // Returns the cache folder used by FileCache("LockerQYesAssets")
    static func cacheFolderURL() throws -> URL {
        let cache = try FileCache(folderName: "LockerQYesAssets")
        return cache.url(for: "")
    }

    static func loadCachedImages() throws -> [UIImage] {
        let folder = try cacheFolderURL()
        let urls = try FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
        )
        return urls.compactMap { url in
            guard url.pathExtension.lowercased() != "csv" else { return nil }
            return UIImage(contentsOfFile: url.path)
        }
    }

    // List CSV file URLs currently in cache
    static func loadCachedCSVURLs() throws -> [URL] {
        let folder = try cacheFolderURL()
        let urls = try FileManager.default.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
        )
        return urls.filter { $0.pathExtension.lowercased() == "csv" }
    }

    // Read CSV text with a safety cap
    static func readCSV(url: URL, maxBytes: Int = 1_000_000) throws -> String {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        let sliced = data.prefix(maxBytes)
        return String(decoding: sliced, as: UTF8.self)
    }
}

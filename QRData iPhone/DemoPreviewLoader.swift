//
//  DemoPreviewLoader.swift
//  QRData iPhone
//
//  Created by Kaushik Manian on 15/9/25.
//

import Foundation
import UIKit

enum DemoPreviewLoader {
    static func loadCachedImages() throws -> [UIImage] {
        let cache = try FileCache(folderName: "LockerQYesAssets")
        let folder = cache.url(for: "").deletingLastPathComponent().appendingPathComponent("LockerQYesAssets")
        let urls = try FileManager.default.contentsOfDirectory(at: folder,
                                                               includingPropertiesForKeys: nil,
                                                               options: [.skipsHiddenFiles])
        return urls.compactMap { UIImage(contentsOfFile: $0.path) }
    }
}

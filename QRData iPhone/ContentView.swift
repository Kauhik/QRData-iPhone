//
//  ContentView.swift
//  QRData iPhone
//
//  Created by Kaushik Manian on 15/9/25.
//

import SwiftUI
import CloudKit
import UniformTypeIdentifiers

struct ContentView: View {

    // IMPORTANT: set your CloudKit container ID here to default for manual fetch
    private let defaultContainerID = "iCloud.com.kaushikmanian.LockerQ"

    @State private var status: String = "Scan the QR or open via lockerqyes://"
    @State private var images: [UIImage] = []
    @State private var isScanning = true
    @State private var customURL: URL? = ContentManager.storedCustomURL()

    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if isScanning {
                    QRScannerView { code in
                        Task { await handleScannedString(code) }
                    }
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary))
                } else {
                    Text("Scanner paused").foregroundStyle(.secondary)
                }

                HStack {
                    Button(isScanning ? "Pause Scanner" : "Resume Scanner") {
                        isScanning.toggle()
                    }
                    Spacer()
                    Button("Clear Cache") {
                        do {
                            let cache = try FileCache(folderName: "LockerQYesAssets")
                            try cache.removeAll()
                            images = []
                            status = "Cache cleared."
                        } catch {
                            status = "Cache clear failed: \(error.localizedDescription)"
                        }
                    }
                }

                Text(status)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(images.enumerated()), id: \.offset) { _, img in
                            Image(uiImage: img).resizable().scaledToFit().frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal, 8)
                }

                if let link = customURL {
                    Button {
                        openURL(link)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "link")
                            Text(link.absoluteString)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("LockerQYes Client")
            .onReceive(NotificationCenter.default.publisher(for: .incomingBootstrapURL)) { note in
                guard let url = note.object as? URL else { return }
                Task { await handleBootstrapURL(url) }
            }
            .task {
                if let imgs = try? DemoPreviewLoader.loadCachedImages() {
                    images = imgs
                }
                if customURL == nil {
                    customURL = ContentManager.storedCustomURL()
                }
            }
        }
    }

    private func handleScannedString(_ str: String) async {
        if let url = URL(string: str), url.scheme?.lowercased() == "lockerqyes" {
            await handleBootstrapURL(url)
        } else {
            status = "Unrecognized QR payload."
        }
    }

    private func handleBootstrapURL(_ url: URL) async {
        do {
            guard url.host?.lowercased() == "bootstrap" || url.path.lowercased().contains("bootstrap") else {
                status = "Not a bootstrap URL."
                return
            }
            let params = url.lkq_queryItems
            guard let container = params["container"], let record = params["record"] else {
                status = "Missing container/record in URL."
                return
            }
            status = "Fetching bootstrap…"
            let mgr = try ContentManager(containerID: container)
            let changed = try await mgr.syncUsingBootstrap(recordName: record)
            status = changed ? "Updated to v\(mgr.currentVersion). Assets cached." :
                               "Already up to date (v\(mgr.currentVersion))."
            if let imgs = try? DemoPreviewLoader.loadCachedImages() { images = imgs }
            customURL = mgr.latestCustomURL ?? ContentManager.storedCustomURL()
        } catch {
            status = "Sync failed: \(error.localizedDescription)"
        }
    }
}

private extension URL {
    var lkq_queryItems: [String: String] {
        var dict: [String: String] = [:]
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?.forEach { dict[$0.name] = $0.value } ?? ()
        return dict
    }
}

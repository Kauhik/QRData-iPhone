//
//  QRData_iPhoneApp.swift
//  QRData iPhone
//
//  Created by Kaushik Manian on 15/9/25.
//

import SwiftUI

@main
struct QRData_iPhoneApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Handle lockerqyes://bootstrap?container=...&record=...
                .onOpenURL { url in
                    NotificationCenter.default.post(name: .incomingBootstrapURL, object: url)
                }
        }
    }
}

extension Notification.Name {
    static let incomingBootstrapURL = Notification.Name("incomingBootstrapURL")
}

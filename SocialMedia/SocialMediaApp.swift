//
//  SocialMediaApp.swift
//  SocialMedia
//
//  Created by Jose Garcia on 1/25/25.
//

import SwiftUI
import Firebase

@main
struct SocialMediaApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

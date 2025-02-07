//
//  ContentView.swift
//  SocialMedia
//
//  Created by Jose Garcia on 1/25/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("log_status") var logStatus: Bool = false
    var body: some View {
        // MARK: Redirecting User Based on Log Status
        if logStatus {
            MainView()
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
}

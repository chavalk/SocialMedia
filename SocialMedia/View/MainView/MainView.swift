//
//  MainView.swift
//  SocialMedia
//
//  Created by Jose Garcia on 2/6/25.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        // MARK: TabView With Recent Posts And Profile Tabs
        TabView {
            Text("Recent Posts")
                .tabItem {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled")
                    Text("Posts")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Profile")
                }
        }
        // Changing Tab Label Tint to Black
        .tint(.black)
    }
}

#Preview {
    MainView()
}

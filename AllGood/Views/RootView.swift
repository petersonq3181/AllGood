//
//  RootView.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/13/25.
//

import SwiftUI

struct RootView: View {
    @StateObject private var postViewModel = PostViewModel(postManager: PostManager(db: FirestoreManager.db))

    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    private let theme = ColorThemeA()
    
    var body: some View {
        Group {
            if let user = authViewModel.user {
                TabView {
                    MapView(postViewModel: postViewModel)
                        .environment(\.colorTheme, theme)
                        .environmentObject(authViewModel)
                        .tabItem {
                            Image(systemName: "map")
                            Text("Map")
                        }
                        .onAppear {
                            postViewModel.fetchAllPosts()
                        }
                    
                    ProfileView(postViewModel: postViewModel)
                        .environment(\.colorTheme, theme)
                        .environmentObject(authViewModel)
                        .tabItem {
                            Image(systemName: "person")
                            Text("Profile")
                        }
                }
                .tint(.white) // sets the selected tab color
            } else {
                ProgressView("Loading user..")
            }
        }
    }
}

#Preview {
    let authViewModel = AuthenticationViewModel()
    RootView()
        .environmentObject(authViewModel)
}

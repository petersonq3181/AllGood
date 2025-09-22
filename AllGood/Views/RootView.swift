//
//  RootView.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/13/25.
//

import SwiftUI

struct RootView: View {
    @StateObject private var postViewModel = PostViewModel(postManager: PostManager())
    @ObservedObject var authViewModel = AuthenticationViewModel()
    
    private let theme = ColorThemeA()
    
    var body: some View {
        Group {
            if let user = authViewModel.user {
                TabView {
                    MapView(authViewModel: authViewModel, postViewModel: postViewModel)
                        .environment(\.colorTheme, theme)
                        .tabItem {
                            Image(systemName: "map")
                            Text("Map")
                        }
                        .onAppear {
                            postViewModel.fetchAllPosts()
                        }
                    
                    ProfileView(authViewModel: authViewModel, postViewModel: postViewModel)
                        .environment(\.colorTheme, theme)
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
    var authViewModel = AuthenticationViewModel()
    RootView(authViewModel: authViewModel)
}

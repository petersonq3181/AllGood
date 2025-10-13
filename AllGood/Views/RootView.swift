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
    
    @State private var isSpinning = false
    
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
                            Task {
                                await postViewModel.fetchAllPosts()
                            }
                        }
                    
                    ProfileView(postViewModel: postViewModel)
                        .environment(\.colorTheme, theme)
                        .environmentObject(authViewModel)
                        .tabItem {
                            Image("CustomIcon\(user.avatarNumber)Tab")
                                .renderingMode(.original)
                            Text("Profile")
                        }
                }
                .tint(.white) // sets the selected tab color
            } else {
                VStack(spacing: 16) {
                    Image("CustomIcon4")
                        .rotationEffect(.degrees(isSpinning ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 2)
                                .repeatForever(autoreverses: false),
                            value: isSpinning
                        )
                    Text("Loading…")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .onAppear {
                    isSpinning = true
                }
            }
        }
    }
}

#Preview {
    let authViewModel = AuthenticationViewModel()
    RootView()
        .environmentObject(authViewModel)
}

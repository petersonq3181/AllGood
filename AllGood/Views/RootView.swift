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
    
    var body: some View {
        Group {
            if let user = authViewModel.user {
                TabView {
                    MapView()
                        .tabItem {
                            Image(systemName: "map")
                            Text("Map")
                        }
                    
                    ProfileView(authViewModel: authViewModel, postViewModel: postViewModel)
                        .tabItem {
                            Image(systemName: "person")
                            Text("Profile")
                        }
                }
            } else {
                ProgressView("Loading user...")
            }
        }
    }
}

#Preview {
    var authViewModel = AuthenticationViewModel()
    RootView(authViewModel: authViewModel)
}

//
//  ProfileView.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/13/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthenticationViewModel
    @StateObject private var postViewModel = PostViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // User ID
                if let user = authViewModel.user {
                    Text("User ID: \(user.uid)")
                        .font(.headline)
                        .padding(.top, 20)
                    
                    // Posts Section
                    VStack(spacing: 15) {
                        if postViewModel.isLoading {
                            Text("Loading posts...")
                                .foregroundColor(.secondary)
                        } else if let errorMessage = postViewModel.errorMessage {
                            Text("Failed to load posts: \(errorMessage)")
                                .foregroundColor(.red)
                        } else if postViewModel.posts.isEmpty {
                            Text("No posts yet")
                                .foregroundColor(.secondary)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 10) {
                                    ForEach(postViewModel.posts) { post in
                                        PostRowView(post: post)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .onAppear {
                        postViewModel.loadUserPosts(userId: user.uid)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PostRowView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(post.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(post.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(post.description)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            if !post.description.isEmpty {
                Divider()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    var authViewModel = AuthenticationViewModel()
    ProfileView(authViewModel: authViewModel)
}

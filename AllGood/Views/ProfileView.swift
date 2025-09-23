//
//  ProfileView.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/13/25.
//

import SwiftUI

struct ProfileView: View {
    
    @Environment(\.colorTheme) var theme
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    @ObservedObject var postViewModel: PostViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                if let user = authViewModel.user {
                    // profile Header
                    HStack(spacing: 30) {
                        // profile picture placeholder
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.white)
                            )
                        
                        // username
                        Text("@\(user.username ?? "anonymous")")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .center) // center horizontally
                    .padding(.top, 100) // push down a little from the top
                    
                    // streak section
                    HStack(spacing: 40) {
                        // app Streak
                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(theme.tertiary)
                                Text("\(user.streakApp)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            Text("App Streak")
                                .foregroundColor(.white)
                                .font(.body)
                            Text("\(user.streakAppBest) best")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        
                        // good deed Streak
                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "heart")
                                    .foregroundColor(theme.primary)
                                Text("\(user.streakPost)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            Text("Good Deed Streak")
                                .foregroundColor(.white)
                                .font(.body)
                            Text("\(user.streakPostBest) best")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center) // center horizontally
                    
                    // scrollable posts section
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(postViewModel.userPosts) { post in
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .center, spacing: 16) {
                                        // circle with first letter
                                        Circle()
                                            .stroke(theme.quaternary, lineWidth: 3)
                                            .frame(width: 35, height: 35)
                                            .overlay(
                                                Text(post.userName.first.map { String($0).uppercased() } ?? "A")
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(theme.quaternary)
                                            )
                                        
                                        // date
                                        Text(post.timestamp, style: .date)
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                            
                                        Spacer()
                                    }
                                    
                                    // description
                                    Text(post.description)
                                        .font(.body)
                                        .foregroundColor(theme.secondary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(3)
                                }
                                .padding(.horizontal, 22)   // more breathing room inside
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(theme.tertiary, lineWidth: 3)
                                )
                                .frame(maxWidth: 325) // control tile width here
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 12)
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // expand to full screen
            .background(Color(theme.secondary)) // hex #1B282E
            .ignoresSafeArea() // cover behind nav bar
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let user = authViewModel.user {
                    postViewModel.loadUserPosts(userId: user.uid)
                }
            }
        }
        // attach this to the *content view* inside the tab
        .toolbarBackground(Color(theme.secondary), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    let mockAuthVM = MockAuthenticationViewModel()
    let mockPostVM = MockPostViewModel()
    
    ProfileView(postViewModel: mockPostVM)
        .environmentObject(mockAuthVM)
}

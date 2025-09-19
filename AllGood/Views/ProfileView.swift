//
//  ProfileView.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/13/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthenticationViewModel
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
                                    .foregroundColor(.blue)
                                Text("\(user.streakApp)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            Text("App Streak")
                                .foregroundColor(.white)
                                .font(.subheadline)
                            Text("\(user.streakAppBest) best")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        
                        // good deed Streak
                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "heart")
                                    .foregroundColor(.red)
                                Text("\(user.streakPost)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            Text("Good Deed Streak")
                                .foregroundColor(.white)
                                .font(.subheadline)
                            Text("\(user.streakPostBest) best")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center) // center horizontally
                    
                    // scrollable posts section
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(postViewModel.posts) { post in
                                HStack(alignment: .top, spacing: 30) {
                                    // circle with first letter
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 2)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text(post.userName.first.map { String($0).uppercased() } ?? "A")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        // date
                                        Text(post.timestamp, style: .date)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        
                                        // description
                                        Text(post.description)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue, lineWidth: 1)
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 12)
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // expand to full screen
            .background(Color(red: 0x1B/255, green: 0x28/255, blue: 0x2E/255)) // hex #1B282E
            .ignoresSafeArea() // cover behind nav bar
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let user = authViewModel.user {
                    postViewModel.loadUserPosts(userId: user.uid)
                }
            }
        }
    }
}

#Preview {
    let authViewModel = AuthenticationViewModel()
    let mockVM = MockPostViewModel()
    ProfileView(authViewModel: authViewModel, postViewModel: mockVM)
}

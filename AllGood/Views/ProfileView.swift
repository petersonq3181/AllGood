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
    
    @State private var showUserSetupPopup: Bool = false
    @State private var selectedIconNumber: Int = 0
    @State private var newUsername: String = ""
    private var isSetupUserFormValid: Bool {
        selectedIconNumber > 0 &&
        !newUsername.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    @State private var showUserUpdatePopup: Bool = false
    private var isUpdateUserFormValid: Bool {
        selectedIconNumber > 0
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                if let user = authViewModel.user {
 
                    if authViewModel.hasValidUsername {
                        if showUserUpdatePopup {
                            updateUserForm(user: user)
                        } else {
                            profileSection(user: user)
                            streakSection(user: user)
                            postSection(user: user)
                        }
                    } else {
                        if !showUserSetupPopup {
                            setupProfileSection(user: user)
                        } else {
                            userSetupForm(user: user)
                        }
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
                    Task {
                        await postViewModel.loadUserPosts(userId: user.uid)
                    }
                }
            }
            .toolbar {
//                 //Saved temporarily and commented -- helpful to Sign Out
//                 // for User - sign-up flow testing
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Sign Out") {
//                        authViewModel.signOut()
//                    }
//                    .foregroundColor(.white) // optional to match your theme
//                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showUserUpdatePopup = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.white) // keep theme color
                    }
                }
            }
        }
        // attach this to the *content view* inside the tab
        .toolbarBackground(Color(theme.secondary), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
    
    private func profileSection(user: User) -> some View {
        HStack(spacing: 30) {
            // profile picture placeholder
            Circle()
                .fill(Color.white)
                .frame(width: 80, height: 80)
                .overlay(
                    Image("CustomIcon\(user.avatarNumber)")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
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
    }
    
    private func setupProfileSection(user: User) -> some View {
        HStack(spacing: 30) {
            Button(action: { showUserSetupPopup = true }) {
                Image(systemName: "plus")
                    .font(.title)
                    .frame(width: 80, height: 80)
                    .foregroundColor(theme.secondary)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            
            Text("Setup Profile")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .center) // center horizontally
        .padding(.top, 100) // push down a little from the top
    }
    
    private func streakSection(user: User) -> some View {
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
    }
    
    private func postSection(user: User) -> some View {
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
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .frame(maxWidth: 325) // control tile width here
                    .padding(.horizontal)
                }
            }
            .padding(.top, 12)
        }
    }
    
    private func userSetupForm(user: User) -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showUserSetupPopup = false }
                    newUsername = ""
                }
            
            VStack(spacing: 20) {
                Text("Select Avatar")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // grid of avatars (FOW NOW JUST 2 rows x 3 cols)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
                    ForEach(1..<7) { index in
                        avatarCircle(index: index)
                    }
                }
                
                TextField("Username..", text: $newUsername)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .onChange(of: newUsername) { _, newValue in
                        if newValue.count > 15 {
                            newUsername = String(newValue.prefix(15))
                        }
                    }
                
                Text("Username will be permanent")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if (authViewModel.errorMessage != nil) {
                    Text("Your username contains inappropriate language.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button(action: {
                    Task {
                        await authViewModel.setupProfile(username: newUsername, avatarNumber: selectedIconNumber)
                    }
                }) {
                    Text("Setup")
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(isSetupUserFormValid ? theme.tertiary : Color.gray.opacity(0.5))
                        .cornerRadius(10)
                }
                .disabled(!isSetupUserFormValid)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
            .frame(width: 320)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
        }
    }
    
    private func updateUserForm(user: User) -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { showUserUpdatePopup = false } }
            
            VStack(spacing: 20) {
                Text("Select Avatar")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // grid of avatars (FOW NOW JUST 2 rows x 3 cols)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
                    ForEach(1..<7) { index in
                        avatarCircle(index: index)
                    }
                }
                
                Button(action: {
                    Task {
                        await authViewModel.updateAvatar(avatarNumber: selectedIconNumber)
                    }
                    
                    withAnimation {
                        showUserUpdatePopup = false
                    }
                }) {
                    Text("Update")
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(isUpdateUserFormValid ? theme.tertiary : Color.gray.opacity(0.5))
                        .cornerRadius(10)
                }
                .disabled(!isUpdateUserFormValid)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
            .frame(width: 320)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .onAppear {
                // pre-fill with user’s current avatar
                if selectedIconNumber == 0 {
                    selectedIconNumber = user.avatarNumber
                }
            }
        }
    }
    
    private func avatarCircle(index: Int) -> some View {
        Circle()
            .fill(Color.black)
            .frame(width: 80, height: 80)
            .overlay(
                Image("CustomIcon\(index)")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75, height: 75)
                    .foregroundColor(.white)
            )
            .overlay(
                Circle()
                    .stroke(selectedIconNumber == index ? theme.tertiary : Color.clear, lineWidth: 5)
            )
            .onTapGesture {
                selectedIconNumber = index
            }
    }
}

#Preview {
    let mockAuthVM = MockAuthenticationViewModel()
    let mockPostVM = MockPostViewModel()
    ProfileView(postViewModel: mockPostVM)
        .environmentObject(mockAuthVM as AuthenticationViewModel)
}

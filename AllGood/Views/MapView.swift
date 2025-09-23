//
//  MapView.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/13/25.
//

import SwiftUI
import MapKit
import FirebaseFirestore

struct MapView: View {
    
    @Environment(\.colorTheme) var theme
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    @ObservedObject var postViewModel: PostViewModel
    
    @StateObject private var locationManager = LocationManager()
    @State private var showLocationDeniedAlert = false
    
    @State private var showNewPostForm = false
    @State private var selectedType: PostType? = nil
    @State private var message: String = ""
    @State private var canPost: Bool? = nil
    var isFormValid: Bool {
        selectedType != nil &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    @State private var selectedPost: PostLocation? = nil

    @State private var bounds = MapCameraBounds(
        centerCoordinateBounds: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.7392, longitude: -104.9903),
            span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 360)
        ),
        minimumDistance: nil,
        maximumDistance: nil
    )
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(bounds: bounds) {
                ForEach(postViewModel.worldPosts, id: \.id) { post in
                    Annotation("", coordinate: post.coordinate) {
                        Button(action: { selectedPost = post }) {
                            Image(systemName: "heart.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(theme.primary)
                                .shadow(radius: 2)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .bottom)
            
            if postViewModel.worldPosts.isEmpty { postLoadingNote }
            
            if !showNewPostForm { floatingButtons }

            if showNewPostForm { newPostForm }
        }
        // attach this to the *content view* inside the tab
        .toolbarBackground(Color(theme.secondary), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        // fallback for location enabling
        .alert("Location Access Disabled", isPresented: $showLocationDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable location in Settings to attach your approximate location to posts.")
        }
        // tapped post bottom sheet
        .sheet(
            isPresented: Binding(
                get: { selectedPost != nil },
                set: { if !$0 { selectedPost = nil } }
            )
        ) {
            tappedPostSheet
        }
    }
    
    private var postLoadingNote: some View {
        HStack {
            Text("Loading posts..")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(8)
                .background(Color.white.opacity(0.7))
                .cornerRadius(8)
            Spacer()
        }
        .padding(.top, 25)
        .padding(.leading, 16)
        .transition(.opacity)
    }
    
    private var floatingButtons: some View {
        VStack(spacing: 12) {
            Button(action: { showNewPostForm = true }) {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            
            Button(action: { print("Filter tapped") }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
        }
        .padding(.top, 25)
        .padding(.trailing, 25)
    }
    
    private var newPostForm: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { showNewPostForm = false } }
            
            VStack(spacing: 16) {
                Text("New Post")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let canPost = canPost {
                    if canPost {
                        typeDropdown
                        messageField
                        postLocationNote
                        postButton
                    } else {
                        VStack {
                            Text("Daily Limit Reached")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text("You can only post once per day")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                } else {
                    ProgressView("Checking..")
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(theme.secondary)
            .cornerRadius(10)
            .shadow(radius: 8)
            .padding()
            .task {
                canPost = await postViewModel.userCanPost(userId: authViewModel.user?.uid ?? "")
            }
        }
    }
        
    private var typeDropdown: some View {
        Menu {
            ForEach(PostType.allCases, id: \.self) { type in
                Button(type.displayName) { selectedType = type }
            }
        } label: {
            HStack {
                Text(selectedType?.displayName ?? "Type")
                    .foregroundColor(selectedType == nil ? .gray : .black)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private var messageField: some View {
        ZStack(alignment: .topLeading) {
            if message.isEmpty {
                Text("Message..")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
            }
            TextEditor(text: $message)
                .padding(12)
                .opacity(message.isEmpty ? 0.01 : 1)
        }
        .frame(height: 100)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.gray, lineWidth: 1))
    }
        
    private var postLocationNote: some View {
        Text("Posts to general area, not exact address")
            .font(.footnote)
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
        
    private var postButton: some View {
        Button(action: handlePostButton) {
            Text("Post")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? theme.primary : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(25)
        }
        .padding(.top, 4)
        .frame(maxWidth: 160)
        .disabled(!isFormValid)
    }
        
    private func handlePostButton() {
        guard isFormValid else { return }
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAuthorization()
            // locationManager.requestSingleLocation()
            
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestSingleLocation { loc in
                guard let loc = loc else {
                    // fallback (show alert, etc.)
                    return
                }
                
                let randomizedLoc = locationManager.randomNearbyLocation(from: loc, maxMeters: 5000)

                let geo = GeoPoint(latitude: randomizedLoc.coordinate.latitude,
                                   longitude: randomizedLoc.coordinate.longitude)

                postViewModel.createPost(
                    userId: authViewModel.user?.uid ?? "",
                    userName: authViewModel.user?.username ?? "",
                    type: selectedType ?? PostType.donation,
                    location: geo,
                    description: message
                )

                withAnimation { showNewPostForm = false }
            }
            
        case .denied, .restricted, .none:
            showLocationDeniedAlert = true
        @unknown default:
            break
        }
    }
    
    private var tappedPostSheet: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Capsule()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
                Group {
                    if let post = selectedPost,
                       let details = postViewModel.selectedPostDetails,
                       details.id == post.id {
                        VStack(alignment: .leading, spacing: 16) {
                            // date
                            Text(details.timestamp.formatted(date: .long, time: .omitted))
                                .font(.subheadline)
                            // category
                            Text(details.type.displayName)
                                .font(.subheadline)
                                .foregroundColor(theme.quaternary)
                            // description
                            Text(details.description)
                                .font(.body)
                                .padding(.top, 8)
                            Spacer()
                            // footer: Post from @username
                            HStack(spacing: 6) {
                                Text("Post from")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text("@\(details.userName)")
                                    .font(.subheadline)
                                    .foregroundColor(theme.tertiary)
                            }
                            .padding(.bottom, 8)
                        }
                        .padding(.horizontal, 45)
                    } else if selectedPost != nil {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading post...")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 24)
                    } else {
                        EmptyView()
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom)
        }
        .onAppear {
            if let post = selectedPost { postViewModel.fetchPostById(post.id) }
        }
        .onDisappear { postViewModel.selectedPostDetails = nil }
        .presentationDetents([.fraction(0.66)])
    }
}

#Preview {
    let mockAuthVM = MockAuthenticationViewModel()
    let mockPostVM = MockPostViewModel()
    MapView(postViewModel: mockPostVM)
        .environmentObject(mockAuthVM)
}

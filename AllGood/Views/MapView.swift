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
    
    @State private var showFilterForm = false
    @State private var selectedDateFilter: PostDateFilter = .all
    @State private var selectedTypeFilter: PostTypeFilter = .all
    
    @State private var showNewPostForm = false
    @State private var selectedType: PostType? = nil
    @State private var message: String = ""
    @State private var canPost: Bool? = nil
    var isPostFormValid: Bool {
        selectedType != nil &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isUserSetup: Bool {
        authViewModel.hasValidUsername
    }
    
    @State private var selectedPost: Post? = nil

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
            
            if postViewModel.worldPosts.isEmpty { postLoadingNote }
            
            if !showNewPostForm && selectedPost == nil { floatingButtons }

            if showNewPostForm { newPostForm }
            if showFilterForm { filterForm }

            if selectedPost != nil { tappedPostPopup }
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
    
    private var tappedPostPopup: some View {
        ZStack {
            // dim background; tap outside to dismiss
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { selectedPost = nil }
            
            // card
            VStack(alignment: .leading, spacing: 16) {
                if let details = postViewModel.selectedPostDetails {
                    if let formatted = postViewModel.formattedLocation(for: details) {
                        Text(formatted)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                    
                    Text(details.timestamp.formatted(date: .long, time: .omitted))
                        .font(.body)
                        .foregroundColor(.black)

                    Text(details.type.displayName)
                        .font(.body)
                        .foregroundColor(theme.quaternary)

                    Text(details.description)
                        .font(.body)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .lineLimit(6)
                        .truncationMode(.tail)
                        .padding(.top, 12)

                    Spacer(minLength: 0)

                    HStack(spacing: 6) {
                        Text("Post from @\(details.userName)")
                            .font(.body)
                            .foregroundColor(.black)
                            .lineLimit(2)
                            .truncationMode(.tail)
                        
                        Spacer() // pushes the circle to the far right
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80) 
                            .overlay(
                                Image("CustomIcon\(details.avatarNumber ?? 1)")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 75, height: 75)
                                    .foregroundColor(.white)
                            )
                    }
                    .padding(.bottom, 4)
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading post...")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading) // force to left
            .padding(.horizontal, 25)
            .padding(.vertical, 30)
            .frame(maxWidth: 294, maxHeight: 432)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 8)
        }
        .onAppear {
            if let post = selectedPost {
                Task {
                    await postViewModel.fetchPostById(post.id ?? "")
                }
            }
        }
        .onDisappear {
            postViewModel.selectedPostDetails = nil
        }
    }

    private var floatingButtons: some View {
        VStack(spacing: 12) {
            if isUserSetup {
                Button(action: { showNewPostForm = true }) {
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                    
                        .shadow(radius: 5)
                }
            }
            
            Button(action: { showFilterForm = true }) {
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
                        if (postViewModel.errorMessage != nil) { postErrorNote }
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
        
    private var filterForm: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { showFilterForm = false } }
            
            VStack(spacing: 16) {
                Text("Filter Posts")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // date dropdown
                Menu {
                    ForEach(PostDateFilter.allCases, id: \.self) { filter in
                        Button(filter.displayName) {
                            selectedDateFilter = filter
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedDateFilter.displayName)
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
                
                // type dropdown
                Menu {
                    ForEach(PostTypeFilter.allCases, id: \.self) { type in
                        Button(type.displayName) { selectedTypeFilter = type }
                    }
                } label: {
                    HStack {
                        Text(selectedTypeFilter.displayName)
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    postViewModel.selectedDateFilter = selectedDateFilter
                    postViewModel.selectedTypeFilter = selectedTypeFilter
                    postViewModel.applyFilters()
                    withAnimation { showFilterForm = false }
                }) {
                    Text("Filter")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.tertiary)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                .padding(.top, 4)
                .frame(maxWidth: 160)
            }
            .padding(20)
            .background(theme.secondary)
            .cornerRadius(10)
            .shadow(radius: 8)
            .padding()
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
            TextEditor(text: $message)
                .padding(12)
                .background(Color.clear)
            
            if message.isEmpty {
                Text("Message..")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: 100)
        .background(Color(UIColor.systemBackground)) // adaptive background
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray, lineWidth: 1)
        )
    }
        
    private var postLocationNote: some View {
        Text("Posts to general area, not exact address")
            .font(.footnote)
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
    
    private var postErrorNote: some View {
        Text(postViewModel.errorMessage ?? "")
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
                .background(isPostFormValid ? theme.primary : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(25)
        }
        .padding(.top, 4)
        .frame(maxWidth: 160)
        .disabled(!isPostFormValid)
    }
        
    private func handlePostButton() {
        guard isPostFormValid else { return }
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAuthorization()
            
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestSingleLocation { loc in
                guard let loc = loc else {
                    return
                }
                
                let randomizedLoc = locationManager.randomNearbyLocation(from: loc, maxMeters: 5000)
                
                // reverse geocode the randomized location
                locationManager.reverseGeocode(randomizedLoc) { locationString in
                    let geo = GeoPoint(
                        latitude: randomizedLoc.coordinate.latitude,
                        longitude: randomizedLoc.coordinate.longitude
                    )
                    
                    Task {
                        let post = await postViewModel.createPost(
                            userId: authViewModel.user?.uid ?? "",
                            userName: authViewModel.user?.username ?? "",
                            avatarNumber: authViewModel.user?.avatarNumber ?? 1,
                            type: selectedType ?? PostType.donation,
                            location: geo,
                            locationString: locationString ?? "",
                            description: message
                        )
                        
                        if post != nil {
                            message = ""
                            selectedType = nil
                            withAnimation { showNewPostForm = false }
                        }
                    }
                }
            }
            
        case .denied, .restricted, .none:
            showLocationDeniedAlert = true
        @unknown default:
            break
        }
    }
}

#if DEBUG
#Preview {
    let mockAuthVM = MockAuthenticationViewModel()
    let mockPostVM = MockPostViewModel()
    MapView(postViewModel: mockPostVM)
        .environmentObject(mockAuthVM)
}
#endif

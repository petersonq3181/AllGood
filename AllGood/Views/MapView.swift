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
    
    @ObservedObject var authViewModel: AuthenticationViewModel
    @ObservedObject var postViewModel: PostViewModel
    
    @StateObject private var locationManager = LocationManager()
    @State private var showLocationDeniedAlert = false
    
    @State private var showNewPostForm = false
    @State private var selectedType: PostType? = nil
    @State private var message: String = ""
    var isFormValid: Bool {
        selectedType != nil &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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
            Map(bounds: bounds)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .bottom)
            
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
                
                typeDropdown
                messageField
                postLocationNote
                postButton
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
            if message.isEmpty {
                Text("Message...")
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

                let geo = GeoPoint(latitude: loc.coordinate.latitude,
                                   longitude: loc.coordinate.longitude)

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
}

#Preview {
    let mockAuthVM = MockAuthenticationViewModel()
    let mockPostVM = MockPostViewModel()
    MapView(authViewModel: mockAuthVM, postViewModel: mockPostVM)
}

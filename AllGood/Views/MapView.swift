//
//  MapView.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/13/25.
//

import SwiftUI
import MapKit

struct MapView: View {
    
    @Environment(\.colorTheme) var theme
    
    @StateObject private var locationManager = LocationManager()
    @State private var showLocationDeniedAlert = false
    
    @State private var showNewPostForm = false
    @State private var location: String = ""
    @State private var selectedType: PostType? = nil
    @State private var message: String = ""
    var isFormValid: Bool {
        selectedType != nil &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @State private var bounds = MapCameraBounds(
        centerCoordinateBounds: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.7392, longitude: -104.9903),
            span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
        ),
        minimumDistance: nil,
        maximumDistance: nil
    )
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(bounds: bounds)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .bottom)
            
            if !showNewPostForm {
                // floating buttons (overlay)
                VStack(spacing: 12) {
                    Button(action: {
                        print("Add tapped")
                        showNewPostForm = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    
                    Button(action: {
                        print("Filter tapped")
                    }) {
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
            
            // poppup new post form
            if showNewPostForm {
                ZStack {
                    // background tap catcher
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showNewPostForm = false
                            }
                        }
                    
                    VStack(spacing: 16) {
                        // title
                        Text("New Post")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // type dropdown
                        Menu {
                            ForEach(PostType.allCases, id: \.self) { type in
                                Button(type.displayName) {
                                    selectedType = type
                                }
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
                        
                        // message field (z-stack hack to get placeholder text)
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        
                        Text("Posts to general area, not exact address")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // post button
                        Button(action: {
                            guard isFormValid else { return }
                            
                            switch locationManager.authorizationStatus {
                            case .notDetermined:
                                // first time: ask
                                locationManager.requestAuthorization()
                                locationManager.requestSingleLocation()
                                
                            case .authorizedWhenInUse, .authorizedAlways:
                                // already granted: get location
                                locationManager.requestSingleLocation()
                                
                            case .denied, .restricted, .none:
                                // user denied: show alert
                                showLocationDeniedAlert = true
                            @unknown default:
                                break
                            }
                        }) {
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
                    .padding(20)
                    .background(theme.secondary)
                    .cornerRadius(10)
                    .shadow(radius: 8)
                    .padding()
                }
            }
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
        .onChange(of: locationManager.lastLocation) {
            // use locationManager.lastLocation directly
            guard showNewPostForm, let loc = locationManager.lastLocation else { return }
            location = "\(loc.coordinate.latitude), \(loc.coordinate.longitude)"
            withAnimation { showNewPostForm = false }
        }
    }
}

#Preview {
    MapView()
}

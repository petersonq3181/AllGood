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
    
    @State private var bounds = MapCameraBounds(
        centerCoordinateBounds: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.7392, longitude: -104.9903),
            span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40) 
        ),
        minimumDistance: nil,
        maximumDistance: nil
    )
    
    var body: some View {
        ZStack {
            Map(bounds: bounds)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .bottom)
        }
        // attach this to the *content view* inside the tab
        .toolbarBackground(Color(theme.secondary), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    MapView()
}

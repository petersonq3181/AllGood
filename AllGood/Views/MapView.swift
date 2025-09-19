//
//  MapView.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/13/25.
//

import SwiftUI
import MapKit

struct MapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    MapView()
}

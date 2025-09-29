//
//  PostPopup.swift
//  AllGood
//
//  Created by Quinn Peterson on 9/24/25.
//

import SwiftUI
import FirebaseFirestore

struct MockPostPopup: View {
    @Environment(\.colorTheme) var theme
    let details: Post
    
    let postViewModel: PostViewModel = PostViewModel(postManager: PostManager(db: FirestoreManager.db))

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let formatted = postViewModel.formattedLocation(for: details) {
                Text(formatted)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text(details.timestamp.formatted(date: .long, time: .omitted))
                .font(.body)

            Text(details.type.displayName)
                .font(.body)
                .foregroundColor(theme.quaternary)

            Text(details.description)
                .font(.body)
                .multilineTextAlignment(.leading)
                .lineLimit(6)
                .truncationMode(.tail)
                .padding(.top, 12)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Text("Post from @\(details.userName)")
                    .font(.body)
                    .foregroundColor(.primary)
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

        }
        .frame(maxWidth: .infinity, alignment: .leading) // force to left
        .padding(.horizontal, 25)
        .padding(.vertical, 30)
        .frame(maxWidth: 294, maxHeight: 432)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 8)
    }
}

#Preview {
    let mock = Post.mockPosts.first!
    MockPostPopup(details: mock)
}
